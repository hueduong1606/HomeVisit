//  ScheduleVisitViewModel.swift
//  HomeVisit
//


import Foundation

class ScheduleVisitViewModel: ObservableObject {

    //PROPERTIES
    @Published var patients: [Patient] = []
    @Published var selectedPatientID: UUID? = nil
    @Published var careType: CareType = .woundCare
    @Published var scheduledStart: Date = Date().addingTimeInterval(30 * 60) // 30 minutes from now
    @Published var durationMinutes: Int = 45
    @Published var errorMessage: String? = nil

    private let repository: CaseloadRepository
    private let scheduleHomeVisit: ScheduleHomeVisitUseCase

    //INITIALIZER
    init(dependencies: AppDependencies = .live) {
        self.repository = dependencies.repository
        self.scheduleHomeVisit = dependencies.makeScheduleHomeVisit()
    }

    //COMPUTED PROPERTIES
    // The date picker offers times from now until the end of the planning window (today + 14 days)
    var bookingTimes: ClosedRange<Date> {
        let now = Date()
        let calendar = Calendar.current
        let endOfPlanningWindow = calendar.date(byAdding: .day, value: ScheduleHomeVisitUseCase.planningWindowDays + 1, to: calendar.startOfDay(for: now))!
        return now...endOfPlanningWindow.addingTimeInterval(-60)
    }

    //MARK: - FUNCTIONS

    // Patients for the picker (read through the repository protocol, not Core Data)
    func loadPatients() {
        do {
            patients = try repository.fetchPatients()
        } catch {
            errorMessage = "Your caseload couldn't be opened, so no patient can be chosen. Your patients are still saved – close Add Visit to Round and open it again."
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
