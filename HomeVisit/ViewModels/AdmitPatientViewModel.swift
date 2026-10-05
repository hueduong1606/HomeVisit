//  AdmitPatientViewModel.swift
//  HomeVisit
//
//  Holds the "Admit to Caseload" form. When opened from the Referral Inbox
//  the form is pre-filled from the shared referral.

import Foundation

class AdmitPatientViewModel: ObservableObject {

    //MARK: - PROPERTIES
    @Published var fullName: String = ""
    @Published var homeAddress: String = ""
    @Published var contactNumber: String = ""
    @Published var clinicalAlert: String = ""
    @Published var referralNote: String = ""
    @Published var errorMessage: String? = nil

    let referral: PatientReferral?
    private let admitPatientToCaseload: AdmitPatientToCaseloadUseCase

    //MARK: - INITIALIZER
    init(referral: PatientReferral? = nil, dependencies: AppDependencies = .live) {
        self.referral = referral
        self.admitPatientToCaseload = dependencies.makeAdmitPatientToCaseload()

        // Pre-fill from the referral so the nurse only checks and corrects
        if let referral = referral {
            self.fullName = referral.suggestedPatientName
            self.homeAddress = referral.suggestedHomeAddress
            self.referralNote = referral.referralText
        }
    }

    //MARK: - COMPUTED PROPERTIES
    var isFromReferral: Bool {
        referral != nil
    }

    var canAdmit: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !homeAddress.trimmingCharacters(in: .whitespaces).isEmpty
    }

    //MARK: - FUNCTION

    // Returns the admitted patient, or nil (with errorMessage set) if a business rule failed
    func admitPatient() -> Patient? {
        do {
            let patient = try admitPatientToCaseload.execute(
                fullName: fullName,
                homeAddress: homeAddress,
                contactNumber: contactNumber,
                clinicalAlert: clinicalAlert,
                referralNote: referralNote,
                fromReferral: referral?.id
            )
            errorMessage = nil
            return patient
        } catch {
            errorMessage = NurseFacingMessage.from(error)
            return nil
        }
    }
}
