//  Persistence.swift
//  HomeVisit
//
//  Sets up the Core Data stack. The SQLite store lives in the App Group container
//  so it sits alongside the files shared with the extensions.

import CoreData // Import the CoreData framework

// Struct to manage persistent data storage
struct PersistenceController {

    //MARK: - PROPERTIES
    // Singleton instance to allow global access to this controller
    static let shared = PersistenceController()

    // Load the compiled model ONCE so the shared and preview containers
    // never create two copies of the same entity descriptions
    static let managedObjectModel: NSManagedObjectModel = {
        guard let modelURL = Bundle.main.url(forResource: "HomeVisit", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("HomeVisit.xcdatamodeld is missing from the app bundle.")
        }
        return model
    }()

    // Preview instance using in-memory storage with a realistic round (for SwiftUI previews)
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true) // Create an instance with in-memory storage
        let viewContext = result.container.viewContext      // Get the view context from the container
        PreviewCaseload.insertSampleRound(into: viewContext)
        do {
            try viewContext.save() // Save the context to persist the sample objects
        } catch {
            print("Preview caseload could not be saved: \(error.localizedDescription)")
        }
        return result // Return the instance for preview
    }()

    let container: NSPersistentContainer // Main persistent container
    var storeLoadError: Error? = nil      // Set if the store could not be opened

    //MARK: - INITIALIZER
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "HomeVisit", managedObjectModel: PersistenceController.managedObjectModel)

        if inMemory {
            // Configure in-memory store (previews)
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Keep the caseload in the App Group container
            container.persistentStoreDescriptions.first!.url = AppGroup.caseloadStoreURL
        }

        var loadError: Error? = nil
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            // Record the error instead of crashing so the UI can explain the problem
            if let error = error as NSError? {
                print("Caseload store could not be opened: \(error), \(error.userInfo)")
                loadError = error
            }
        })
        storeLoadError = loadError

        container.viewContext.automaticallyMergesChangesFromParent = true // Automatically merge changes from parent context
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy  // Latest edit wins on conflict
    }
}

// MARK: - PreviewCaseload
/// Realistic sample data so every SwiftUI preview shows a believable nurse's day.
enum PreviewCaseload {

    static func insertSampleRound(into context: NSManagedObjectContext) {
        let today = Calendar.current.startOfDay(for: Date())

        let samplePatients: [(String, String, String, String, CareType, Int, VisitStatus)] = [
            ("Margaret Thompson", "14 Wattle Street, Parramatta NSW 2150", "0412 345 678", "Dog on premises – call ahead", .woundCare, 9, .completed),
            ("Arthur Nguyen", "3/7 Banksia Road, Granville NSW 2142", "0498 765 432", "", .medicationReview, 10, .scheduled),
            ("Dorothy Williams", "88 Church Street, Westmead NSW 2145", "0400 111 222", "Falls risk – uses walking frame", .postDischargeCheck, 12, .scheduled),
            ("Henry Patel", "21 Station Lane, Harris Park NSW 2150", "0433 222 999", "", .diabetesManagement, 14, .scheduled)
        ]

        for (name, address, phone, alert, careType, hour, status) in samplePatients {
            let patientRecord = PatientRecord(context: context)
            patientRecord.patientID = UUID()
            patientRecord.fullName = name
            patientRecord.homeAddress = address
            patientRecord.contactNumber = phone
            patientRecord.clinicalAlert = alert
            patientRecord.referralNote = "Referred by GP for \(careType.rawValue.lowercased())."
            patientRecord.admittedOn = today.addingTimeInterval(-7 * 24 * 60 * 60)

            let visitRecord = CareVisitRecord(context: context)
            visitRecord.visitID = UUID()
            visitRecord.careTypeRaw = careType.rawValue
            visitRecord.scheduledStart = today.addingTimeInterval(TimeInterval(hour * 60 * 60))
            visitRecord.durationMinutes = Int16(careType.typicalDurationMinutes)
            visitRecord.statusRaw = status.rawValue
            visitRecord.outcomeNote = status == .completed ? "Dressing changed, wound healing well. Review in 2 days." : ""
            visitRecord.outcomeRecordedAt = status == .completed ? Date() : nil
            visitRecord.patient = patientRecord
        }
    }
}
