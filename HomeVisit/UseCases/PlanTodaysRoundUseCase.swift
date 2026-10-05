//  PlanTodaysRoundUseCase.swift
//  HomeVisit
//
//  Business operation: show the nurse who is still to be seen today, in time order,
//  and flag any visit that is running late.

import Foundation

// MARK: - PlanTodaysRoundError
enum PlanTodaysRoundError: LocalizedError, Equatable {
    case roundUnavailable

    // What went wrong – in the nurse's words
    var errorDescription: String? {
        switch self {
        case .roundUnavailable:
            return "Today's round couldn't be loaded from this iPhone."
        }
    }

    // What the nurse can do next
    var recoverySuggestion: String? {
        switch self {
        case .roundUnavailable:
            return "Close and reopen HomeVisit. If it keeps happening, check the iPhone has free storage and call your team leader for today's list."
        }
    }
}

// MARK: - PlanTodaysRoundUseCase
struct PlanTodaysRoundUseCase {

    //MARK: - PROPERTIES
    let repository: CaseloadRepository

    //MARK: - FUNCTION
    /// Business rules:
    /// - outstanding visits are ordered by start time (the order the nurse drives the round)
    /// - a visit still not documented 15+ minutes after its start is flagged as running late
    func execute(on day: Date = Date(), now: Date = Date()) throws(PlanTodaysRoundError) -> TodaysRound {
        let outstandingVisits: [CareVisit]
        let everyVisitToday: [CareVisit]
        do {
            outstandingVisits = try repository.fetchOutstandingVisits(scheduledOn: day)
            everyVisitToday = try repository.fetchVisits(scheduledOn: day)
        } catch {
            throw PlanTodaysRoundError.roundUnavailable
        }

        // Rule 1: drive the round in time order
        let orderedOutstandingVisits = outstandingVisits.sorted { $0.scheduledStart < $1.scheduledStart }

        // Closed visits (completed or no access), most recently documented first
        let closedVisits = everyVisitToday
            .filter { $0.status.isClosed }
            .sorted { ($0.outcomeRecordedAt ?? $0.scheduledStart) > ($1.outcomeRecordedAt ?? $1.scheduledStart) }

        // Rule 2: flag visits running late so the nurse can call ahead
        let runningLateVisitIDs = Set(
            orderedOutstandingVisits
                .filter { $0.isRunningLate(at: now) }
                .map { $0.id }
        )

        return TodaysRound(
            day: Calendar.current.startOfDay(for: day),
            outstandingVisits: orderedOutstandingVisits,
            closedVisits: closedVisits,
            runningLateVisitIDs: runningLateVisitIDs
        )
    }
}
