//  Patient.swift
//  HomeVisit
//
//  A person on the community nurse's caseload who receives care at home.

import Foundation

struct Patient: Identifiable, Equatable {
    //PROPERTIES
    let id: UUID                 // Stable identity used by Core Data and visits
    var fullName: String         // Name the nurse uses to identify the patient
    var homeAddress: String      // Where the nurse must drive to
    var clinicalAlert: String    // Safety / access alert
    var referralNote: String     // Why the patient was referred (from the GP or hospital)

    //INITIALIZER
    init(id: UUID = UUID(), fullName: String, homeAddress: String, clinicalAlert: String = "", referralNote: String = "") {
        self.id = id
        self.fullName = fullName
        self.homeAddress = homeAddress
        self.clinicalAlert = clinicalAlert
        self.referralNote = referralNote
    }

    // True when the nurse must read a safety alert before entering the home
    var hasClinicalAlert: Bool {
        !clinicalAlert.isEmpty
    }
}
