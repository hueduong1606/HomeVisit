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
    @Published var scheduledStart: Date = Date().addingTimeInterval(30 * 60) // 30 minutes from now
    @Published var durationMinutes: Int = 45
    @Published var errorMessage: String? = nil

    private let repository: CaseloadRepository
    private let scheduleHomeVisit: ScheduleHomeVisitUseCase

    //MARK: - INITIALIZER
    init(dependencies: AppDependencies = .live) {
        self.repository = dependencies.repository
        self.scheduleHomeVisit = dependencies.makeScheduleHomeVisit()
    }

    //MARK: - COMPUTED PROPERTIES
    // The date picker only offers times from now until the end of today (today's round only)
    var todaysBookingTimes: ClosedRange<Date> {
        let now = Date()
        let calendar = Calendar.current
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        let lastMinuteToday = startOfTomorrow.addingTimeInterval(-60)
        return now...max(now, lastMinuteToday)
    }

    //MARK: - FUNCTIONS

    // Patients for the picker (read through the repository protocol, not Core Data)
    func loadPatients() {
        do {
            patients = try repository.fetchPatients()
        } catch {
            errorMessage = "Your patients could not be loaded. Please try again."
        }
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
