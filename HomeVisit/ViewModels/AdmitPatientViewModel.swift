//  AdmitPatientViewModel.swift
//  HomeVisit
//
//  Holds the "Admit to Caseload" form. When opened from a shared referral,
//  the patient's name and the referral text are filled in for the nurse.

import Foundation

class AdmitPatientViewModel: ObservableObject {

    //MARK: - PROPERTIES
    @Published var fullName: String = ""
    @Published var homeAddress: String = ""
    @Published var clinicalAlert: String = ""
    @Published var referralNote: String = ""
    @Published var errorMessage: String? = nil

    let referral: PatientReferral?
    private let admitPatientToCaseload: AdmitPatientToCaseloadUseCase

    //MARK: - INITIALIZER
    init(referral: PatientReferral? = nil, dependencies: AppDependencies = .live) {
        self.referral = referral
        self.admitPatientToCaseload = dependencies.makeAdmitPatientToCaseload()

        // Pre-fill from the shared referral
        if let referral = referral {
            self.fullName = referral.patientName
            self.referralNote = referral.referralText
        }
    }

    //MARK: - FUNCTION

    // Returns true when the patient is on the caseload
    func admitPatient() -> Bool {
        do {
            _ = try admitPatientToCaseload.execute(
                fullName: fullName,
                homeAddress: homeAddress,
                clinicalAlert: clinicalAlert,
                referralNote: referralNote,
                fromReferral: referral?.id
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
