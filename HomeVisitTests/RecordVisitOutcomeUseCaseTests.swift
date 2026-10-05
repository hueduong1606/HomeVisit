//  RecordVisitOutcomeUseCaseTests.swift
//  HomeVisitTests
//
//  Business rules for documenting a home visit.

import Testing
import Foundation
@testable import HomeVisit

@MainActor
struct RecordVisitOutcomeUseCaseTests {

    //MARK: - PROPERTIES
    let repository = MockCaseloadRepository()
    let roundSync = MockRoundSync()
    let nineAMVisit: CareVisit

    var recordVisitOutcome: RecordVisitOutcomeUseCase {
        RecordVisitOutcomeUseCase(repository: repository, roundSync: roundSync)
    }

    init() {
        nineAMVisit = CaseloadFixtures.visit(for: CaseloadFixtures.margaret, at: CaseloadFixtures.tuesday(hour: 9))
        repository.patients = [CaseloadFixtures.margaret]
        repository.visits = [nineAMVisit]
    }

    //MARK: - HAPPY PATHS

    @Test("Completing a visit with a clinical note closes it and moves the widget to the next patient")
    func completingVisitWithClinicalNote_closesVisit() throws {
        // --- WHEN ---
        let documentedVisit = try recordVisitOutcome.execute(
            visitID: nineAMVisit.id,
            outcome: .completed,
            clinicalNote: "  Dressing changed, wound edges healing. Review Friday.  ",
            now: CaseloadFixtures.tuesday(hour: 9, minute: 40)
        )

        // --- THEN ---
        #expect(documentedVisit.status == .completed)
        #expect(documentedVisit.outcomeNote == "Dressing changed, wound edges healing. Review Friday.", "Note is saved without stray spaces")
        #expect(documentedVisit.outcomeRecordedAt == CaseloadFixtures.tuesday(hour: 9, minute: 40))
        #expect(repository.visits.first?.status == .completed)
        #expect(roundSync.roundDidChangeCallCount == 1)
    }

    @Test("When the nurse cannot get in, the visit is recorded as No access")
    func noAccessVisit_isRecordedAsNoAccess() throws {
        let documentedVisit = try recordVisitOutcome.execute(
            visitID: nineAMVisit.id,
            outcome: .noAccess,
            clinicalNote: "No answer at door, phoned twice. Left card.",
            now: CaseloadFixtures.tuesday(hour: 9, minute: 10)
        )
        #expect(documentedVisit.status == .noAccess)
    }

    //MARK: - DOMAIN ERRORS

    @Test("A visit that is already documented cannot be overwritten")
    func recordingOutcomeTwice_isRejected() throws {
        // --- GIVEN --- the visit is already completed
        _ = try recordVisitOutcome.execute(
            visitID: nineAMVisit.id,
            outcome: .completed,
            clinicalNote: "Dressing changed, healing well.",
            now: CaseloadFixtures.tuesday(hour: 9, minute: 30)
        )

        // --- WHEN / THEN ---
        #expect(throws: RecordVisitOutcomeError.outcomeAlreadyRecorded(.completed)) {
            try recordVisitOutcome.execute(
                visitID: nineAMVisit.id,
                outcome: .noAccess,
                clinicalNote: "Trying to change the record.",
                now: CaseloadFixtures.tuesday(hour: 10)
            )
        }
    }

    @Test("A visit cannot be documented more than 30 minutes before it is due")
    func documentingBeforeArrivalWindow_isRejected() {
        #expect(throws: RecordVisitOutcomeError.visitHasNotStarted(startTime: nineAMVisit.scheduledStart)) {
            try recordVisitOutcome.execute(
                visitID: nineAMVisit.id,
                outcome: .completed,
                clinicalNote: "Dressing changed, healing well.",
                now: CaseloadFixtures.tuesday(hour: 8, minute: 29)
            )
        }
    }

    @Test("A visit removed from the round can no longer be documented")
    func documentingCancelledVisit_isRejected() {
        #expect(throws: RecordVisitOutcomeError.visitNoLongerOnRound) {
            try recordVisitOutcome.execute(
                visitID: UUID(),
                outcome: .completed,
                clinicalNote: "Dressing changed, healing well.",
                now: CaseloadFixtures.tuesday(hour: 9)
            )
        }
    }

    //MARK: - BOUNDARY CONDITIONS

    @Test("Notes shorter than 10 characters (after trimming spaces) are rejected", arguments: ["Done", "  Seen ok  ", "         "])
    func shortClinicalNote_isRejected(note: String) {
        #expect(throws: RecordVisitOutcomeError.clinicalNoteTooShort(minimumCharacters: 10)) {
            try recordVisitOutcome.execute(
                visitID: nineAMVisit.id,
                outcome: .completed,
                clinicalNote: note,
                now: CaseloadFixtures.tuesday(hour: 9, minute: 30)
            )
        }
        #expect(roundSync.roundDidChangeCallCount == 0, "Nothing changes when a rule fails")
    }

    @Test("A note of exactly 10 characters is accepted")
    func clinicalNoteOfExactlyMinimumLength_isAccepted() throws {
        let documentedVisit = try recordVisitOutcome.execute(
            visitID: nineAMVisit.id,
            outcome: .completed,
            clinicalNote: "Dressed ok", // 10 characters
            now: CaseloadFixtures.tuesday(hour: 9, minute: 30)
        )
        #expect(documentedVisit.status == .completed)
    }

    @Test("Documenting exactly 30 minutes early (nurse arrived early) is accepted")
    func documentingExactlyThirtyMinutesEarly_isAccepted() throws {
        let documentedVisit = try recordVisitOutcome.execute(
            visitID: nineAMVisit.id,
            outcome: .completed,
            clinicalNote: "Arrived early, dressing changed.",
            now: CaseloadFixtures.tuesday(hour: 8, minute: 30)
        )
        #expect(documentedVisit.status == .completed)
    }
}
