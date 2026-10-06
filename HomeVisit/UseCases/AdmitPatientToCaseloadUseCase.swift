//  AdmitPatientToCaseloadUseCase.swift
//  HomeVisit
//
//  Business operation: accept a patient onto the nurse's caseload,
//  typed in by hand or from a referral shared into HomeVisit.

import Foundation

// MARK: - AdmitPatientError
enum AdmitPatientError: LocalizedError, Equatable {
    case patientNameMissing
    case homeAddressIncomplete
    case patientAlreadyOnCaseload(name: String)
    case caseloadCouldNotBeSaved
    case referralNotCleared(name: String)

    // What went wrong + what the nurse can do next
    var errorDescription: String? {
        switch self {
        case .patientNameMissing:
            return "The patient's full name is missing. Enter the name exactly as it appears on the referral."
        case .homeAddressIncomplete:
            return "The home address needs a street number and street name, otherwise you can't find the home. Check the referral or call the referrer."
        case .patientAlreadyOnCaseload(let name):
            return "\(name) is already on your caseload at this address. Book a visit for them from Today's Round instead."
        case .caseloadCouldNotBeSaved:
            return "The patient couldn't be added to your caseload. Nothing was changed – please try again."
        case .referralNotCleared(let name):
            return "\(name) is now on your caseload, but the referral is still in Referrals waiting. Don't admit it again – reopen HomeVisit and check the App Group is set up."
        }
    }
}

// MARK: - AdmitPatientToCaseloadUseCase
struct AdmitPatientToCaseloadUseCase {

    //MARK: - PROPERTIES
    let repository: CaseloadRepository
    let referralInbox: ReferralInbox

    //MARK: - FUNCTION
    func execute(
        fullName: String,
        homeAddress: String,
        clinicalAlert: String = "",
        referralNote: String = "",
        fromReferral referralID: UUID? = nil
    ) throws(AdmitPatientError) -> Patient {

        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = homeAddress.trimmingCharacters(in: .whitespacesAndNewlines)

        // Rule 1: the nurse must know who they are visiting
        guard !trimmedName.isEmpty else {
            throw AdmitPatientError.patientNameMissing
        }

        // Rule 2: the nurse must be able to find the home (street number + street name)
        let addressHasStreetNumber = trimmedAddress.contains { $0.isNumber }
        guard addressHasStreetNumber && trimmedAddress.count >= 8 else {
            throw AdmitPatientError.homeAddressIncomplete
        }

        // Rule 3: the same person at the same address is never admitted twice
        let currentCaseload: [Patient]
        do {
            currentCaseload = try repository.fetchPatients()
        } catch {
            throw AdmitPatientError.caseloadCouldNotBeSaved
        }
        for existingPatient in currentCaseload {
            if existingPatient.fullName.lowercased() == trimmedName.lowercased()
                && existingPatient.homeAddress.lowercased() == trimmedAddress.lowercased() {
                throw AdmitPatientError.patientAlreadyOnCaseload(name: trimmedName)
            }
        }

        let patient = Patient(
            fullName: trimmedName,
            homeAddress: trimmedAddress,
            clinicalAlert: clinicalAlert.trimmingCharacters(in: .whitespacesAndNewlines),
            referralNote: referralNote.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try repository.admitPatient(patient)
        } catch {
            throw AdmitPatientError.caseloadCouldNotBeSaved
        }

        // Rule 4: a shared referral leaves the inbox only once the patient is safely admitted
        if let referralID = referralID {
            do {
                try referralInbox.removeReferral(id: referralID)
            } catch {
                throw AdmitPatientError.referralNotCleared(name: trimmedName)
            }
        }

        return patient
    }
}
