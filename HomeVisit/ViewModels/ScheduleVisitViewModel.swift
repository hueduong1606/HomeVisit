//  ScheduleVisitViewModel.swift
//  HomeVisit
//
//  Holds the "Add Visit to Round" form.

import Foundation

class ScheduleVisitViewModel: ObservableObject {

    //MARK: - PROPERTIES
    @Published var patients: [Patient] = []
    @Published var selectedPatientID: UUID? = nil
    @Published var careType: CareType = .woundCare
    @Published var scheduledStart: Date = Date().addingTimeInterval(60 * 60) // One hour from now
    @Published var durationMinutes: Int = 45
    @Published var errorMessage: String? = nil

    private let repository: CaseloadRepository
    private let scheduleHomeVisit: ScheduleHomeVisitUseCase

    //MARK: - INITIALIZER
    init(dependencies: AppDependencies = .live) {
        self.repository = dependencies.repository
        self.scheduleHomeVisit = dependencies.makeScheduleHomeVisit()
    }

    //MARK: - FUNCTIONS

    // Patients for the picker (read through the repository protocol, not Core Data)
    func loadPatients() {
        patients = (try? repository.fetchPatients()) ?? []
    }

    // Returns true when the visit is on the round
    func addVisitToRound() -> Bool {
        guard let patientID = selectedPatientID else {
            errorMessage = "Choose the patient you are visiting first."
            return false
        }
        do {
            _ = try scheduleHomeVisit.execute(
                patientID: patientID,
                careType: careType,
                scheduledStart: scheduledStart,
                durationMinutes: durationMinutes
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
