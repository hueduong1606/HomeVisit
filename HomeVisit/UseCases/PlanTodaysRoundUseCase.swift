//  PlanTodaysRoundUseCase.swift
//  HomeVisit
//

import Foundation

//  PlanTodaysRoundError

enum PlanTodaysRoundError: LocalizedError, Equatable {
    case roundUnavailable   // Today's visits could not be read from the device

    // What went wrong + what the nurse can do next
    var errorDescription: String? {
        switch self {
        case .roundUnavailable:
            return "Today's round couldn't be loaded. Close and reopen HomeVisit, or call your team leader for today's visit list."
        }
    }
}

//PlanTodaysRoundUseCase
struct PlanTodaysRoundUseCase {

    //PROPERTIES
    let repository: CaseloadRepository

    //FUNCTION
    func execute(on day: Date = Date(), now: Date = Date()) throws(PlanTodaysRoundError) -> TodaysRound {
        let calendar = Calendar.current
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: day))!
        let endOfPlanningWindow = calendar.date(byAdding: .day, value: ScheduleHomeVisitUseCase.planningWindowDays + 1, to: calendar.startOfDay(for: day))!

        let outstandingVisits: [CareVisit]
        let everyVisitToday: [CareVisit]
        let comingUpVisits: [CareVisit]
        do {
            outstandingVisits = try repository.fetchOutstandingVisits(scheduledOn: day)
            everyVisitToday = try repository.fetchVisits(scheduledOn: day)
            comingUpVisits = try repository.fetchOutstandingVisits(from: startOfNextDay, before: endOfPlanningWindow)
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
            outcomeOverdueVisitIDs: outcomeOverdueVisitIDs,
            comingUpVisits: comingUpVisits.sorted { $0.scheduledStart < $1.scheduledStart }
        )
    }
}
