//  AppGroup.swift
//  Shared by: HomeVisit app, NextVisitWidget, ReferralShareExtension, VisitReminderNotification
//

import Foundation

//AppGroup
enum AppGroup {
    //PROPERTIES
    static let identifier = "group.com.heather.HomeVisit"

    // Folder shared by the app and the extensions – nil when the App Group is not set up
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    //FILE LOCATIONS
    // Core Data store (nil = App Group missing, Core Data then uses its default location)
    static var caseloadStoreURL: URL? {
        containerURL?.appendingPathComponent("HomeVisit.sqlite")
    }

    // Today's round written by the app, read by the widget
    static func todaysRoundSnapshotURL() throws -> URL {
        guard let containerURL = containerURL else { throw ReferralSharingError.sharingUnavailableOnThisDevice }
        return containerURL.appendingPathComponent("TodaysRound.json")
    }

    // Referrals written by the share extension, read by the app
    static func referralInboxURL() throws -> URL {
        guard let containerURL = containerURL else { throw ReferralSharingError.sharingUnavailableOnThisDevice }
        return containerURL.appendingPathComponent("ReferralInbox.json")
    }
}

//  ReferralSharingError
enum ReferralSharingError: LocalizedError, Equatable {
    case sharingUnavailableOnThisDevice   // The shared space between the app and its extensions is missing
    case referralsWaitingUnreadable       // The referrals waiting list exists but cannot be opened
    case referralsWaitingNotUpdated       // A referral could not be added to or removed from the list

    // What went wrong + what the nurse can do next
    var errorDescription: String? {
        switch self {
        case .sharingUnavailableOnThisDevice:
            return "Referrals can't be passed into HomeVisit on this iPhone right now. Your patients and visits are still saved – admit the patient by hand from the Caseload tab, and ask IT support to reinstall HomeVisit."
        case .referralsWaitingUnreadable:
            return "Your referrals waiting couldn't be opened. No referral has been deleted – close and reopen HomeVisit, or admit the patient by hand from the referral text."
        case .referralsWaitingNotUpdated:
            return "The referral couldn't be saved to your referrals waiting, so nothing was changed. Your referral text is still here – tap Save Referral to HomeVisit again in a moment."
        }
    }
}
