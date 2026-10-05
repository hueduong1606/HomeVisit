//  MockRoundSync.swift
//  HomeVisitTests
//
//  Records whether a Use Case asked for the widget and reminders to be refreshed.

import Foundation
@testable import HomeVisit

final class MockRoundSync: RoundSyncing {

    //MARK: - PROPERTIES
    private(set) var roundDidChangeCallCount = 0

    //MARK: - FUNCTION
    func roundDidChange() {
        roundDidChangeCallCount += 1
    }
}
