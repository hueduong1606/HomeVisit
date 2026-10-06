//  RoundSyncing.swift
//  HomeVisit
//

import Foundation

protocol RoundSyncing {
    func roundDidChange()
}

// Used by SwiftUI previews so they never touch the real widget or notifications
struct PreviewRoundSync: RoundSyncing {
    func roundDidChange() {}
}
