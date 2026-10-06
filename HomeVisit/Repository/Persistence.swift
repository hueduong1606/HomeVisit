//  Persistence.swift
//  HomeVisit
//
//  Sets up the Core Data stack. The SQLite store lives in the App Group container.

import CoreData // Import the CoreData framework

// Struct to manage persistent data storage
struct PersistenceController {

    //MARK: - PROPERTIES
    // Singleton instance to allow global access to this controller
    static let shared = PersistenceController()

    // Preview instance using in-memory storage (for SwiftUI previews)
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true) // Create an instance with in-memory storage
        let viewContext = result.container.viewContext      // Get the view context from the container

        // One sample patient with one visit later today
        let patient = PatientRecord(context: viewContext)
        patient.patientID = UUID()
        patient.fullName = "Margaret Thompson"
        patient.homeAddress = "14 Wattle Street, Parramatta NSW 2150"
        patient.clinicalAlert = "Dog on premises – call ahead"
        patient.referralNote = "Referred by GP for leg ulcer dressing."

        let visit = CareVisitRecord(context: viewContext)
        visit.visitID = UUID()
        visit.careTypeRaw = CareType.woundCare.rawValue
        visit.scheduledStart = Date().addingTimeInterval(60 * 60)
        visit.durationMinutes = 45
        visit.statusRaw = VisitStatus.scheduled.rawValue
        visit.outcomeNote = ""
        visit.patient = patient

        do {
            try viewContext.save() // Save the context to persist the sample objects
        } catch {
            print("Preview data could not be saved: \(error)")
        }
        return result // Return the instance for preview
    }()

    let container: NSPersistentContainer // Main persistent container

    //MARK: - INITIALIZER
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "HomeVisit") // Initialize container with the model name
        if inMemory {
            // Configure in-memory store
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else if let sharedStoreURL = AppGroup.caseloadStoreURL {
            // Keep the caseload in the App Group container
            container.persistentStoreDescriptions.first!.url = sharedStoreURL
        } else {
            // App Group missing: Core Data keeps its default location so the caseload still works
            print("App Group unavailable – caseload saved in the app's own folder.")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            // Print the error instead of crashing the app
            if let error = error as NSError? {
                print("Caseload store could not be opened: \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true // Automatically merge changes from parent context
    }
}
