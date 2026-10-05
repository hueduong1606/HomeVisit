//  AppGroup.swift
//  Shared by: HomeVisit app, NextVisitWidget, ReferralShareExtension, VisitReminderNotification
//
//  The App Group is the shared container that lets the app and its extensions
//  exchange data (today's round for the widget, referrals from the share sheet).

import Foundation

enum AppGroup {
    //MARK: - PROPERTIES
    // ⚠️ Must match the App Group in every target's .entitlements file (see README)
    static let identifier = "group.com.student.HomeVisit"

    // Folder shared by the app and all extensions
    static var containerURL: URL {
        if let sharedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) {
            return sharedURL
        }
        // Fallback keeps the app running if the App Group capability is not set up yet.
        // The widget and share extension will NOT see this data until the App Group is configured.
        print("⚠️ App Group '\(identifier)' is not available. Check Signing & Capabilities for every target.")
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    //MARK: - FILE LOCATIONS
    // Core Data store lives in the shared container
    static var caseloadStoreURL: URL {
        containerURL.appendingPathComponent("HomeVisit.sqlite")
    }

    // Snapshot of today's round written by the app, read by the widget
    static var todaysRoundSnapshotURL: URL {
        containerURL.appendingPathComponent("TodaysRoundSnapshot.json")
    }

    // Referrals written by the share extension, read by the app
    static var referralInboxURL: URL {
        containerURL.appendingPathComponent("ReferralInbox.json")
    }
}
