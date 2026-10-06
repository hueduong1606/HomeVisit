//  ReferralInbox.swift
//  HomeVisit

import Foundation

// ReferralInbox
protocol ReferralInbox {
    func pendingReferrals() throws -> [PatientReferral]
    func removeReferral(id: UUID) throws
}

// AppGroupReferralInbox
struct AppGroupReferralInbox: ReferralInbox {

    func pendingReferrals() throws -> [PatientReferral] {
        try SharedContainerStore.loadReferrals()
    }

    func removeReferral(id: UUID) throws {
        try SharedContainerStore.removeReferral(id: id)
    }
}

// PreviewReferralInbox
/// One sample referral for SwiftUI previews.
struct PreviewReferralInbox: ReferralInbox {

    func pendingReferrals() -> [PatientReferral] {
        [PatientReferral(patientName: "Beatrice Collins", referralText: "Discharged after hip replacement. Please review wound within 48 hours.")]
    }

    func removeReferral(id: UUID) {}
}
