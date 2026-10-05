//  AdmitPatientToCaseloadUseCase.swift
//  HomeVisit
//
//  Business operation: accept a patient onto the nurse's caseload,
//  either typed in by hand or from a referral in the Referral Inbox.

import Foundation

// MARK: - AdmitPatientError
enum AdmitPatientError: LocalizedError, Equatable {
    case patientNameMissing
    case homeAddressIncomplete
    case contactNumberInvalid
    case patientAlreadyOnCaseload(name: String)
    case caseloadCouldNotBeSaved

    // What went wrong – in the nurse's words
    var errorDescription: String? {
        switch self {
        case .patientNameMissing:
            return "The patient's full name is missing."
        case .homeAddressIncomplete:
            return "The home address needs a street number and street name."
        case .contactNumberInvalid:
            return "That contact number is too short to call."
        case .patientAlreadyOnCaseload(let name):
            return "\(name) is already on your caseload at this address."
        case .caseloadCouldNotBeSaved:
            return "The patient couldn't be added to your caseload."
        }
    }

    // What the nurse can do next
    var recoverySuggestion: String? {
        switch self {
        case .patientNameMissing:
            return "Enter the name exactly as it appears on the referral."
        case .homeAddressIncomplete:
            return "You need the full address to find the home – check the referral or call the referrer."
        case .contactNumberInvalid:
            return "Enter a number with at least \(AdmitPatientToCaseloadUseCase.minimumContactDigits) digits, or leave it blank."
        case .patientAlreadyOnCaseload:
            return "Open the patient from the Caseload tab and book a visit there instead."
        case .caseloadCouldNotBeSaved:
            return "Nothing was changed. Try again in a moment."
        }
    }
}

// MARK: - AdmitPatientToCaseloadUseCase
struct AdmitPatientToCaseloadUseCase {

    //MARK: - PROPERTIES
    let repository: CaseloadRepository
    let referralInbox: ReferralInbox

    static let minimumNameLength = 2
    static let minimumAddressLength = 8
    static let minimumContactDigits = 8

    //MARK: - FUNCTION
    func execute(
        fullName: String,
        homeAddress: String,
        contactNumber: String = "",
        clinicalAlert: String = "",
        referralNote: String = "",
        fromReferral referralID: UUID? = nil,
        now: Date = Date()
    ) throws(AdmitPatientError) -> Patient {

        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = homeAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContactNumber = contactNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        // Rule 1: the nurse must know who they are visiting
        guard trimmedName.count >= AdmitPatientToCaseloadUseCase.minimumNameLength else {
            throw AdmitPatientError.patientNameMissing
        }

        // Rule 2: the nurse must be able to find the home (street number + street name)
        let addressHasStreetNumber = trimmedAddress.contains { $0.isNumber }
        guard trimmedAddress.count >= AdmitPatientToCaseloadUseCase.minimumAddressLength, addressHasStreetNumber else {
            throw AdmitPatientError.homeAddressIncomplete
        }

        // Rule 3: a contact number is optional, but if given it must be callable
        let contactDigits = trimmedContactNumber.filter { $0.isNumber }
        if !trimmedContactNumber.isEmpty && contactDigits.count < AdmitPatientToCaseloadUseCase.minimumContactDigits {
            throw AdmitPatientError.contactNumberInvalid
        }

        // Rule 4: the same person at the same address is never admitted twice
        let currentCaseload: [Patient]
        do {
            currentCaseload = try repository.fetchPatients()
        } catch {
            throw AdmitPatientError.caseloadCouldNotBeSaved
        }
        let isAlreadyOnCaseload = currentCaseload.contains { existingPatient in
            existingPatient.fullName.caseInsensitiveCompare(trimmedName) == .orderedSame &&
            existingPatient.homeAddress.caseInsensitiveCompare(trimmedAddress) == .orderedSame
        }
        guard !isAlreadyOnCaseload else {
            throw AdmitPatientError.patientAlreadyOnCaseload(name: trimmedName)
        }

        let patient = Patient(
            fullName: trimmedName,
            homeAddress: trimmedAddress,
            contactNumber: trimmedContactNumber,
            clinicalAlert: clinicalAlert.trimmingCharacters(in: .whitespacesAndNewlines),
            referralNote: referralNote.trimmingCharacters(in: .whitespacesAndNewlines),
            admittedOn: now
        )

        do {
            try repository.admitPatient(patient)
        } catch {
            throw AdmitPatientError.caseloadCouldNotBeSaved
        }

        // Rule 5: a referral leaves the inbox only once the patient is safely admitted
        if let referralID = referralID {
            referralInbox.removeReferral(id: referralID)
        }

        return patient
    }
}
