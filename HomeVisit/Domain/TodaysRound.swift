//  TodaysRound.swift
//  HomeVisit
//

import Foundation

struct TodaysRound {
    //PROPERTIES
    let outstandingVisits: [CareVisit]     // Still to visit, earliest first
    let closedVisits: [CareVisit]          // Completed or no access
    let outcomeOverdueVisitIDs: [UUID]     // Past their planned finish time with no outcome recorded
    let comingUpVisits: [CareVisit]        // Booked for the coming days, earliest first

    // The visit the nurse should drive to next
    var nextVisit: CareVisit? {
        outstandingVisits.first
    }

    var totalVisitCount: Int {
        outstandingVisits.count + closedVisits.count
    }

    //Visits done"
    var progressSummary: String {
        "\(closedVisits.count) of \(totalVisitCount) visits done"
    }

    //FUNCTION
    func isOutcomeOverdue(_ visit: CareVisit) -> Bool {
        outcomeOverdueVisitIDs.contains(visit.id)
    }
}
