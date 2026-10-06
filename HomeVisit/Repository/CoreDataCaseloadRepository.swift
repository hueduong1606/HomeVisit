//  CoreDataCaseloadRepository.swift
//  HomeVisit
//
//  Core Data implementation of CaseloadRepository.
//  This is the only type in the app that creates fetch requests or saves the context.

import Foundation
import CoreData

class CoreDataCaseloadRepository: CaseloadRepository {

    //MARK: - PROPERTIES
    private let context: NSManagedObjectContext // Scratchpad for fetching and saving

    //MARK: - INITIALIZER
    init(persistenceController: PersistenceController = .shared) {
        self.context = persistenceController.container.viewContext
    }

    //MARK: - PATIENTS

    // Whole caseload, alphabetical by name
    func fetchPatients() throws -> [Patient] {
        let fetchRequest: NSFetchRequest<PatientRecord> = PatientRecord.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \PatientRecord.fullName, ascending: true)]
        return try context.fetch(fetchRequest).map { toPatient($0) }
    }

    func findPatient(id: UUID) throws -> Patient? {
        guard let patientRecord = try findPatientRecord(id: id) else { return nil }
        return toPatient(patientRecord)
    }

    func admitPatient(_ patient: Patient) throws {
        let patientRecord = PatientRecord(context: context)
        patientRecord.patientID = patient.id
        patientRecord.fullName = patient.fullName
        patientRecord.homeAddress = patient.homeAddress
        patientRecord.clinicalAlert = patient.clinicalAlert
        patientRecord.referralNote = patient.referralNote
        try context.save()
    }

    //MARK: - VISITS

    func findVisit(id: UUID) throws -> CareVisit? {
        guard let visitRecord = try findVisitRecord(id: id) else { return nil }
        return toCareVisit(visitRecord)
    }

    // Every visit booked on a calendar day, whatever its status
    func fetchVisits(scheduledOn day: Date) throws -> [CareVisit] {
        let startOfDay = Calendar.current.startOfDay(for: day)
        let startOfNextDay = startOfDay.addingTimeInterval(24 * 60 * 60)

        let fetchRequest: NSFetchRequest<CareVisitRecord> = CareVisitRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "scheduledStart >= %@ AND scheduledStart < %@", startOfDay as NSDate, startOfNextDay as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CareVisitRecord.scheduledStart, ascending: true)]
        return try context.fetch(fetchRequest).map { toCareVisit($0) }
    }

    // Domain query: "fetch all visits scheduled for today that the nurse has not documented yet"
    func fetchOutstandingVisits(scheduledOn day: Date) throws -> [CareVisit] {
        let startOfDay = Calendar.current.startOfDay(for: day)
        let startOfNextDay = startOfDay.addingTimeInterval(24 * 60 * 60)

        let fetchRequest: NSFetchRequest<CareVisitRecord> = CareVisitRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "scheduledStart >= %@ AND scheduledStart < %@ AND statusRaw == %@",
            startOfDay as NSDate,
            startOfNextDay as NSDate,
            VisitStatus.scheduled.rawValue
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CareVisitRecord.scheduledStart, ascending: true)]
        return try context.fetch(fetchRequest).map { toCareVisit($0) }
    }

    // Insert a new visit, or update the existing one with the same id
    func saveVisit(_ visit: CareVisit) throws {
        guard let patientRecord = try findPatientRecord(id: visit.patientID) else {
            throw CaseloadRepositoryError.patientRecordMissing
        }
        let visitRecord = try findVisitRecord(id: visit.id) ?? CareVisitRecord(context: context)
        visitRecord.visitID = visit.id
        visitRecord.careTypeRaw = visit.careType.rawValue
        visitRecord.scheduledStart = visit.scheduledStart
        visitRecord.durationMinutes = Int16(visit.durationMinutes)
        visitRecord.statusRaw = visit.status.rawValue
        visitRecord.outcomeNote = visit.outcomeNote
        visitRecord.patient = patientRecord
        try context.save()
    }

    //MARK: - PRIVATE HELPERS

    private func findPatientRecord(id: UUID) throws -> PatientRecord? {
        let fetchRequest: NSFetchRequest<PatientRecord> = PatientRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "patientID == %@", id as CVarArg) // Filter by patient id
        return try context.fetch(fetchRequest).first
    }

    private func findVisitRecord(id: UUID) throws -> CareVisitRecord? {
        let fetchRequest: NSFetchRequest<CareVisitRecord> = CareVisitRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "visitID == %@", id as CVarArg) // Filter by visit id
        return try context.fetch(fetchRequest).first
    }

    // Core Data record -> domain model
    private func toPatient(_ record: PatientRecord) -> Patient {
        Patient(
            id: record.patientID ?? UUID(),
            fullName: record.fullName ?? "",
            homeAddress: record.homeAddress ?? "",
            clinicalAlert: record.clinicalAlert ?? "",
            referralNote: record.referralNote ?? ""
        )
    }

    // Core Data record -> domain model (patient details come through the relationship)
    private func toCareVisit(_ record: CareVisitRecord) -> CareVisit {
        CareVisit(
            id: record.visitID ?? UUID(),
            patientID: record.patient?.patientID ?? UUID(),
            patientName: record.patient?.fullName ?? "Unknown patient",
            homeAddress: record.patient?.homeAddress ?? "",
            clinicalAlert: record.patient?.clinicalAlert ?? "",
            careType: CareType(rawValue: record.careTypeRaw ?? "") ?? .woundCare,
            scheduledStart: record.scheduledStart ?? Date(),
            durationMinutes: Int(record.durationMinutes),
            status: VisitStatus(rawValue: record.statusRaw ?? "") ?? .scheduled,
            outcomeNote: record.outcomeNote ?? ""
        )
    }
}
