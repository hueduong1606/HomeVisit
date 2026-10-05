//  MockReferralInbox.swift
//  HomeVisitTests
//
//  In-memory referral inbox – no App Group files are touched during tests.

import Foundation
@testable import HomeVisit

final class MockReferralInbox: ReferralInbox {

    //MARK: - PROPERTIES
    var referrals: [PatientReferral] = []
    private(set) var removedReferralIDs: [UUID] = []

    //MARK: - FUNCTIONS
    func pendingReferrals() -> [PatientReferral] {
        referrals
    }

    func removeReferral(id: UUID) {
        referrals.removeAll { $0.id == id }
        removedReferralIDs.append(id)
    }
}
