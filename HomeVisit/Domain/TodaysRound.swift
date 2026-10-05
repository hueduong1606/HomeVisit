//  TodaysRound.swift
//  HomeVisit
//
//  The nurse's plan for one working day: who is still to be seen, who has been seen,
//  and which visits are running late.

import Foundation

struct TodaysRound: Equatable {
    //MARK: - PROPERTIES
    let day: Date
    let outstandingVisits: [CareVisit]     // Still to visit, earliest first
    let closedVisits: [CareVisit]          // Completed or no access, latest first
    let runningLateVisitIDs: Set<UUID>     // Outstanding visits past the lateness threshold

    //MARK: - COMPUTED PROPERTIES
    // The visit the nurse should drive to next
    var nextVisit: CareVisit? {
        outstandingVisits.first
    }

    var totalVisitCount: Int {
        outstandingVisits.count + closedVisits.count
    }

    var completedVisitCount: Int {
        closedVisits.filter { $0.status == .completed }.count
    }

    var noAccessVisitCount: Int {
        closedVisits.filter { $0.status == .noAccess }.count
    }

    var isRoundComplete: Bool {
        totalVisitCount > 0 && outstandingVisits.isEmpty
    }

    // e.g. "3 of 7 visits closed"
    var progressSummary: String {
        "\(closedVisits.count) of \(totalVisitCount) visits closed"
    }

    // Fraction for the progress bar (0...1)
    var progressFraction: Double {
        guard totalVisitCount > 0 else { return 0 }
        return Double(closedVisits.count) / Double(totalVisitCount)
    }

    //MARK: - FUNCTION
    func isRunningLate(_ visit: CareVisit) -> Bool {
        runningLateVisitIDs.contains(visit.id)
    }
}
