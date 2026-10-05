//  MockCaseloadRepository.swift
//  HomeVisitTests
//
//  In-memory stand-in for CoreDataCaseloadRepository.
//  Tests never touch the real Core Data stack.

import Foundation
@testable import HomeVisit

final class MockCaseloadRepository: CaseloadRepository {

    //MARK: - PROPERTIES
    var patients: [Patient] = []
    var visits: [CareVisit] = []

    // Set to true to simulate the iPhone's storage failing
    var shouldFailStorage = false

    // Spies so tests can check what the Use Case asked for
    private(set) var savedVisits: [CareVisit] = []
    private(set) var deletedVisitIDs: [UUID] = []
    private(set) var dischargedPatientIDs: [UUID] = []

    //MARK: - PATIENTS
    func fetchPatients() throws -> [Patient] {
        try failIfNeeded()
        return patients.sorted { $0.fullName < $1.fullName }
    }

    func findPatient(id: UUID) throws -> Patient? {
        try failIfNeeded()
        return patients.first { $0.id == id }
    }

    func admitPatient(_ patient: Patient) throws {
        try failIfNeeded()
        patients.removeAll { $0.id == patient.id }
        patients.append(patient)
    }

    func dischargePatient(id: UUID) throws {
        try failIfNeeded()
        patients.removeAll { $0.id == id }
        visits.removeAll { $0.patientID == id }   // Mirrors the Cascade delete rule
        dischargedPatientIDs.append(id)
    }

    //MARK: - VISITS
    func findVisit(id: UUID) throws -> CareVisit? {
        try failIfNeeded()
        return visits.first { $0.id == id }
    }

    func fetchVisits(forPatient patientID: UUID) throws -> [CareVisit] {
        try failIfNeeded()
        return visits
            .filter { $0.patientID == patientID }
            .sorted { $0.scheduledStart < $1.scheduledStart }
    }

    func fetchVisits(scheduledOn day: Date) throws -> [CareVisit] {
        try failIfNeeded()
        return visits
            .filter { Calendar.current.isDate($0.scheduledStart, inSameDayAs: day) }
            .sorted { $0.scheduledStart < $1.scheduledStart }
    }

    // Same domain condition as the Core Data predicate: that day AND status == scheduled
    func fetchOutstandingVisits(scheduledOn day: Date) throws -> [CareVisit] {
        try fetchVisits(scheduledOn: day).filter { $0.status == .scheduled }
    }

    func saveVisit(_ visit: CareVisit) throws {
        try failIfNeeded()
        visits.removeAll { $0.id == visit.id }
        visits.append(visit)
        savedVisits.append(visit)
    }

    func deleteVisit(id: UUID) throws {
        try failIfNeeded()
        visits.removeAll { $0.id == id }
        deletedVisitIDs.append(id)
    }

    //MARK: - PRIVATE
    private func failIfNeeded() throws {
        if shouldFailStorage {
            throw CaseloadRepositoryError.storeUnavailable
        }
    }
}
