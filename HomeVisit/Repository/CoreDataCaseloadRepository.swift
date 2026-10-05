//  CoreDataCaseloadRepository.swift
//  HomeVisit
//
//  Core Data implementation of CaseloadRepository.
//  This is the only type in the app that creates fetch requests or saves a context.

import Foundation
import CoreData

final class CoreDataCaseloadRepository: CaseloadRepository {

    //MARK: - PROPERTIES
    private let persistenceController: PersistenceController

    // Scratchpad for fetching and saving (main queue, used from the UI thread)
    private var context: NSManagedObjectContext {
        persistenceController.container.viewContext
    }

    //MARK: - INITIALIZER
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    //MARK: - PATIENTS

    // Whole caseload, alphabetical by name
    func fetchPatients() throws -> [Patient] {
        try ensureStoreIsOpen()
        let fetchRequest: NSFetchRequest<PatientRecord> = PatientRecord.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \PatientRecord.fullName, ascending: true)]
        return try context.fetch(fetchRequest).map { $0.toPatient() }
    }

    func findPatient(id: UUID) throws -> Patient? {
        try findPatientRecord(id: id)?.toPatient()
    }

    func admitPatient(_ patient: Patient) throws {
        try ensureStoreIsOpen()
        let patientRecord = try findPatientRecord(id: patient.id) ?? PatientRecord(context: context)
        patientRecord.update(from: patient)
        try saveContext()
    }

    // Deleting the patient cascades to all of their visits (see the data model)
    func dischargePatient(id: UUID) throws {
        guard let patientRecord = try findPatientRecord(id: id) else {
            throw CaseloadRepositoryError.patientRecordMissing(id)
        }
        context.delete(patientRecord)
        try saveContext()
    }

    //MARK: - VISITS

    func findVisit(id: UUID) throws -> CareVisit? {
        try findVisitRecord(id: id)?.toCareVisit()
    }

    // Every visit for one patient, earliest first (Patient Detail screen)
    func fetchVisits(forPatient patientID: UUID) throws -> [CareVisit] {
        try ensureStoreIsOpen()
        let fetchRequest: NSFetchRequest<CareVisitRecord> = CareVisitRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "patient.patientID == %@", patientID as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CareVisitRecord.scheduledStart, ascending: true)]
        return try context.fetch(fetchRequest).map { $0.toCareVisit() }
    }

    // Every visit booked on a calendar day, whatever its status
    func fetchVisits(scheduledOn day: Date) throws -> [CareVisit] {
        try ensureStoreIsOpen()
        let (startOfDay, startOfNextDay) = dayBounds(for: day)
        let fetchRequest: NSFetchRequest<CareVisitRecord> = CareVisitRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "scheduledStart >= %@ AND scheduledStart < %@",
            startOfDay as NSDate,
            startOfNextDay as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CareVisitRecord.scheduledStart, ascending: true)]
        return try context.fetch(fetchRequest).map { $0.toCareVisit() }
    }

    // Domain query: "fetch all visits scheduled for this day that the nurse has not yet documented"
    func fetchOutstandingVisits(scheduledOn day: Date) throws -> [CareVisit] {
        try ensureStoreIsOpen()
        let (startOfDay, startOfNextDay) = dayBounds(for: day)
        let fetchRequest: NSFetchRequest<CareVisitRecord> = CareVisitRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "scheduledStart >= %@ AND scheduledStart < %@ AND statusRaw == %@",
            startOfDay as NSDate,
            startOfNextDay as NSDate,
            VisitStatus.scheduled.rawValue
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CareVisitRecord.scheduledStart, ascending: true)]
        return try context.fetch(fetchRequest).map { $0.toCareVisit() }
    }

    // Insert a new visit or update the existing one with the same id
    func saveVisit(_ visit: CareVisit) throws {
        guard let patientRecord = try findPatientRecord(id: visit.patientID) else {
            throw CaseloadRepositoryError.patientRecordMissing(visit.patientID)
        }
        let visitRecord = try findVisitRecord(id: visit.id) ?? CareVisitRecord(context: context)
        visitRecord.update(from: visit, patientRecord: patientRecord)
        try saveContext()
    }

    func deleteVisit(id: UUID) throws {
        guard let visitRecord = try findVisitRecord(id: id) else {
            throw CaseloadRepositoryError.visitRecordMissing(id)
        }
        context.delete(visitRecord)
        try saveContext()
    }

    //MARK: - PRIVATE HELPERS

    private func findPatientRecord(id: UUID) throws -> PatientRecord? {
        try ensureStoreIsOpen()
        let fetchRequest: NSFetchRequest<PatientRecord> = PatientRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "patientID == %@", id as CVarArg) // Filter by patient id
        fetchRequest.fetchLimit = 1
        return try context.fetch(fetchRequest).first
    }

    private func findVisitRecord(id: UUID) throws -> CareVisitRecord? {
        try ensureStoreIsOpen()
        let fetchRequest: NSFetchRequest<CareVisitRecord> = CareVisitRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "visitID == %@", id as CVarArg) // Filter by visit id
        fetchRequest.fetchLimit = 1
        return try context.fetch(fetchRequest).first
    }

    // Saves the context, undoing unsaved changes if Core Data rejects them
    private func saveContext() throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    private func ensureStoreIsOpen() throws {
        if persistenceController.storeLoadError != nil {
            throw CaseloadRepositoryError.storeUnavailable
        }
    }

    // Midnight-to-midnight range for a calendar day
    private func dayBounds(for day: Date) -> (Date, Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: day)
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay.addingTimeInterval(24 * 60 * 60)
        return (startOfDay, startOfNextDay)
    }
}
