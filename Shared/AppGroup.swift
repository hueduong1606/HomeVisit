//  AppGroup.swift
//  Shared by: HomeVisit app, NextVisitWidget, ReferralShareExtension, VisitReminderNotification
//
//  The App Group is the shared container that lets the app and its extensions
//  exchange data (today's round for the widget, referrals from the share sheet).

import Foundation

// MARK: - AppGroup
enum AppGroup {
    //MARK: - PROPERTIES
    // ⚠️ Must match the App Group in Config/HomeVisit.entitlements,
    //    Config/NextVisitWidget.entitlements and Config/ReferralShareExtension.entitlements
    static let identifier = "group.com.heather.HomeVisit"

    // Folder shared by the app and the extensions – nil when the App Group is not set up
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    //MARK: - FILE LOCATIONS
    // Core Data store (nil = App Group missing, Core Data then uses its default location)
    static var caseloadStoreURL: URL? {
        containerURL?.appendingPathComponent("HomeVisit.sqlite")
    }

    // Today's round written by the app, read by the widget
    static func todaysRoundSnapshotURL() throws -> URL {
        guard let containerURL = containerURL else { throw AppGroupError.sharedContainerUnavailable }
        return containerURL.appendingPathComponent("TodaysRound.json")
    }

    // Referrals written by the share extension, read by the app
    static func referralInboxURL() throws -> URL {
        guard let containerURL = containerURL else { throw AppGroupError.sharedContainerUnavailable }
        return containerURL.appendingPathComponent("ReferralInbox.json")
    }
}

// MARK: - AppGroupError
enum AppGroupError: LocalizedError {
    case sharedContainerUnavailable
    case sharedFileUnreadable

    var errorDescription: String? {
        switch self {
        case .sharedContainerUnavailable:
            return "HomeVisit can't reach its shared storage, so referrals and the widget can't be updated. In Xcode, turn on the App Group group.com.heather.HomeVisit for the app and its extensions."
        case .sharedFileUnreadable:
            return "Shared referrals could not be read. Nothing was deleted – please try again."
        }
    }
}
