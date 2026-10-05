//  VisitStatus.swift
//  HomeVisit
//
//  Where a home visit is in its lifecycle, and the outcome a nurse can record.

import Foundation

// MARK: - VisitStatus
enum VisitStatus: String, Codable {
    case scheduled = "Scheduled"   // On the round, not yet documented
    case completed = "Completed"   // Care delivered and clinical note written
    case noAccess = "No access"    // Nurse arrived but could not get into the home

    //MARK: - PROPERTIES
    // A visit is closed once its outcome is part of the clinical record
    var isClosed: Bool {
        self != .scheduled
    }

    var symbolName: String {
        switch self {
        case .scheduled:
            return "clock"
        case .completed:
            return "checkmark.circle.fill"
        case .noAccess:
            return "door.left.hand.closed"
        }
    }

    //MARK: - FUNCTION
    static func fromStoredValue(_ value: String?) -> VisitStatus {
        VisitStatus(rawValue: value ?? "") ?? .scheduled
    }
}

// MARK: - VisitOutcome
/// The two outcomes a nurse records at the door of the patient's home.
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

    // Prompt shown above the note field so the nurse knows what to write
    var notePrompt: String {
        switch self {
        case .completed:
            return "Clinical note: care given, observations, follow-up needed"
        case .noAccess:
            return "Reason: e.g. no answer at door, patient in hospital"
        }
    }
}
