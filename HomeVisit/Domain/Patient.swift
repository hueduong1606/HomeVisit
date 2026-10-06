//  Patient.swift
//  HomeVisit
//
//  A person on the community nurse's caseload who receives care at home.

import Foundation

/// A person on the community nurse's caseload who receives nursing care at home.
/// Business Rule: a patient is only admitted with a full name and a findable home address,
/// and the same person at the same address is never admitted twice.
struct Patient: Identifiable, Equatable {
    //MARK: - PROPERTIES
    let id: UUID                 // Stable identity used by Core Data and visits
    var fullName: String         // Name the nurse uses to identify the patient
    var homeAddress: String      // Where the nurse must drive to
    var clinicalAlert: String    // Safety / access alert e.g. "Dog on premises – call ahead"
    var referralNote: String     // Why the patient was referred (from the GP or hospital)

    //MARK: - INITIALIZER
    init(id: UUID = UUID(), fullName: String, homeAddress: String, clinicalAlert: String = "", referralNote: String = "") {
        self.id = id
        self.fullName = fullName
        self.homeAddress = homeAddress
        self.clinicalAlert = clinicalAlert
        self.referralNote = referralNote
    }

    //MARK: - COMPUTED PROPERTIES
    // True when the nurse must read a safety alert before entering the home
    var hasClinicalAlert: Bool {
        !clinicalAlert.isEmpty
    }
}
