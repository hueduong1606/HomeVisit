//  CaseloadManagementUseCaseTests.swift
//  HomeVisitTests
//
//  Business rules for reviewing the caseload, discharging patients
//  and cancelling booked visits.

import Testing
import Foundation
@testable import HomeVisit

@MainActor
struct CaseloadManagementUseCaseTests {

    //MARK: - PROPERTIES
    let repository = MockCaseloadRepository()
    let roundSync = MockRoundSync()

    init() {
        repository.patients = [CaseloadFixtures.margaret, CaseloadFixtures.arthur]
    }

    //MARK: - REVIEW CASELOAD

    @Test("A patient with no visit booked in the next 7 days is flagged and listed first")
    func patientWithoutVisitThisWeek_isFlaggedFirst() throws {
        // --- GIVEN --- only Margaret has a visit this week
        repository.visits = [CaseloadFixtures.visit(for: CaseloadFixtures.margaret, at: CaseloadFixtures.tuesday(hour: 10))]

        // --- WHEN ---
        let caseload = try ReviewCaseloadUseCase(repository: repository).execute(now: CaseloadFixtures.startOfShift)

        // --- THEN ---
        #expect(caseload.first?.patient.fullName == "Arthur Nguyen", "Patients needing a visit come first")
        #expect(caseload.first?.needsVisitBooked == true)
        #expect(caseload.last?.needsVisitBooked == false)
    }

    @Test("A visit booked 8 days ahead is outside the continuity-of-care window")
    func visitEightDaysAhead_stillNeedsVisitBooked() throws {
        let eightDaysAhead = CaseloadFixtures.tuesday(hour: 10).addingTimeInterval(8 * 24 * 60 * 60)
        repository.visits = [CaseloadFixtures.visit(for: CaseloadFixtures.margaret, at: eightDaysAhead)]

        let caseload = try ReviewCaseloadUseCase(repository: repository).execute(now: CaseloadFixtures.startOfShift)
        let margaretsEntry = caseload.first { $0.patient.id == CaseloadFixtures.margaret.id }

        #expect(margaretsEntry?.needsVisitBooked == true)
    }

    //MARK: - DISCHARGE PATIENT

    @Test("A patient with an undocumented visit cannot be discharged")
    func dischargingPatientWithOutstandingVisit_isRejected() {
        repository.visits = [CaseloadFixtures.visit(for: CaseloadFixtures.margaret, at: CaseloadFixtures.tuesday(hour: 10))]

        #expect(throws: DischargePatientError.visitsStillOutstanding(count: 1)) {
            try DischargePatientUseCase(repository: repository, roundSync: roundSync)
                .execute(patientID: CaseloadFixtures.margaret.id)
        }
        #expect(repository.patients.count == 2, "Nobody is discharged when the rule fails")
    }

    @Test("A patient whose visits are all documented is discharged with their visit history")
    func dischargingPatientWithOnlyDocumentedVisits_removesFromCaseload() throws {
        repository.visits = [CaseloadFixtures.visit(for: CaseloadFixtures.margaret, at: CaseloadFixtures.tuesday(hour: 8), status: .completed)]

        try DischargePatientUseCase(repository: repository, roundSync: roundSync)
            .execute(patientID: CaseloadFixtures.margaret.id)

        #expect(repository.dischargedPatientIDs == [CaseloadFixtures.margaret.id])
        #expect(!repository.patients.contains(CaseloadFixtures.margaret))
        #expect(roundSync.roundDidChangeCallCount == 1)
    }

    //MARK: - CANCEL HOME VISIT

    @Test("A completed visit cannot be cancelled because it is part of the clinical record")
    func cancellingCompletedVisit_isRejected() {
        let completedVisit = CaseloadFixtures.visit(for: CaseloadFixtures.margaret, at: CaseloadFixtures.tuesday(hour: 8), status: .completed)
        repository.visits = [completedVisit]

        #expect(throws: CancelHomeVisitError.visitAlreadyDocumented) {
            try CancelHomeVisitUseCase(repository: repository, roundSync: roundSync)
                .execute(visitID: completedVisit.id)
        }
        #expect(repository.deletedVisitIDs.isEmpty)
    }

    @Test("Cancelling a booked visit removes it from the round and refreshes the widget")
    func cancellingScheduledVisit_removesFromRound() throws {
        let bookedVisit = CaseloadFixtures.visit(for: CaseloadFixtures.arthur, at: CaseloadFixtures.tuesday(hour: 14))
        repository.visits = [bookedVisit]

        try CancelHomeVisitUseCase(repository: repository, roundSync: roundSync)
            .execute(visitID: bookedVisit.id)

        #expect(repository.visits.isEmpty)
        #expect(roundSync.roundDidChangeCallCount == 1)
    }
}
