//  VisitReminderPayload.swift
//  Shared by: HomeVisit app (schedules reminders) and VisitReminderNotification (displays them)
//
//  The visit details packed into a notification's userInfo so the
//  Notification Content Extension can draw the visit card.

import Foundation

struct VisitReminderPayload {
    //MARK: - PROPERTIES
    // Must match UNNotificationExtensionCategory in Config/VisitReminderNotification-Info.plist
    static let categoryIdentifier = "VISIT_REMINDER"

    let patientName: String
    let homeAddress: String
    let careTypeTitle: String
    let scheduledStart: Date
    let clinicalAlert: String

    //MARK: - COMPUTED PROPERTIES
    // Dictionary stored on the notification content
    var userInfo: [String: Any] {
        [
            "patientName": patientName,
            "homeAddress": homeAddress,
            "careTypeTitle": careTypeTitle,
            "scheduledStart": scheduledStart.timeIntervalSince1970,
            "clinicalAlert": clinicalAlert
        ]
    }
}

// MARK: - Reading the payload back in the extension
extension VisitReminderPayload {
    // Returns nil when the notification was not created by HomeVisit
    init?(userInfo: [AnyHashable: Any]) {
        guard
            let patientName = userInfo["patientName"] as? String,
            let homeAddress = userInfo["homeAddress"] as? String,
            let careTypeTitle = userInfo["careTypeTitle"] as? String,
            let startInterval = userInfo["scheduledStart"] as? Double
        else {
            return nil
        }

        self.init(
            patientName: patientName,
            homeAddress: homeAddress,
            careTypeTitle: careTypeTitle,
            scheduledStart: Date(timeIntervalSince1970: startInterval),
            clinicalAlert: userInfo["clinicalAlert"] as? String ?? ""
        )
    }
}
