//  CaseloadViewModel.swift
//  HomeVisit
//

import Foundation

class CaseloadViewModel: ObservableObject {

    //PROPERTIES
    @Published var patients: [Patient] = []
    @Published var referrals: [PatientReferral] = []
    @Published var errorMessage: String? = nil

    let dependencies: AppDependencies

    //INITIALIZER
    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
    }

    //FUNCTION

    // Re-read the caseload and the App Group referral inbox.
    // On failure the previous lists stay on screen and the nurse is told why.
    func loadCaseload() {
        do {
            patients = try dependencies.repository.fetchPatients()
        } catch {
            errorMessage = "Your caseload couldn't be opened. Your patients are still saved – switch to Today's Round and back to Caseload to reload it."
        }

        do {
            referrals = try dependencies.referralInbox.pendingReferrals()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
