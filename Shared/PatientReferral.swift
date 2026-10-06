//  PatientReferral.swift
//  Shared by: ReferralShareExtension (writes) and HomeVisit app (reads)
//
//  A referral a nurse received from a GP or hospital and shared into HomeVisit.
//  It waits in "Referrals waiting" on the Caseload screen until the patient is admitted.

import Foundation

struct PatientReferral: Codable, Identifiable, Equatable {
    //MARK: - PROPERTIES
    let id: UUID
    let receivedAt: Date
    var patientName: String      // Typed by the nurse in the share sheet
    var referralText: String     // The referral exactly as it was shared

    //MARK: - INITIALIZER
    init(id: UUID = UUID(), receivedAt: Date = Date(), patientName: String, referralText: String) {
        self.id = id
        self.receivedAt = receivedAt
        self.patientName = patientName
        self.referralText = referralText
    }
}
