//  PatientReferral.swift
//  Shared by: ReferralShareExtension (writes) and HomeVisit app (reads)
//

import Foundation


struct PatientReferral: Codable, Identifiable, Equatable {
    //PROPERTIES
    let id: UUID
    let receivedAt: Date
    var patientName: String      // Typed by the nurse in the share sheet
    var referralText: String     // The referral exactly as it was shared

    //INITIALIZER
    init(id: UUID = UUID(), receivedAt: Date = Date(), patientName: String, referralText: String) {
        self.id = id
        self.receivedAt = receivedAt
        self.patientName = patientName
        self.referralText = referralText
    }
}
