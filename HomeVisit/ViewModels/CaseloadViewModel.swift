//  CaseloadViewModel.swift
//  HomeVisit
//
//  Single source of truth for the Caseload and Patient Detail screens.

import Foundation

class CaseloadViewModel: ObservableObject {

    //MARK: - PROPERTIES
    @Published var entries: [CaseloadEntry] = []
    @Published var errorMessage: String? = nil

    let dependencies: AppDependencies
    private let reviewCaseload: ReviewCaseloadUseCase
    private let dischargePatient: DischargePatientUseCase

    //MARK: - INITIALIZER
    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
        self.reviewCaseload = dependencies.makeReviewCaseload()
        self.dischargePatient = dependencies.makeDischargePatient()
    }

    //MARK: - COMPUTED PROPERTIES
    var patientsNeedingVisitCount: Int {
        entries.filter { $0.needsVisitBooked }.count
    }

    //MARK: - FUNCTIONS

    func loadCaseload() {
        do {
            entries = try reviewCaseload.execute()
        } catch {
            errorMessage = NurseFacingMessage.from(error)
        }
    }

    func entry(for patientID: UUID) -> CaseloadEntry? {
        entries.first { $0.id == patientID }
    }

    // Swipe action "Discharge" on a patient row
    func discharge(_ entry: CaseloadEntry) {
        do {
            try dischargePatient.execute(patientID: entry.patient.id)
        } catch {
            errorMessage = NurseFacingMessage.from(error)
        }
        loadCaseload()
    }
}
