//  ReferralDraft.swift
//  ReferralShareExtension
//
//  The referral the nurse is about to save, filled in from the shared text.

import Foundation

class ReferralDraft: ObservableObject {

    //MARK: - PROPERTIES
    @Published var referralText: String = ""
    @Published var patientName: String = ""
    @Published var homeAddress: String = ""
    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil

    //MARK: - COMPUTED PROPERTIES
    var canSave: Bool {
        !referralText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    //MARK: - FUNCTIONS

    // Adds text received from the host app (Mail, Messages, Notes, Safari)
    func append(_ sharedText: String?) {
        guard let sharedText = sharedText?.trimmingCharacters(in: .whitespacesAndNewlines),
              !sharedText.isEmpty,
              !referralText.contains(sharedText) else {
            return // Ignore empty or duplicate text (some apps send the same text twice)
        }

        referralText = referralText.isEmpty ? sharedText : referralText + "\n\n" + sharedText

        // Pre-fill name and address from labelled lines like "Patient:" and "Address:"
        if patientName.isEmpty {
            patientName = ReferralTextParser.suggestedPatientName(in: referralText)
        }
        if homeAddress.isEmpty {
            homeAddress = ReferralTextParser.suggestedHomeAddress(in: referralText)
        }
    }

    // Builds the referral that is written to the App Group inbox
    func makeReferral() -> PatientReferral {
        PatientReferral(
            suggestedPatientName: patientName.trimmingCharacters(in: .whitespacesAndNewlines),
            suggestedHomeAddress: homeAddress.trimmingCharacters(in: .whitespacesAndNewlines),
            referralText: referralText.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
