//  CaseloadRepository.swift
//  HomeVisit
//
//  The ONLY way the rest of the app reaches stored patients and visits.
//  Use Cases and ViewModels depend on this protocol, never on Core Data,
//  so unit tests can swap in MockCaseloadRepository.

import Foundation

// MARK: - CaseloadRepository
protocol CaseloadRepository {

    //MARK: - PATIENTS
    func fetchPatients() throws -> [Patient]
    func findPatient(id: UUID) throws -> Patient?
    func admitPatient(_ patient: Patient) throws

    //MARK: - VISITS
    func findVisit(id: UUID) throws -> CareVisit?
    // Every visit on a calendar day (any status), earliest first
    func fetchVisits(scheduledOn day: Date) throws -> [CareVisit]
    // Domain query: visits on a day that the nurse has not documented yet, earliest first
    func fetchOutstandingVisits(scheduledOn day: Date) throws -> [CareVisit]
    // Inserts a new visit or updates the existing one with the same id
    func saveVisit(_ visit: CareVisit) throws
}

// MARK: - CaseloadRepositoryError
enum CaseloadRepositoryError: Error {
    case patientRecordMissing
}
