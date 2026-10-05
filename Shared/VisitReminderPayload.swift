//  VisitReminderPayload.swift
//  Shared by: HomeVisit app (schedules reminders) and VisitReminderNotification (displays them)
//
//  The visit details packed into a notification's userInfo so the
//  Notification Content Extension can draw a rich visit card.

import Foundation

struct VisitReminderPayload: Equatable {
    //MARK: - PROPERTIES
    // Must match UNNotificationExtensionCategory in VisitReminderNotification-Info.plist
    static let categoryIdentifier = "VISIT_REMINDER"
    static let startVisitActionIdentifier = "START_VISIT"

    let visitID: String
    let patientName: String
    let homeAddress: String
    let careTypeTitle: String
    let careTypeSymbol: String
    let scheduledStart: Date
    let durationMinutes: Int
    let clinicalAlert: String

    //MARK: - KEYS
    private enum Key {
        static let visitID = "visitID"
        static let patientName = "patientName"
        static let homeAddress = "homeAddress"
        static let careTypeTitle = "careTypeTitle"
        static let careTypeSymbol = "careTypeSymbol"
        static let scheduledStart = "scheduledStart"
        static let durationMinutes = "durationMinutes"
        static let clinicalAlert = "clinicalAlert"
    }

    //MARK: - COMPUTED PROPERTIES
    // Dictionary stored on UNMutableNotificationContent.userInfo
    var userInfo: [String: Any] {
        [
            Key.visitID: visitID,
            Key.patientName: patientName,
            Key.homeAddress: homeAddress,
            Key.careTypeTitle: careTypeTitle,
            Key.careTypeSymbol: careTypeSymbol,
            Key.scheduledStart: scheduledStart.timeIntervalSince1970,
            Key.durationMinutes: durationMinutes,
            Key.clinicalAlert: clinicalAlert
        ]
    }

    var hasClinicalAlert: Bool {
        !clinicalAlert.isEmpty
    }
}

// MARK: - Decoding from a delivered notification
extension VisitReminderPayload {
    // Returns nil when the notification was not created by HomeVisit
    init?(userInfo: [AnyHashable: Any]) {
        guard
            let visitID = userInfo[Key.visitID] as? String,
            let patientName = userInfo[Key.patientName] as? String,
            let homeAddress = userInfo[Key.homeAddress] as? String,
            let careTypeTitle = userInfo[Key.careTypeTitle] as? String,
            let startInterval = userInfo[Key.scheduledStart] as? Double
        else {
            return nil
        }

        self.init(
            visitID: visitID,
            patientName: patientName,
            homeAddress: homeAddress,
            careTypeTitle: careTypeTitle,
            careTypeSymbol: userInfo[Key.careTypeSymbol] as? String ?? "cross.case.fill",
            scheduledStart: Date(timeIntervalSince1970: startInterval),
            durationMinutes: userInfo[Key.durationMinutes] as? Int ?? 30,
            clinicalAlert: userInfo[Key.clinicalAlert] as? String ?? ""
        )
    }
}
