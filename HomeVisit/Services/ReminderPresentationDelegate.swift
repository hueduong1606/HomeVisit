//  ReminderPresentationDelegate.swift
//  HomeVisit
//
//  Shows visit reminders as banners even while HomeVisit is open,
//  so the nurse never misses the next visit while documenting the current one.

import Foundation
import UserNotifications

class ReminderPresentationDelegate: NSObject, UNUserNotificationCenterDelegate {

    //MARK: - PROPERTIES
    // UNUserNotificationCenter only keeps a weak reference, so we keep the delegate here
    static let shared = ReminderPresentationDelegate()

    //MARK: - UNUserNotificationCenterDelegate
    // Called when a reminder arrives while the app is open
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
