//  CareVisit.swift
//  HomeVisit
//
//  One booked home visit on the nurse's round.

import Foundation

/// A single home visit booked on a community nurse's round.
/// Business Rules:
/// - Two visits clash when one starts before the other has finished; back-to-back visits do not clash.
/// - The outcome is overdue once the planned finish time has passed and nothing has been recorded.
struct CareVisit: Identifiable, Equatable {
    //MARK: - PROPERTIES
    let id: UUID
    let patientID: UUID
    var patientName: String
    var homeAddress: String
    var clinicalAlert: String
    var careType: CareType
    var scheduledStart: Date
    var durationMinutes: Int
    var status: VisitStatus
    var outcomeNote: String

    //MARK: - INITIALIZER
    init(
        id: UUID = UUID(),
        patientID: UUID,
        patientName: String,
        homeAddress: String,
        clinicalAlert: String = "",
        careType: CareType,
        scheduledStart: Date,
        durationMinutes: Int,
        status: VisitStatus = .scheduled,
        outcomeNote: String = ""
    ) {
        self.id = id
        self.patientID = patientID
        self.patientName = patientName
        self.homeAddress = homeAddress
        self.clinicalAlert = clinicalAlert
        self.careType = careType
        self.scheduledStart = scheduledStart
        self.durationMinutes = durationMinutes
        self.status = status
        self.outcomeNote = outcomeNote
    }

    //MARK: - COMPUTED PROPERTIES
    // When the nurse expects to leave the home
    var scheduledEnd: Date {
        scheduledStart.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }

    var hasClinicalAlert: Bool {
        !clinicalAlert.isEmpty
    }

    //MARK: - FUNCTIONS
    // Two visits clash when one starts before the other has finished.
    // Back-to-back visits (one ends exactly when the next starts) do not clash.
    func clashes(with otherVisit: CareVisit) -> Bool {
        scheduledStart < otherVisit.scheduledEnd && otherVisit.scheduledStart < scheduledEnd
    }

    // The outcome is overdue once the planned finish time has passed and nothing is recorded yet.
    // (The app only knows what the nurse records – not whether she has arrived.)
    func isOutcomeOverdue(at now: Date) -> Bool {
        status == .scheduled && now > scheduledEnd
    }
}
