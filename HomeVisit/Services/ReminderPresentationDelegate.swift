//  ReminderPresentationDelegate.swift
//  HomeVisit
//
//  Shows visit reminders as banners even while HomeVisit is open,
//  so the nurse never misses the next visit while documenting the current one.

import Foundation
import UserNotifications

final class ReminderPresentationDelegate: NSObject, UNUserNotificationCenterDelegate {

    //MARK: - PROPERTIES
    // UNUserNotificationCenter keeps a weak reference, so we hold the delegate here
    static let shared = ReminderPresentationDelegate()

    //MARK: - UNUserNotificationCenterDelegate

    // Called when a reminder arrives while the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    // Called when the nurse taps the reminder or its "Start Visit" button
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Opening the app lands the nurse on Today's Round, which already lists this visit first
        completionHandler()
    }
}
