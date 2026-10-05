//  CaseloadFixtures.swift
//  HomeVisitTests
//
//  Fixed dates and sample patients so every test is repeatable,
//  whatever day or time the tests are run.

import Foundation
@testable import HomeVisit

enum CaseloadFixtures {

    //MARK: - DATES
    // Tuesday 6 October 2026, at a given time
    static func tuesday(hour: Int, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = 6
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }

    // The nurse starts the day at 8:00 AM
    static let startOfShift = tuesday(hour: 8)

    //MARK: - PATIENTS
    static let margaret = Patient(
        fullName: "Margaret Thompson",
        homeAddress: "14 Wattle Street, Parramatta NSW 2150",
        contactNumber: "0412 345 678",
        clinicalAlert: "Dog on premises – call ahead"
    )

    static let arthur = Patient(
        fullName: "Arthur Nguyen",
        homeAddress: "3/7 Banksia Road, Granville NSW 2142",
        contactNumber: "0498 765 432"
    )

    //MARK: - VISITS
    static func visit(
        for patient: Patient,
        at start: Date,
        durationMinutes: Int = 45,
        status: VisitStatus = .scheduled,
        careType: CareType = .woundCare
    ) -> CareVisit {
        CareVisit(
            patientID: patient.id,
            patientName: patient.fullName,
            homeAddress: patient.homeAddress,
            contactNumber: patient.contactNumber,
            clinicalAlert: patient.clinicalAlert,
            careType: careType,
            scheduledStart: start,
            durationMinutes: durationMinutes,
            status: status,
            outcomeNote: status == .scheduled ? "" : "Documented earlier in the day."
        )
    }
}
