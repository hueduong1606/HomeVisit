//  HomeVisitApp.swift
//  HomeVisit
//
//  App entry point. Registers the visit-reminder notification category used by
//  the VisitReminderNotification content extension.

import SwiftUI
import UserNotifications

@main
struct HomeVisitApp: App {

    //MARK: - INITIALIZER
    init() {
        // Category must be registered so reminders show the rich visit card and "Start Visit" button
        VisitReminderScheduler.registerReminderCategory()
        // Show reminders as banners even while the nurse is using the app
        UNUserNotificationCenter.current().delegate = ReminderPresentationDelegate.shared
    }

    //MARK: - BODY
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
