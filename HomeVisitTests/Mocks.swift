//  Mocks.swift
//  HomeVisitTests
//
//  In-memory stand-ins for the repository, the widget/reminder sync and the
//  referral inbox. The tests never touch the real Core Data stack or App Group.

import Foundation
@testable import HomeVisit

// MARK: - MockCaseloadRepository
class MockCaseloadRepository: CaseloadRepository {
    var patients: [Patient] = []
    var visits: [CareVisit] = []

    func fetchPatients() throws -> [Patient] {
        patients
    }

    func findPatient(id: UUID) throws -> Patient? {
        patients.first { $0.id == id }
    }

    func admitPatient(_ patient: Patient) throws {
        patients.append(patient)
    }

    func findVisit(id: UUID) throws -> CareVisit? {
        visits.first { $0.id == id }
    }

    func fetchVisits(scheduledOn day: Date) throws -> [CareVisit] {
        visits.filter { Calendar.current.isDate($0.scheduledStart, inSameDayAs: day) }
    }

    // Same domain condition as the Core Data predicate: that day AND still scheduled
    func fetchOutstandingVisits(scheduledOn day: Date) throws -> [CareVisit] {
        try fetchVisits(scheduledOn: day).filter { $0.status == .scheduled }
    }

    func fetchOutstandingVisits(from start: Date, before end: Date) throws -> [CareVisit] {
        visits
            .filter { $0.status == .scheduled && $0.scheduledStart >= start && $0.scheduledStart < end }
            .sorted { $0.scheduledStart < $1.scheduledStart }
    }

    func saveVisit(_ visit: CareVisit) throws {
        visits.removeAll { $0.id == visit.id }
        visits.append(visit)
    }
}

// MARK: - MockRoundSync
// Counts how often a Use Case asked for the widget to be refreshed
class MockRoundSync: RoundSyncing {
    var roundDidChangeCallCount = 0

    func roundDidChange() {
        roundDidChangeCallCount += 1
    }
}

// MARK: - MockReferralInbox
class MockReferralInbox: ReferralInbox {
    var referrals: [PatientReferral] = []

    func pendingReferrals() throws -> [PatientReferral] {
        referrals
    }

    func removeReferral(id: UUID) throws {
        referrals.removeAll { $0.id == id }
    }
}

// MARK: - Test data
// Fixed times on one day so the tests give the same result whenever they run
enum TestData {
    static func tuesday(hour: Int, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = 6
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }

    static let margaret = Patient(fullName: "Margaret Thompson", homeAddress: "14 Wattle Street, Parramatta NSW 2150", clinicalAlert: "Dog on premises – call ahead")
    static let arthur = Patient(fullName: "Arthur Nguyen", homeAddress: "3/7 Banksia Road, Granville NSW 2142")

    static func visit(for patient: Patient, at start: Date, status: VisitStatus = .scheduled) -> CareVisit {
        CareVisit(
            patientID: patient.id,
            patientName: patient.fullName,
            homeAddress: patient.homeAddress,
            clinicalAlert: patient.clinicalAlert,
            careType: .woundCare,
            scheduledStart: start,
            durationMinutes: 45,
            status: status
        )
    }
}
