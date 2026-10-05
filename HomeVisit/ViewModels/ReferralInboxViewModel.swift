//  ReferralInboxViewModel.swift
//  HomeVisit
//
//  Lists referrals saved by the Share Extension into the App Group container.

import Foundation

class ReferralInboxViewModel: ObservableObject {

    //MARK: - PROPERTIES
    @Published var referrals: [PatientReferral] = []

    let dependencies: AppDependencies

    //MARK: - INITIALIZER
    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
    }

    //MARK: - FUNCTIONS

    // Re-read the inbox – a referral may have been shared while the app was in the background
    func loadReferrals() {
        referrals = dependencies.referralInbox.pendingReferrals()
    }

    // Swipe action "Decline" – e.g. the patient is outside the service area
    func decline(_ referral: PatientReferral) {
        dependencies.referralInbox.removeReferral(id: referral.id)
        loadReferrals()
    }
}
