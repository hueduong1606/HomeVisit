//  PlanTodaysRoundUseCase.swift
//  HomeVisit
//
//  Business operation: show the nurse who is still to be seen today, in time order,
//  and flag any visit whose outcome is overdue.

import Foundation

// MARK: - PlanTodaysRoundError
enum PlanTodaysRoundError: LocalizedError, Equatable {
    case roundUnavailable

    // What went wrong + what the nurse can do next
    var errorDescription: String? {
        switch self {
        case .roundUnavailable:
            return "Today's round couldn't be loaded. Close and reopen HomeVisit, or call your team leader for today's visit list."
        }
    }
}

// MARK: - PlanTodaysRoundUseCase
struct PlanTodaysRoundUseCase {

    //MARK: - PROPERTIES
    let repository: CaseloadRepository

    //MARK: - FUNCTION
    /// Business rules:
    /// 1. visits still to do are listed in time order – the order the nurse drives the round
    /// 2. a visit still not documented after its planned finish time is flagged "Outcome overdue"
    func execute(on day: Date = Date(), now: Date = Date()) throws(PlanTodaysRoundError) -> TodaysRound {
        let outstandingVisits: [CareVisit]
        let everyVisitToday: [CareVisit]
        do {
            outstandingVisits = try repository.fetchOutstandingVisits(scheduledOn: day)
            everyVisitToday = try repository.fetchVisits(scheduledOn: day)
        } catch {
            throw PlanTodaysRoundError.roundUnavailable
        }

        // Rule 1: time order
        let orderedVisits = outstandingVisits.sorted { $0.scheduledStart < $1.scheduledStart }

        // Rule 2: outcome overdue
        let outcomeOverdueVisitIDs = orderedVisits
            .filter { $0.isOutcomeOverdue(at: now) }
            .map { $0.id }

        return TodaysRound(
            outstandingVisits: orderedVisits,
            closedVisits: everyVisitToday.filter { $0.status.isClosed },
            outcomeOverdueVisitIDs: outcomeOverdueVisitIDs
        )
    }
}
