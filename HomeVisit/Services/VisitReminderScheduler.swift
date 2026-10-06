//  VisitReminderScheduler.swift
//  HomeVisit
//
//  Schedules a local notification 15 minutes before each outstanding visit.
//  Every reminder uses the VISIT_REMINDER category, so the
//  VisitReminderNotification extension shows it as a visit card.

import Foundation
import UserNotifications

enum VisitReminderScheduler {

    //MARK: - PROPERTIES
    // Business rule: remind the nurse 15 minutes before the visit so there is time to drive
    static let reminderLeadTimeMinutes = 15

    //MARK: - SETUP

    // Registers the category that the notification content extension listens for
    static func registerReminderCategory() {
        let visitReminderCategory = UNNotificationCategory(
            identifier: VisitReminderPayload.categoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([visitReminderCategory])
    }

    // Asks once for permission to show visit reminders
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            print("Visit reminders allowed: \(granted)")
        }
    }

    //MARK: - SCHEDULING

    // Replaces all pending reminders with one per outstanding visit
    static func rescheduleReminders(for visits: [CareVisit]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for visit in visits {
            let reminderDate = visit.scheduledStart.addingTimeInterval(TimeInterval(-reminderLeadTimeMinutes * 60))
            let secondsUntilReminder = reminderDate.timeIntervalSinceNow
            if secondsUntilReminder > 0 {
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: secondsUntilReminder, repeats: false)
                let request = UNNotificationRequest(identifier: visit.id.uuidString, content: makeReminderContent(for: visit), trigger: trigger)
                center.add(request, withCompletionHandler: nil)
            }
        }
    }

    // Lets the nurse see the visit reminder straight away – it arrives in 5 seconds
    static func sendPreviewReminder(for visit: CareVisit) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "preview-" + visit.id.uuidString, content: makeReminderContent(for: visit), trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    //MARK: - CONTENT
    static func makeReminderContent(for visit: CareVisit) -> UNMutableNotificationContent {
        let payload = VisitReminderPayload(
            patientName: visit.patientName,
            homeAddress: visit.homeAddress,
            careTypeTitle: visit.careType.rawValue,
            scheduledStart: visit.scheduledStart,
            clinicalAlert: visit.clinicalAlert
        )

        let content = UNMutableNotificationContent()
        content.title = "Next visit: \(visit.patientName)"
        content.body = "\(visit.careType.rawValue) · \(visit.homeAddress)"
        content.sound = .default
        content.categoryIdentifier = VisitReminderPayload.categoryIdentifier // Routes to the content extension
        content.userInfo = payload.userInfo
        return content
    }
}
