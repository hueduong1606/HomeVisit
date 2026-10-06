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
    @Published var errorMessage: String? = nil

    let dependencies: AppDependencies

    //MARK: - INITIALIZER
    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
    }

    //MARK: - FUNCTION

    // Re-read the caseload and the App Group referral inbox.
    // On failure the previous lists stay on screen and the nurse is told why.
    func loadCaseload() {
        do {
            patients = try dependencies.repository.fetchPatients()
        } catch {
            errorMessage = "Your patients could not be loaded. Please try again."
        }

        do {
            referrals = try dependencies.referralInbox.pendingReferrals()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
