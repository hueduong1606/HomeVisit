//  Patient.swift
//  HomeVisit
//
//  A person on the community nurse's caseload who receives care at home.

import Foundation

struct Patient: Identifiable, Equatable {
    //MARK: - PROPERTIES
    let id: UUID                 // Stable identity used by Core Data and visits
    var fullName: String         // Name the nurse uses to identify the patient
    var homeAddress: String      // Where the nurse must drive to
    var contactNumber: String    // Used to call ahead before arriving
    var clinicalAlert: String    // Safety / access alert e.g. "Dog on premises – call ahead"
    var referralNote: String     // Why the patient was referred (from GP or hospital)
    var admittedOn: Date         // Date the patient joined the caseload

    //MARK: - INITIALIZER
    init(
        id: UUID = UUID(),
        fullName: String,
        homeAddress: String,
        contactNumber: String = "",
        clinicalAlert: String = "",
        referralNote: String = "",
        admittedOn: Date = Date()
    ) {
        self.id = id
        self.fullName = fullName
        self.homeAddress = homeAddress
        self.contactNumber = contactNumber
        self.clinicalAlert = clinicalAlert
        self.referralNote = referralNote
        self.admittedOn = admittedOn
    }

    //MARK: - COMPUTED PROPERTIES
    // True when the nurse must read a safety alert before entering the home
    var hasClinicalAlert: Bool {
        !clinicalAlert.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Digits only, so the phone app can dial the number
    var dialableContactNumber: String {
        contactNumber.filter { "0123456789+".contains($0) }
    }
}
