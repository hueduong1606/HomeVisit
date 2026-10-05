//  ScheduleVisitViewModel.swift
//  HomeVisit
//
//  Holds the "Add Visit to Round" form.

import Foundation

class ScheduleVisitViewModel: ObservableObject {

    //MARK: - PROPERTIES
    @Published var patients: [Patient] = []
    @Published var selectedPatientID: UUID? = nil
    @Published var careType: CareType = .woundCare {
        didSet {
            // Start from the typical length for this kind of care
            durationMinutes = careType.typicalDurationMinutes
        }
    }
    @Published var scheduledStart: Date = ScheduleVisitViewModel.nextQuarterHour()
    @Published var durationMinutes: Int = CareType.woundCare.typicalDurationMinutes
    @Published var errorMessage: String? = nil

    private let reviewCaseload: ReviewCaseloadUseCase
    private let scheduleHomeVisit: ScheduleHomeVisitUseCase

    //MARK: - INITIALIZER
    init(preselectedPatientID: UUID? = nil, dependencies: AppDependencies = .live) {
        self.reviewCaseload = dependencies.makeReviewCaseload()
        self.scheduleHomeVisit = dependencies.makeScheduleHomeVisit()
        self.selectedPatientID = preselectedPatientID
    }

    //MARK: - COMPUTED PROPERTIES
    var selectedPatient: Patient? {
        patients.first { $0.id == selectedPatientID }
    }

    var canAddToRound: Bool {
        selectedPatientID != nil
    }

    // The UI stepper uses the same safe range the Use Case enforces
    var safeDurationRange: ClosedRange<Int> {
        ScheduleHomeVisitUseCase.safeDurationRange
    }

    //MARK: - FUNCTIONS

    func loadPatients() {
        do {
            patients = try reviewCaseload.execute().map { $0.patient }
                .sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
        } catch {
            errorMessage = NurseFacingMessage.from(error)
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
            errorMessage = nil
            return true
        } catch {
            errorMessage = NurseFacingMessage.from(error)
            return false
        }
    }

    // Rounds up to the next quarter hour, e.g. 9:07 -> 9:15
    static func nextQuarterHour(after date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: date)
        let minutesToAdd = 15 - (minute % 15)
        let roundedUp = calendar.date(byAdding: .minute, value: minutesToAdd, to: date) ?? date
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: roundedUp)
        return calendar.date(from: components) ?? roundedUp
    }
}
