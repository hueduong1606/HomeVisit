//  HomeVisitApp.swift
//  HomeVisit
//

import SwiftUI
import UserNotifications

@main
struct HomeVisitApp: App {

    //INITIALIZER
    init() {
        // The category routes reminders to the notification content extension
        VisitReminderScheduler.registerReminderCategory()
        // Show reminders as banners even while the nurse is using the app
        UNUserNotificationCenter.current().delegate = ReminderPresentationDelegate.shared
    }

    // BODY
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
