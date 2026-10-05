//  ScheduleHomeVisitUseCaseTests.swift
//  HomeVisitTests
//
//  Business rules for adding a visit to the nurse's round.

import Testing
import Foundation
@testable import HomeVisit

@MainActor
struct ScheduleHomeVisitUseCaseTests {

    //MARK: - PROPERTIES
    // A fresh mock for every test – no setUp() needed
    let repository = MockCaseloadRepository()
    let roundSync = MockRoundSync()

    var scheduleHomeVisit: ScheduleHomeVisitUseCase {
        ScheduleHomeVisitUseCase(repository: repository, roundSync: roundSync)
    }

    init() {
        repository.patients = [CaseloadFixtures.margaret, CaseloadFixtures.arthur]
    }

    //MARK: - HAPPY PATH

    @Test("Booking a visit for a patient on the caseload adds it to the round and refreshes the widget")
    func bookingVisitForPatientOnCaseload_addsVisitToRound() throws {
        // --- GIVEN ---
        let tenAM = CaseloadFixtures.tuesday(hour: 10)

        // --- WHEN ---
        let visit = try scheduleHomeVisit.execute(
            patientID: CaseloadFixtures.margaret.id,
            careType: .woundCare,
            scheduledStart: tenAM,
            durationMinutes: 45,
            now: CaseloadFixtures.startOfShift
        )

        // --- THEN ---
        #expect(repository.visits.contains(visit), "The visit should be saved to the round")
        #expect(visit.patientName == "Margaret Thompson")
        #expect(visit.homeAddress == CaseloadFixtures.margaret.homeAddress)
        #expect(visit.clinicalAlert == "Dog on premises – call ahead", "The safety alert must travel with the visit")
        #expect(visit.status == .scheduled)
        #expect(roundSync.roundDidChangeCallCount == 1, "The Lock Screen widget must be refreshed")
    }

    //MARK: - DOMAIN ERRORS

