//  VisitStatus.swift
//  HomeVisit
//
//  Where a home visit is in its lifecycle, and the outcome a nurse can record.

import Foundation

// MARK: - VisitStatus
/// Where a home visit is in its lifecycle.
/// Business Rule: once a visit is closed (completed or no access), its outcome is part of the clinical record.
enum VisitStatus: String {
    case scheduled = "Scheduled"   // On the round, not yet documented
    case completed = "Completed"   // Care delivered and clinical note written
    case noAccess = "No access"    // Nurse arrived but could not get into the home

    // A visit is closed once its outcome is part of the clinical record
    var isClosed: Bool {
        self != .scheduled
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
}
