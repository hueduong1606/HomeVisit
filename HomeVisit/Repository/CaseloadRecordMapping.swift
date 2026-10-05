//  CaseloadRecordMapping.swift
//  HomeVisit
//
//  Converts between Core Data records (PatientRecord, CareVisitRecord) and the
//  domain models (Patient, CareVisit). Only the repository uses this file.

import CoreData

// MARK: - PatientRecord <-> Patient
extension PatientRecord {

    // Core Data record -> domain model
    func toPatient() -> Patient {
        Patient(
            id: patientID ?? UUID(),
            fullName: fullName ?? "",
            homeAddress: homeAddress ?? "",
            contactNumber: contactNumber ?? "",
            clinicalAlert: clinicalAlert ?? "",
            referralNote: referralNote ?? "",
            admittedOn: admittedOn ?? Date()
        )
    }

    // Domain model -> Core Data record
    func update(from patient: Patient) {
        patientID = patient.id
        fullName = patient.fullName
        homeAddress = patient.homeAddress
        contactNumber = patient.contactNumber
        clinicalAlert = patient.clinicalAlert
        referralNote = patient.referralNote
        admittedOn = patient.admittedOn
    }
}

// MARK: - CareVisitRecord <-> CareVisit
extension CareVisitRecord {

    // Core Data record -> domain model (patient details come through the relationship)
    func toCareVisit() -> CareVisit {
        CareVisit(
            id: visitID ?? UUID(),
            patientID: patient?.patientID ?? UUID(),
            patientName: patient?.fullName ?? "Unknown patient",
            homeAddress: patient?.homeAddress ?? "",
            contactNumber: patient?.contactNumber ?? "",
            clinicalAlert: patient?.clinicalAlert ?? "",
            careType: CareType.fromStoredValue(careTypeRaw),
            scheduledStart: scheduledStart ?? Date(),
            durationMinutes: Int(durationMinutes),
            status: VisitStatus.fromStoredValue(statusRaw),
            outcomeNote: outcomeNote ?? "",
            outcomeRecordedAt: outcomeRecordedAt
        )
    }

    // Domain model -> Core Data record
    func update(from visit: CareVisit, patientRecord: PatientRecord) {
        visitID = visit.id
        careTypeRaw = visit.careType.rawValue
        scheduledStart = visit.scheduledStart
        durationMinutes = Int16(clamping: visit.durationMinutes)
        statusRaw = visit.status.rawValue
        outcomeNote = visit.outcomeNote
        outcomeRecordedAt = visit.outcomeRecordedAt
        patient = patientRecord
    }
}
