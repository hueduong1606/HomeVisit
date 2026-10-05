//  ReviewCaseloadUseCase.swift
//  HomeVisit
//
//  Business operation: review every patient on the caseload and flag anyone
//  who has no visit booked in the next 7 days (continuity of care).

import Foundation

// MARK: - ReviewCaseloadError
enum ReviewCaseloadError: LocalizedError, Equatable {
    case caseloadUnavailable

    var errorDescription: String? {
        switch self {
        case .caseloadUnavailable:
            return "Your caseload couldn't be loaded from this iPhone."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .caseloadUnavailable:
            return "Close and reopen HomeVisit. If it keeps happening, contact your team leader for the current patient list."
        }
    }
}

// MARK: - ReviewCaseloadUseCase
struct ReviewCaseloadUseCase {

    //MARK: - PROPERTIES
    let repository: CaseloadRepository

    // Business rule: every patient should have a visit booked within this many days
    static let continuityOfCareWindowDays = 7

    //MARK: - FUNCTION
    func execute(now: Date = Date()) throws(ReviewCaseloadError) -> [CaseloadEntry] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let endOfWindow = calendar.date(byAdding: .day, value: ReviewCaseloadUseCase.continuityOfCareWindowDays, to: now) ?? now

        var entries: [CaseloadEntry] = []
        do {
            for patient in try repository.fetchPatients() {
                let visits = try repository.fetchVisits(forPatient: patient.id)
                    .sorted { $0.scheduledStart < $1.scheduledStart }

                // Rule: flag patients without a booked visit in the continuity-of-care window
                let hasVisitBookedInWindow = visits.contains { visit in
                    visit.status == .scheduled &&
                    visit.scheduledStart >= startOfToday &&
                    visit.scheduledStart <= endOfWindow
                }

                entries.append(CaseloadEntry(patient: patient, visits: visits, needsVisitBooked: !hasVisitBookedInWindow))
            }
        } catch {
            throw ReviewCaseloadError.caseloadUnavailable
        }

        // Patients who need a visit booked come first, then alphabetical
        return entries.sorted { first, second in
            if first.needsVisitBooked != second.needsVisitBooked {
                return first.needsVisitBooked
            }
            return first.patient.fullName.localizedCaseInsensitiveCompare(second.patient.fullName) == .orderedAscending
        }
    }
}
