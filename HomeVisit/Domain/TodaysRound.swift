//  TodaysRound.swift
//  HomeVisit
//
//  The nurse's plan for one working day: who is still to be seen, who has been seen,
//  and which visits are running late.

import Foundation

struct TodaysRound {
    //MARK: - PROPERTIES
    let outstandingVisits: [CareVisit]     // Still to visit, earliest first
    let closedVisits: [CareVisit]          // Completed or no access
    let runningLateVisitIDs: [UUID]        // Outstanding visits past the lateness threshold

    //MARK: - COMPUTED PROPERTIES
    // The visit the nurse should drive to next
    var nextVisit: CareVisit? {
        outstandingVisits.first
    }

    var totalVisitCount: Int {
        outstandingVisits.count + closedVisits.count
    }

    // e.g. "3 of 7 visits done"
    var progressSummary: String {
        "\(closedVisits.count) of \(totalVisitCount) visits done"
    }

    //MARK: - FUNCTION
    func isRunningLate(_ visit: CareVisit) -> Bool {
        runningLateVisitIDs.contains(visit.id)
    }
}
