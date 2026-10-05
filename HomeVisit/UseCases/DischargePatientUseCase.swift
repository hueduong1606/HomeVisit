//  DischargePatientUseCase.swift
//  HomeVisit
//
//  Business operation: discharge a patient from the community nursing caseload
//  once their episode of care is finished.

import Foundation

// MARK: - DischargePatientError
enum DischargePatientError: LocalizedError, Equatable {
    case patientNotOnCaseload
    case visitsStillOutstanding(count: Int)
    case caseloadCouldNotBeUpdated

    var errorDescription: String? {
        switch self {
        case .patientNotOnCaseload:
            return "This patient has already been discharged."
        case .visitsStillOutstanding(let count):
            return count == 1
                ? "This patient still has 1 visit that hasn't been documented."
                : "This patient still has \(count) visits that haven't been documented."
        case .caseloadCouldNotBeUpdated:
            return "The patient couldn't be discharged."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .patientNotOnCaseload:
            return "Pull down to refresh your caseload."
        case .visitsStillOutstanding:
            return "Record an outcome for, or cancel, every outstanding visit before discharging so nothing is left undocumented."
        case .caseloadCouldNotBeUpdated:
            return "Nothing was changed. Try again in a moment."
        }
    }
}

// MARK: - DischargePatientUseCase
struct DischargePatientUseCase {

    //MARK: - PROPERTIES
    let repository: CaseloadRepository
    let roundSync: RoundSyncing

    //MARK: - FUNCTION
    func execute(patientID: UUID) throws(DischargePatientError) {
        let foundPatient: Patient?
        let visits: [CareVisit]
        do {
            foundPatient = try repository.findPatient(id: patientID)
            visits = try repository.fetchVisits(forPatient: patientID)
        } catch {
            throw DischargePatientError.caseloadCouldNotBeUpdated
        }

        guard foundPatient != nil else {
            throw DischargePatientError.patientNotOnCaseload
        }

        // Business rule: never discharge while a booked visit is still undocumented
        let outstandingVisitCount = visits.filter { $0.status == .scheduled }.count
        guard outstandingVisitCount == 0 else {
            throw DischargePatientError.visitsStillOutstanding(count: outstandingVisitCount)
        }

        do {
            try repository.dischargePatient(id: patientID)
        } catch {
            throw DischargePatientError.caseloadCouldNotBeUpdated
        }

        roundSync.roundDidChange()
    }
}
