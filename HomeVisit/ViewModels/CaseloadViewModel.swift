//  CaseloadViewModel.swift
//  HomeVisit
//
//  Single source of truth for the Caseload screen:
//  referrals waiting (from the Share Extension) and patients on the caseload.

import Foundation

class CaseloadViewModel: ObservableObject {

    //MARK: - PROPERTIES
    @Published var patients: [Patient] = []
    @Published var referrals: [PatientReferral] = []

    let dependencies: AppDependencies

    //MARK: - INITIALIZER
    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
    }

    //MARK: - FUNCTION

    // Re-read the caseload and the App Group referral inbox
    func loadCaseload() {
        patients = (try? dependencies.repository.fetchPatients()) ?? []
        referrals = dependencies.referralInbox.pendingReferrals()
    }
}
