//  PatientReferral.swift
//  Shared by: ReferralShareExtension (writes) and HomeVisit app (reads)
//
//  A referral a nurse received from a GP or hospital (email, message, notes)
//  and shared into HomeVisit. It waits in the Referral Inbox until the nurse
//  admits the patient to the caseload.

import Foundation

struct PatientReferral: Codable, Equatable, Identifiable {
    //MARK: - PROPERTIES
    let id: UUID
    let receivedAt: Date
    var suggestedPatientName: String     // Pre-filled from "Patient:" line, editable
    var suggestedHomeAddress: String     // Pre-filled from "Address:" line, editable
    var referralText: String             // Full text exactly as it was shared

    //MARK: - INITIALIZER
    init(
        id: UUID = UUID(),
        receivedAt: Date = Date(),
        suggestedPatientName: String,
        suggestedHomeAddress: String,
        referralText: String
    ) {
        self.id = id
        self.receivedAt = receivedAt
        self.suggestedPatientName = suggestedPatientName
        self.suggestedHomeAddress = suggestedHomeAddress
        self.referralText = referralText
    }

    //MARK: - COMPUTED PROPERTIES
    // Title shown in the inbox list
    var inboxTitle: String {
        suggestedPatientName.isEmpty ? "Unnamed referral" : suggestedPatientName
    }

    // First line of the referral, used as a preview under the title
    var previewLine: String {
        referralText
            .components(separatedBy: .newlines)
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? ""
    }
}
