//  RoundSyncing.swift
//  HomeVisit
//
//  Use Cases call roundDidChange() after every change to the nurse's round.
//  The app implementation refreshes the widget and visit reminders;
//  the unit tests use MockRoundSync to check it was called.

import Foundation

protocol RoundSyncing {
    // Publish the latest round to the Home/Lock Screen widget and reschedule visit reminders
    func roundDidChange()
}

// Used by SwiftUI previews so they never touch the real widget or notifications
struct PreviewRoundSync: RoundSyncing {
    func roundDidChange() {}
}
