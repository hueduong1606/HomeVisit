//  RoundSnapshot.swift
//  Shared by: HomeVisit app (writes) and NextVisitWidget (reads)
//

import Foundation

//  RoundSnapshot
struct RoundSnapshot: Codable {
    // PROPERTIES
    let roundDate: Date                       // The day this round belongs to
    let closedVisitCount: Int                 // Completed + no access
    let totalVisitCount: Int
    let upcomingVisits: [RoundSnapshotVisit]  // Outstanding visits, earliest first

  
    var nextVisit: RoundSnapshotVisit? {
        upcomingVisits.first
    }

    // FUNCTION
    // Yesterday's round must never be shown as today's
    func isForToday(now: Date = Date()) -> Bool {
        Calendar.current.isDate(roundDate, inSameDayAs: now)
    }
}

// RoundSnapshotVisit
struct RoundSnapshotVisit: Codable, Identifiable {
    let id: UUID
    let patientName: String
    let homeAddress: String
    let careTypeTitle: String
    let scheduledStart: Date
    let clinicalAlert: String
}

// Sample data for the widget gallery and previews
extension RoundSnapshot {
    static var sample: RoundSnapshot {
        RoundSnapshot(
            roundDate: Date(),
            closedVisitCount: 2,
            totalVisitCount: 5,
            upcomingVisits: [
                RoundSnapshotVisit(
                    id: UUID(),
                    patientName: "Margaret Thompson",
                    homeAddress: "14 Wattle Street, Parramatta",
                    careTypeTitle: "Wound care",
                    scheduledStart: Date().addingTimeInterval(25 * 60),
                    clinicalAlert: "Dog on premises – call ahead"
                )
            ]
        )
    }
}
