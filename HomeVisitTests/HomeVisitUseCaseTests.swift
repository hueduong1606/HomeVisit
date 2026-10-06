//  HomeVisitUseCaseTests.swift
//  HomeVisitTests
//
//  Six tests across the four Use Cases, using the mock repository only.
//  Happy paths, boundary conditions and domain error cases.

import Testing
import Foundation
@testable import HomeVisit

@MainActor
struct HomeVisitUseCaseTests {

    //MARK: - PROPERTIES
    // A fresh mock for every test – no setUp() needed
    let repository = MockCaseloadRepository()
    let roundSync = MockRoundSync()
    let referralInbox = MockReferralInbox()

    //MARK: - SCHEDULE HOME VISIT

    // 1. Happy path
    @Test func scheduleHomeVisit_addsVisitToTomorrowsRound_whenPlannedTheDayBefore() throws {
        // --- GIVEN --- Margaret is on the caseload, it is Tuesday 4:00 PM
        repository.patients = [TestData.margaret]
        let scheduleHomeVisit = ScheduleHomeVisitUseCase(repository: repository, roundSync: roundSync)
        let wednesdayTenAM = Calendar.current.date(byAdding: .day, value: 1, to: TestData.tuesday(hour: 10))!

        // --- WHEN --- the nurse plans tomorrow's round: Margaret on Wednesday at 10:00 AM
        let visit = try scheduleHomeVisit.execute(
            patientID: TestData.margaret.id,
            careType: .woundCare,
            scheduledStart: wednesdayTenAM,
            durationMinutes: 45,
            now: TestData.tuesday(hour: 16)
        )

        // --- THEN ---
        #expect(repository.visits.count == 1, "The visit should be on the round")
        #expect(visit.clinicalAlert == "Dog on premises – call ahead", "The safety alert must travel with the visit")
        #expect(roundSync.roundDidChangeCallCount == 1, "The widget must be refreshed")
    }

    // 2. Domain error
    @Test func scheduleHomeVisit_fails_whenVisitOverlapsAnotherPatientsVisit() {
        // --- GIVEN --- Arthur is booked 10:00–10:45
        repository.patients = [TestData.margaret, TestData.arthur]
        repository.visits = [TestData.visit(for: TestData.arthur, at: TestData.tuesday(hour: 10))]
        let scheduleHomeVisit = ScheduleHomeVisitUseCase(repository: repository, roundSync: roundSync)

        // --- WHEN / THEN --- Margaret at 10:30 clashes with Arthur
        #expect(throws: ScheduleHomeVisitError.clashesWithVisit(patientName: "Arthur Nguyen")) {
            try scheduleHomeVisit.execute(
                patientID: TestData.margaret.id,
                careType: .woundCare,
                scheduledStart: TestData.tuesday(hour: 10, minute: 30),
                durationMinutes: 30,
                now: TestData.tuesday(hour: 8)
            )
        }
        #expect(repository.visits.count == 1, "The clashing visit must not be saved")
    }

    //MARK: - RECORD VISIT OUTCOME

    // 3. Boundary condition
    @Test func recordVisitOutcome_fails_whenClinicalNoteIsNineCharacters_andSucceedsAtTen() throws {
        // --- GIVEN --- a visit still to be documented
        let visit = TestData.visit(for: TestData.margaret, at: TestData.tuesday(hour: 9))
        repository.patients = [TestData.margaret]
        repository.visits = [visit]
        let recordVisitOutcome = RecordVisitOutcomeUseCase(repository: repository, roundSync: roundSync)

        // --- WHEN / THEN --- 9 characters is one short of the minimum
        #expect(throws: RecordVisitOutcomeError.clinicalNoteTooShort(minimumCharacters: 10)) {
            try recordVisitOutcome.execute(visitID: visit.id, outcome: .completed, clinicalNote: "Dressed o")
        }

        // --- WHEN / THEN --- exactly 10 characters is accepted
        let documentedVisit = try recordVisitOutcome.execute(visitID: visit.id, outcome: .completed, clinicalNote: "Dressed ok")
        #expect(documentedVisit.status == .completed)
    }

    // 4. Domain error
    @Test func recordVisitOutcome_fails_whenOutcomeIsAlreadyRecorded() throws {
        // --- GIVEN --- the nurse could not get in and recorded "No access"
        let visit = TestData.visit(for: TestData.margaret, at: TestData.tuesday(hour: 9))
        repository.patients = [TestData.margaret]
        repository.visits = [visit]
        let recordVisitOutcome = RecordVisitOutcomeUseCase(repository: repository, roundSync: roundSync)
        _ = try recordVisitOutcome.execute(visitID: visit.id, outcome: .noAccess, clinicalNote: "No answer at the door, phoned twice.")

        // --- WHEN / THEN --- the clinical record cannot be overwritten
        #expect(throws: RecordVisitOutcomeError.outcomeAlreadyRecorded) {
            try recordVisitOutcome.execute(visitID: visit.id, outcome: .completed, clinicalNote: "Trying to change the record.")
        }
        #expect(repository.visits.first?.status == .noAccess)
    }

    //MARK: - ADMIT PATIENT TO CASELOAD

    // 5. Happy path (referral from the Share Extension)
    @Test func admitPatientToCaseload_clearsReferral_whenAdmittedFromSharedReferral() throws {
        // --- GIVEN --- a referral waiting in the inbox
        let referral = PatientReferral(patientName: "Beatrice Collins", referralText: "Post hip replacement – wound review within 48 hours.")
        referralInbox.referrals = [referral]
        let admitPatientToCaseload = AdmitPatientToCaseloadUseCase(repository: repository, referralInbox: referralInbox)

        // --- WHEN ---
        let patient = try admitPatientToCaseload.execute(
            fullName: referral.patientName,
            homeAddress: "5 Marsden Street, Parramatta NSW 2150",
            referralNote: referral.referralText,
            fromReferral: referral.id
        )

        // --- THEN ---
        #expect(repository.patients.contains(patient))
        #expect(referralInbox.referrals.isEmpty, "The referral leaves the inbox once the patient is admitted")
    }

    //MARK: - PLAN TODAY'S ROUND

    // 6. Boundary condition
    @Test func planTodaysRound_flagsOutcomeOverdue_onlyAfterPlannedFinishTime() throws {
        // --- GIVEN --- an 11:00 visit added before a 9:00 visit (9:00 + 45 min = planned finish 9:45)
        let elevenAM = TestData.visit(for: TestData.arthur, at: TestData.tuesday(hour: 11))
        let nineAM = TestData.visit(for: TestData.margaret, at: TestData.tuesday(hour: 9))
        repository.visits = [elevenAM, nineAM]
        let planTodaysRound = PlanTodaysRoundUseCase(repository: repository)

        // --- WHEN --- the round is checked exactly at the planned finish, and one minute later
        let roundAtPlannedFinish = try planTodaysRound.execute(on: TestData.tuesday(hour: 8), now: TestData.tuesday(hour: 9, minute: 45))
        let roundOneMinuteLater = try planTodaysRound.execute(on: TestData.tuesday(hour: 8), now: TestData.tuesday(hour: 9, minute: 46))

        // --- THEN ---
        #expect(roundAtPlannedFinish.nextVisit?.patientName == "Margaret Thompson", "9:00 comes before 11:00")
        #expect(!roundAtPlannedFinish.isOutcomeOverdue(nineAM), "At the planned finish time the outcome is not overdue yet")
        #expect(roundOneMinuteLater.isOutcomeOverdue(nineAM), "One minute after the planned finish the outcome is overdue")
    }
}
