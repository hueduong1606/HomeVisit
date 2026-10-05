//  CareVisit.swift
//  HomeVisit
//
//  One booked home visit on the nurse's round.

import Foundation

struct CareVisit: Identifiable, Equatable {
    //MARK: - PROPERTIES
    let id: UUID
    let patientID: UUID
    var patientName: String
    var homeAddress: String
    var contactNumber: String
    var clinicalAlert: String
    var careType: CareType
    var scheduledStart: Date
    var durationMinutes: Int
    var status: VisitStatus
    var outcomeNote: String
    var outcomeRecordedAt: Date?

    // Business rule: a visit counts as "running late" this many minutes after its start time
    static let lateArrivalThresholdMinutes = 15

    //MARK: - INITIALIZER
    init(
        id: UUID = UUID(),
        patientID: UUID,
        patientName: String,
        homeAddress: String,
        contactNumber: String = "",
        clinicalAlert: String = "",
        careType: CareType,
        scheduledStart: Date,
        durationMinutes: Int,
        status: VisitStatus = .scheduled,
        outcomeNote: String = "",
        outcomeRecordedAt: Date? = nil
    ) {
        self.id = id
        self.patientID = patientID
        self.patientName = patientName
        self.homeAddress = homeAddress
        self.contactNumber = contactNumber
        self.clinicalAlert = clinicalAlert
        self.careType = careType
        self.scheduledStart = scheduledStart
        self.durationMinutes = durationMinutes
        self.status = status
        self.outcomeNote = outcomeNote
        self.outcomeRecordedAt = outcomeRecordedAt
    }

    //MARK: - COMPUTED PROPERTIES
    // When the nurse expects to leave the home
    var scheduledEnd: Date {
        scheduledStart.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }

    var hasClinicalAlert: Bool {
        !clinicalAlert.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Digits only, so the nurse can call ahead from the visit screen
    var dialableContactNumber: String {
        contactNumber.filter { "0123456789+".contains($0) }
    }

    //MARK: - FUNCTIONS
    // Two visits clash when one starts before the other has finished.
    // Back-to-back visits (one ends exactly when the next starts) do not clash.
    func clashes(with otherVisit: CareVisit) -> Bool {
        scheduledStart < otherVisit.scheduledEnd && otherVisit.scheduledStart < scheduledEnd
    }

    // A scheduled visit is running late once the threshold has passed and no outcome is recorded
    func isRunningLate(at now: Date) -> Bool {
        let lateFrom = scheduledStart.addingTimeInterval(TimeInterval(CareVisit.lateArrivalThresholdMinutes * 60))
        return status == .scheduled && now > lateFrom
    }

    // True when the visit falls on the same calendar day as the given date
    func isScheduled(on day: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(scheduledStart, inSameDayAs: day)
    }
}
