//  ReferralInbox.swift
//  HomeVisit
//
//  Referrals shared into HomeVisit from Mail, Messages or Notes wait here
//  until the nurse admits the patient or declines the referral.

import Foundation

// MARK: - ReferralInbox
protocol ReferralInbox {
    func pendingReferrals() -> [PatientReferral]
    func removeReferral(id: UUID)
}

// MARK: - AppGroupReferralInbox
/// Reads the JSON inbox that the ReferralShareExtension writes into the App Group container.
struct AppGroupReferralInbox: ReferralInbox {

    func pendingReferrals() -> [PatientReferral] {
        SharedContainerStore.loadReferrals()
    }

    func removeReferral(id: UUID) {
        SharedContainerStore.removeReferral(id: id)
    }
}

// MARK: - PreviewReferralInbox
/// Sample referrals for SwiftUI previews.
struct PreviewReferralInbox: ReferralInbox {

    func pendingReferrals() -> [PatientReferral] {
        [
            PatientReferral(
                receivedAt: Date().addingTimeInterval(-3 * 60 * 60),
                suggestedPatientName: "Beatrice Collins",
                suggestedHomeAddress: "5 Marsden Street, Parramatta NSW 2150",
                referralText: "Patient: Beatrice Collins\nAddress: 5 Marsden Street, Parramatta NSW 2150\nDischarged from Westmead Hospital after hip replacement. Please review wound and mobility within 48 hours."
            )
        ]
    }

    func removeReferral(id: UUID) {}
}
