//  VisitStatus.swift
//  HomeVisit
//

import Foundation

//VisitStatus

enum VisitStatus: String {
    case scheduled = "Scheduled"   // On the round, not yet documented
    case completed = "Completed"   // Care delivered and clinical note written
    case noAccess = "No access"    // Nurse arrived but could not get into the home

    // A visit is closed once its outcome is part of the clinical record
    var isClosed: Bool {
        self != .scheduled
    }
}

// VisitOutcome

enum VisitOutcome: String, CaseIterable, Identifiable {
    case completed = "Care completed"
    case noAccess = "No access"

    var id: String { rawValue }

    // The status the visit moves to once this outcome is recorded
    var resultingStatus: VisitStatus {
        switch self {
        case .completed:
            return .completed
        case .noAccess:
            return .noAccess
        }
    }
}
