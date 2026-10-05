//  VisitReminderScheduler.swift
//  HomeVisit
//
//  Schedules a local notification before each outstanding visit.
//  Notifications use the VISIT_REMINDER category, so the
//  VisitReminderNotification extension draws them as a rich visit card.

import Foundation
import UserNotifications

enum VisitReminderScheduler {

    //MARK: - PROPERTIES
    // Business rule: remind the nurse 15 minutes before the visit so there is time to drive
    static let reminderLeadTimeMinutes = 15
    static let reminderIdentifierPrefix = "visit-reminder-"
    static let previewIdentifierPrefix = "preview-reminder-"

    //MARK: - SETUP

    // Registers the category the content extension listens for, plus a "Start Visit" button
    static func registerReminderCategory() {
        let startVisitAction = UNNotificationAction(
            identifier: VisitReminderPayload.startVisitActionIdentifier,
            title: "Start Visit",
            options: [.foreground]
        )
        let visitReminderCategory = UNNotificationCategory(
            identifier: VisitReminderPayload.categoryIdentifier,
            actions: [startVisitAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([visitReminderCategory])
    }

    // Asks once for permission to show visit reminders
    static func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Reminder permission request failed: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    //MARK: - SCHEDULING

    // Replaces every pending visit reminder with one per outstanding visit
    static func reschedule(for visits: [CareVisit], now: Date = Date()) {
        let center = UNUserNotificationCenter.current()

        center.getPendingNotificationRequests { pendingRequests in
            // Remove reminders for visits that were moved, documented or cancelled
            let staleIdentifiers = pendingRequests
                .map { $0.identifier }
                .filter { $0.hasPrefix(VisitReminderScheduler.reminderIdentifierPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: staleIdentifiers)

            for visit in visits where visit.status == .scheduled {
                let reminderDate = visit.scheduledStart.addingTimeInterval(TimeInterval(-VisitReminderScheduler.reminderLeadTimeMinutes * 60))
                guard reminderDate > now else { continue } // Too late to remind

                let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let request = UNNotificationRequest(
                    identifier: VisitReminderScheduler.reminderIdentifierPrefix + visit.id.uuidString,
                    content: VisitReminderScheduler.makeReminderContent(for: visit),
                    trigger: trigger
                )
                center.add(request) { error in
                    if let error = error {
                        print("Reminder for \(visit.patientName) could not be scheduled: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // Lets the nurse (or a marker) see the rich reminder straight away – fires in 5 seconds
    static func sendPreviewReminder(for visit: CareVisit) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: previewIdentifierPrefix + visit.id.uuidString,
            content: makeReminderContent(for: visit),
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Preview reminder could not be scheduled: \(error.localizedDescription)")
            }
        }
    }

    //MARK: - CONTENT

    static func makeReminderContent(for visit: CareVisit) -> UNMutableNotificationContent {
        let payload = VisitReminderPayload(
            visitID: visit.id.uuidString,
            patientName: visit.patientName,
            homeAddress: visit.homeAddress,
            careTypeTitle: visit.careType.rawValue,
            careTypeSymbol: visit.careType.symbolName,
            scheduledStart: visit.scheduledStart,
            durationMinutes: visit.durationMinutes,
            clinicalAlert: visit.clinicalAlert
        )

        let content = UNMutableNotificationContent()
        content.title = "Next visit: \(visit.patientName)"
        content.subtitle = visit.careType.rawValue
        content.body = "\(visit.scheduledStart.formatted(date: .omitted, time: .shortened)) · \(visit.homeAddress)"
        content.sound = .default
        content.categoryIdentifier = VisitReminderPayload.categoryIdentifier // Routes to the content extension
        content.userInfo = payload.userInfo
        return content
    }
}
