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

    static let remindersOffMessage = "Visit reminders are turned off. Turn them on in Settings → Notifications → HomeVisit."

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

    // Asks once for permission. The completion gives a message for the nurse, or nil when allowed.
    static func requestPermission(completion: @escaping (String?) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion("Visit reminders could not be set up: \(error.localizedDescription)")
                } else if !granted {
                    completion(VisitReminderScheduler.remindersOffMessage)
                } else {
                    completion(nil)
                }
            }
        }
    }

    //MARK: - SCHEDULING

    // Replaces all pending reminders with one per outstanding visit (only if reminders are allowed)
    static func rescheduleReminders(for visits: [CareVisit]) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("Reminders not scheduled – notifications are turned off.")
                return
            }
            center.removeAllPendingNotificationRequests()

            for visit in visits {
                let reminderDate = visit.scheduledStart.addingTimeInterval(TimeInterval(-VisitReminderScheduler.reminderLeadTimeMinutes * 60))
                let secondsUntilReminder = reminderDate.timeIntervalSinceNow
                if secondsUntilReminder > 0 {
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: secondsUntilReminder, repeats: false)
                    let request = UNNotificationRequest(identifier: visit.id.uuidString, content: VisitReminderScheduler.makeReminderContent(for: visit), trigger: trigger)
                    center.add(request) { error in
                        if let error = error {
                            print("Reminder for \(visit.patientName) not scheduled: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }

    // Sends the visit reminder in 5 seconds. The completion says whether it really was scheduled.
    static func sendPreviewReminder(for visit: CareVisit, completion: @escaping (String) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                DispatchQueue.main.async {
                    completion(VisitReminderScheduler.remindersOffMessage)
                }
                return
            }

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: "preview-" + visit.id.uuidString, content: VisitReminderScheduler.makeReminderContent(for: visit), trigger: trigger)
            center.add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion("The reminder could not be scheduled: \(error.localizedDescription)")
                    } else {
                        completion("Reminder scheduled – it arrives in 5 seconds. Go to the Home Screen or lock the screen to see it.")
                    }
                }
            }
        }
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
