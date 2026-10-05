//  RoundSnapshot.swift
//  Shared by: HomeVisit app (writes) and NextVisitWidget (reads)
//
//  A small, Codable copy of today's round. The widget cannot open the Core Data
//  store safely while the app is writing, so the app publishes this snapshot to
//  the App Group after every change to the round.

import Foundation

// MARK: - RoundSnapshot
struct RoundSnapshot: Codable, Equatable {
    //MARK: - PROPERTIES
    let roundDate: Date                       // Start of the day this round belongs to
    let generatedAt: Date                     // When the app last published it
    let closedVisitCount: Int                 // Completed + no access
    let totalVisitCount: Int
    let upcomingVisits: [RoundSnapshotVisit]  // Outstanding visits, earliest first

    //MARK: - COMPUTED PROPERTIES
    var nextVisit: RoundSnapshotVisit? {
        upcomingVisits.first
    }

    var outstandingVisitCount: Int {
        upcomingVisits.count
    }

    //MARK: - FUNCTION
    // A snapshot from yesterday must not be shown as today's round
    func isForToday(now: Date = Date()) -> Bool {
        Calendar.current.isDate(roundDate, inSameDayAs: now)
    }
}

// MARK: - RoundSnapshotVisit
struct RoundSnapshotVisit: Codable, Equatable, Identifiable {
    let id: UUID
    let patientName: String
    let homeAddress: String
    let careTypeTitle: String
    let careTypeSymbol: String
    let scheduledStart: Date
    let durationMinutes: Int
    let clinicalAlert: String

    // "Margaret Thompson" -> "Margaret T." (less identifying on the Lock Screen)
    var patientShortName: String {
        let parts = patientName.split(separator: " ")
        guard let firstName = parts.first else { return patientName }
        guard parts.count > 1, let surnameInitial = parts.last?.first else { return String(firstName) }
        return "\(firstName) \(surnameInitial)."
    }

    var hasClinicalAlert: Bool {
        !clinicalAlert.isEmpty
    }
}

// MARK: - Sample data for widget placeholders and previews
extension RoundSnapshot {
    static var sample: RoundSnapshot {
        let now = Date()
        return RoundSnapshot(
            roundDate: Calendar.current.startOfDay(for: now),
            generatedAt: now,
            closedVisitCount: 3,
            totalVisitCount: 7,
            upcomingVisits: [
                RoundSnapshotVisit(
                    id: UUID(),
                    patientName: "Margaret Thompson",
                    homeAddress: "14 Wattle Street, Parramatta",
                    careTypeTitle: "Wound care",
                    careTypeSymbol: "bandage.fill",
                    scheduledStart: now.addingTimeInterval(25 * 60),
                    durationMinutes: 45,
                    clinicalAlert: "Dog on premises – call ahead"
                ),
                RoundSnapshotVisit(
                    id: UUID(),
                    patientName: "Arthur Nguyen",
                    homeAddress: "3/7 Banksia Road, Granville",
                    careTypeTitle: "Medication review",
                    careTypeSymbol: "pills.fill",
                    scheduledStart: now.addingTimeInterval(95 * 60),
                    durationMinutes: 30,
                    clinicalAlert: ""
                )
            ]
        )
    }
}
