//  ReferralInbox.swift
//  HomeVisit
//
//  Referrals shared into HomeVisit by the Share Extension wait here
//  until the nurse admits the patient to the caseload.

import Foundation

// MARK: - ReferralInbox
protocol ReferralInbox {
    func pendingReferrals() -> [PatientReferral]
    func removeReferral(id: UUID)
}

// MARK: - AppGroupReferralInbox
/// Reads the JSON file the Share Extension writes into the App Group container.
struct AppGroupReferralInbox: ReferralInbox {

    func pendingReferrals() -> [PatientReferral] {
        SharedContainerStore.loadReferrals()
    }

    func removeReferral(id: UUID) {
        SharedContainerStore.removeReferral(id: id)
    }
}

// MARK: - PreviewReferralInbox
/// One sample referral for SwiftUI previews.
struct PreviewReferralInbox: ReferralInbox {

    func pendingReferrals() -> [PatientReferral] {
        [PatientReferral(patientName: "Beatrice Collins", referralText: "Discharged after hip replacement. Please review wound within 48 hours.")]
    }

    func removeReferral(id: UUID) {}
}
