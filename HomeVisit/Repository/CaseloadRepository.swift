//  CaseloadRepository.swift
//  HomeVisit
//
//  The ONLY way the rest of the app reaches stored patients and visits.
//  Use Cases depend on this protocol, never on Core Data, so unit tests can
//  swap in MockCaseloadRepository without touching the real database.

import Foundation

// MARK: - CaseloadRepository
protocol CaseloadRepository {

    //MARK: - PATIENTS
    func fetchPatients() throws -> [Patient]
    func findPatient(id: UUID) throws -> Patient?
    func admitPatient(_ patient: Patient) throws
    func dischargePatient(id: UUID) throws

    //MARK: - VISITS
    func findVisit(id: UUID) throws -> CareVisit?
    func fetchVisits(forPatient patientID: UUID) throws -> [CareVisit]
    // Every visit on a calendar day (any status), earliest first
    func fetchVisits(scheduledOn day: Date) throws -> [CareVisit]
    // Domain query: visits on a day that still need the nurse (status == scheduled), earliest first
    func fetchOutstandingVisits(scheduledOn day: Date) throws -> [CareVisit]
    // Inserts a new visit or updates an existing one with the same id
    func saveVisit(_ visit: CareVisit) throws
    func deleteVisit(id: UUID) throws
}

// MARK: - CaseloadRepositoryError
/// Low-level storage failures. Use Cases translate these into nurse-facing messages.
enum CaseloadRepositoryError: Error, Equatable {
    case patientRecordMissing(UUID)
    case visitRecordMissing(UUID)
    case storeUnavailable
}