    @Test("A visit cannot be booked for a time that has already passed")
    func bookingVisitEarlierToday_isRejectedAsInThePast() {
        #expect(throws: ScheduleHomeVisitError.visitTimeInThePast) {
            try scheduleHomeVisit.execute(
                patientID: CaseloadFixtures.margaret.id,
                careType: .woundCare,
                scheduledStart: CaseloadFixtures.tuesday(hour: 7),
                durationMinutes: 45,
                now: CaseloadFixtures.startOfShift
            )
        }
        #expect(repository.savedVisits.isEmpty)
        #expect(roundSync.roundDidChangeCallCount == 0)
    }

    @Test("A visit that overlaps another visit is rejected and names the clashing patient")
    func visitOverlappingAnotherVisit_isRejected() {
        // --- GIVEN --- Arthur is booked 10:00–10:45
        let tenAM = CaseloadFixtures.tuesday(hour: 10)
        repository.visits = [CaseloadFixtures.visit(for: CaseloadFixtures.arthur, at: tenAM)]

        // --- WHEN / THEN --- Margaret at 10:30 clashes
        #expect(throws: ScheduleHomeVisitError.clashesWithVisit(patientName: "Arthur Nguyen", startTime: tenAM)) {
            try scheduleHomeVisit.execute(
                patientID: CaseloadFixtures.margaret.id,
                careType: .woundCare,
                scheduledStart: CaseloadFixtures.tuesday(hour: 10, minute: 30),
                durationMinutes: 30,
                now: CaseloadFixtures.startOfShift
            )
        }
    }

    @Test("A patient who has been discharged cannot be booked")
    func bookingDischargedPatient_isRejected() {
        #expect(throws: ScheduleHomeVisitError.patientNotOnCaseload) {
            try scheduleHomeVisit.execute(
                patientID: UUID(),
                careType: .medicationReview,
                scheduledStart: CaseloadFixtures.tuesday(hour: 11),
                durationMinutes: 30,
                now: CaseloadFixtures.startOfShift
            )
        }
    }

    @Test("When the iPhone's storage fails the nurse is told nothing was changed")
    func storageFailure_isReportedInNurseLanguage() {
        repository.shouldFailStorage = true

        #expect(throws: ScheduleHomeVisitError.roundCouldNotBeSaved) {
            try scheduleHomeVisit.execute(
                patientID: CaseloadFixtures.margaret.id,
                careType: .woundCare,
                scheduledStart: CaseloadFixtures.tuesday(hour: 10),
                durationMinutes: 45,
                now: CaseloadFixtures.startOfShift
            )
        }
        let message = NurseFacingMessage.from(ScheduleHomeVisitError.roundCouldNotBeSaved)
        #expect(message.contains("Nothing was changed"))
        #expect(!message.contains("Core Data"), "Technical terms must never reach the nurse")
    }

    //MARK: - BOUNDARY CONDITIONS

    @Test("Durations just outside the safe 15–180 minute range are rejected", arguments: [14, 181])
    func visitDurationOutsideSafeRange_isRejected(minutes: Int) {
        #expect(throws: ScheduleHomeVisitError.durationOutsideSafeRange(minutes: minutes)) {
            try scheduleHomeVisit.execute(
                patientID: CaseloadFixtures.margaret.id,
                careType: .woundCare,
                scheduledStart: CaseloadFixtures.tuesday(hour: 10),
                durationMinutes: minutes,
                now: CaseloadFixtures.startOfShift
            )
        }
    }

    @Test("Durations exactly on the safe range limits are accepted", arguments: [15, 180])
    func visitDurationOnSafeRangeLimit_isAccepted(minutes: Int) throws {
        let visit = try scheduleHomeVisit.execute(
            patientID: CaseloadFixtures.margaret.id,
            careType: .woundCare,
            scheduledStart: CaseloadFixtures.tuesday(hour: 10),
            durationMinutes: minutes,
            now: CaseloadFixtures.startOfShift
        )
        #expect(visit.durationMinutes == minutes)
    }

    @Test("A visit starting exactly when the previous one ends does not clash")
    func backToBackVisits_doNotClash() throws {
        // --- GIVEN --- Arthur 10:00–10:45
        repository.visits = [CaseloadFixtures.visit(for: CaseloadFixtures.arthur, at: CaseloadFixtures.tuesday(hour: 10), durationMinutes: 45)]

        // --- WHEN --- Margaret at 10:45
        let visit = try scheduleHomeVisit.execute(
            patientID: CaseloadFixtures.margaret.id,
            careType: .woundCare,
            scheduledStart: CaseloadFixtures.tuesday(hour: 10, minute: 45),
            durationMinutes: 30,
            now: CaseloadFixtures.startOfShift
        )

        // --- THEN ---
        #expect(repository.visits.count == 2)
        #expect(visit.scheduledStart == CaseloadFixtures.tuesday(hour: 10, minute: 45))
    }

    @Test("Booking the visit you are about to start, up to 5 minutes late, is allowed")
    func bookingWithinFiveMinuteGrace_isAccepted() throws {
        let now = CaseloadFixtures.tuesday(hour: 9, minute: 5)

        let visit = try scheduleHomeVisit.execute(
            patientID: CaseloadFixtures.margaret.id,
            careType: .woundCare,
            scheduledStart: CaseloadFixtures.tuesday(hour: 9),
            durationMinutes: 45,
            now: now
        )
        #expect(visit.status == .scheduled)
    }

    @Test("The 11th visit on one day is rejected because 10 is the safe daily limit")
    func eleventhVisitOfTheDay_isRejected() {
        // --- GIVEN --- ten short visits between 9:00 and 13:30
        repository.visits = (0..<ScheduleHomeVisitUseCase.maximumVisitsPerDay).map { index in
            CaseloadFixtures.visit(
                for: CaseloadFixtures.arthur,
                at: CaseloadFixtures.tuesday(hour: 9).addingTimeInterval(TimeInterval(index * 30 * 60)),
                durationMinutes: 15
            )
        }

        // --- WHEN / THEN ---
        #expect(throws: ScheduleHomeVisitError.dailyVisitLimitReached(limit: 10)) {
            try scheduleHomeVisit.execute(
                patientID: CaseloadFixtures.margaret.id,
                careType: .woundCare,
                scheduledStart: CaseloadFixtures.tuesday(hour: 16),
                durationMinutes: 30,
                now: CaseloadFixtures.startOfShift
            )
        }
    }
}
