//  ReminderPresentationDelegate.swift
//  HomeVisit
//

import Foundation
import UserNotifications

class ReminderPresentationDelegate: NSObject, UNUserNotificationCenterDelegate {

    //PROPERTIES
    static let shared = ReminderPresentationDelegate()

    // UNUserNotificationCenterDelegate
    // Called when a reminder arrives while the app is open
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
