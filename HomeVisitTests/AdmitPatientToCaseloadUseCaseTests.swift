//  AdmitPatientToCaseloadUseCaseTests.swift
//  HomeVisitTests
//
//  Business rules for accepting a patient onto the caseload.

import Testing
import Foundation
@testable import HomeVisit

@MainActor
struct AdmitPatientToCaseloadUseCaseTests {

    //MARK: - PROPERTIES
    let repository = MockCaseloadRepository()
    let referralInbox = MockReferralInbox()

    var admitPatientToCaseload: AdmitPatientToCaseloadUseCase {
        AdmitPatientToCaseloadUseCase(repository: repository, referralInbox: referralInbox)
    }

    //MARK: - HAPPY PATHS

    @Test("A patient with a full name and street address joins the caseload")
    func admittingPatientWithFullDetails_addsToCaseload() throws {
        let patient = try admitPatientToCaseload.execute(
            fullName: "  Beatrice Collins ",
            homeAddress: "5 Marsden Street, Parramatta NSW 2150",
            contactNumber: "0400 555 123",
            clinicalAlert: "Lives alone",
            referralNote: "Post hip replacement",
            now: CaseloadFixtures.startOfShift
        )

        #expect(patient.fullName == "Beatrice Collins", "Name is saved without stray spaces")
        #expect(repository.patients.count == 1)
        #expect(repository.patients.first?.admittedOn == CaseloadFixtures.startOfShift)
    }

    @Test("Admitting a patient from a shared referral removes it from the Referral Inbox")
    func admittingFromReferral_removesReferralFromInbox() throws {
        // --- GIVEN ---
        let referral = PatientReferral(
            suggestedPatientName: "Beatrice Collins",
            suggestedHomeAddress: "5 Marsden Street, Parramatta NSW 2150",
            referralText: "Patient: Beatrice Collins"
        )
        referralInbox.referrals = [referral]

        // --- WHEN ---
        _ = try admitPatientToCaseload.execute(
            fullName: referral.suggestedPatientName,
            homeAddress: referral.suggestedHomeAddress,
            fromReferral: referral.id
        )

        // --- THEN ---
        #expect(referralInbox.referrals.isEmpty)
        #expect(referralInbox.removedReferralIDs == [referral.id])
    }

    //MARK: - DOMAIN ERRORS

    @Test("An address without a street number is rejected because the nurse could not find the home")
    func addressWithoutStreetNumber_isRejected() {
        #expect(throws: AdmitPatientError.homeAddressIncomplete) {
            try admitPatientToCaseload.execute(
                fullName: "Beatrice Collins",
                homeAddress: "Marsden Street, Parramatta"
            )
        }
        #expect(repository.patients.isEmpty)
    }

    @Test("The same person at the same address cannot be admitted twice (ignoring capital letters)")
    func samePatientAtSameAddress_isRejectedAsDuplicate() {
        repository.patients = [CaseloadFixtures.margaret]

        #expect(throws: AdmitPatientError.patientAlreadyOnCaseload(name: "margaret thompson")) {
            try admitPatientToCaseload.execute(
                fullName: "margaret thompson",
                homeAddress: "14 WATTLE STREET, PARRAMATTA NSW 2150"
            )
        }
    }

    @Test("A referral stays in the inbox if the patient could not be admitted")
    func failedAdmission_keepsReferralInInbox() {
        let referral = PatientReferral(suggestedPatientName: "", suggestedHomeAddress: "", referralText: "Please visit")
        referralInbox.referrals = [referral]

        #expect(throws: AdmitPatientError.patientNameMissing) {
            try admitPatientToCaseload.execute(fullName: " ", homeAddress: "5 Marsden Street", fromReferral: referral.id)
        }
        #expect(referralInbox.referrals.count == 1, "The referral must not be lost")
    }

    //MARK: - BOUNDARY CONDITIONS

    @Test("A contact number is optional, but one with fewer than 8 digits is rejected")
    func shortContactNumber_isRejected() throws {
        #expect(throws: AdmitPatientError.contactNumberInvalid) {
            try admitPatientToCaseload.execute(
                fullName: "Beatrice Collins",
                homeAddress: "5 Marsden Street, Parramatta",
                contactNumber: "9876 543"   // 7 digits
            )
        }

        // Blank number is fine
        let patient = try admitPatientToCaseload.execute(
            fullName: "Beatrice Collins",
            homeAddress: "5 Marsden Street, Parramatta",
            contactNumber: ""
        )
        #expect(patient.contactNumber.isEmpty)
    }
}
