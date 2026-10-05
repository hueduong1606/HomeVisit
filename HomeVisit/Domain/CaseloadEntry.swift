//  CaseloadEntry.swift
//  HomeVisit
//
//  One patient on the caseload together with their visits, used by the Caseload screens.

import Foundation

struct CaseloadEntry: Identifiable, Equatable {
    //MARK: - PROPERTIES
    let patient: Patient
    let visits: [CareVisit]          // Every visit for this patient, earliest first
    let needsVisitBooked: Bool       // Continuity-of-care flag set by ReviewCaseloadUseCase

    var id: UUID { patient.id }

    //MARK: - COMPUTED PROPERTIES
    // The next visit that has not been documented yet
    var nextScheduledVisit: CareVisit? {
        visits.first { $0.status == .scheduled }
    }

    // Visits that are already part of the clinical record, newest first
    var visitHistory: [CareVisit] {
        visits.filter { $0.status.isClosed }.sorted { $0.scheduledStart > $1.scheduledStart }
    }

    var outstandingVisits: [CareVisit] {
        visits.filter { $0.status == .scheduled }
    }
}
