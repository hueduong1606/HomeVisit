//  PlanTodaysRoundUseCaseTests.swift
//  HomeVisitTests
//
//  Business rules for building the nurse's round for the day.

import Testing
import Foundation
@testable import HomeVisit

@MainActor
struct PlanTodaysRoundUseCaseTests {

    //MARK: - PROPERTIES
    let repository = MockCaseloadRepository()

    var planTodaysRound: PlanTodaysRoundUseCase {
        PlanTodaysRoundUseCase(repository: repository)
    }

    //MARK: - TESTS

    @Test("Outstanding visits are listed in driving order and documented visits are counted as closed")
    func roundListsOutstandingVisitsInTimeOrder() throws {
        // --- GIVEN --- visits added out of order, one already completed
        let elevenAM = CaseloadFixtures.visit(for: CaseloadFixtures.arthur, at: CaseloadFixtures.tuesday(hour: 11))
        let nineAM = CaseloadFixtures.visit(for: CaseloadFixtures.margaret, at: CaseloadFixtures.tuesday(hour: 9))
        let eightAMDone = CaseloadFixtures.visit(for: CaseloadFixtures.margaret, at: CaseloadFixtures.tuesday(hour: 8), status: .completed)
        repository.visits = [elevenAM, nineAM, eightAMDone]

        // --- WHEN ---
        let round = try planTodaysRound.execute(on: CaseloadFixtures.startOfShift, now: CaseloadFixtures.tuesday(hour: 8, minute: 50))

        // --- THEN ---
        #expect(round.outstandingVisits.map { $0.id } == [nineAM.id, elevenAM.id])
        #expect(round.nextVisit?.patientName == "Margaret Thompson")
        #expect(round.closedVisits.count == 1)
        #expect(round.progressSummary == "1 of 3 visits closed")
    }

    @Test("Visits on other days are not part of today's round")
    func visitsOnOtherDays_areNotOnTodaysRound() throws {
        let tomorrow = CaseloadFixtures.tuesday(hour: 9).addingTimeInterval(24 * 60 * 60)
        repository.visits = [CaseloadFixtures.visit(for: CaseloadFixtures.arthur, at: tomorrow)]

        let round = try planTodaysRound.execute(on: CaseloadFixtures.startOfShift, now: CaseloadFixtures.startOfShift)

        #expect(round.totalVisitCount == 0)
        #expect(round.nextVisit == nil)
    }

    @Test("A visit is running late only once MORE than 15 minutes have passed since its start")
    func runningLateThreshold_isFifteenMinutes() throws {
        let nineAM = CaseloadFixtures.visit(for: CaseloadFixtures.margaret, at: CaseloadFixtures.tuesday(hour: 9))
        repository.visits = [nineAM]

        let atFifteenMinutes = try planTodaysRound.execute(on: CaseloadFixtures.startOfShift, now: CaseloadFixtures.tuesday(hour: 9, minute: 15))
        let atSixteenMinutes = try planTodaysRound.execute(on: CaseloadFixtures.startOfShift, now: CaseloadFixtures.tuesday(hour: 9, minute: 16))

        #expect(!atFifteenMinutes.isRunningLate(nineAM), "Exactly 15 minutes is still on time")
        #expect(atSixteenMinutes.isRunningLate(nineAM))
    }

    @Test("If the round cannot be loaded the nurse is told what to do next")
    func unavailableRound_explainsNextStep() {
        repository.shouldFailStorage = true

        #expect(throws: PlanTodaysRoundError.roundUnavailable) {
            try planTodaysRound.execute(on: CaseloadFixtures.startOfShift, now: CaseloadFixtures.startOfShift)
        }
        #expect(PlanTodaysRoundError.roundUnavailable.recoverySuggestion?.isEmpty == false)
    }
}
