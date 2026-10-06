//  RecordOutcomeViewModel.swift
//  HomeVisit
//
//  Holds the outcome form while the nurse documents a visit.

import Foundation

class RecordOutcomeViewModel: ObservableObject {

    //MARK: - PROPERTIES
    @Published var outcome: VisitOutcome = .completed
    @Published var clinicalNote: String = ""
    @Published var errorMessage: String? = nil

    let visit: CareVisit
    private let recordVisitOutcome: RecordVisitOutcomeUseCase

    //MARK: - INITIALIZER
    init(visit: CareVisit, dependencies: AppDependencies = .live) {
        self.visit = visit
        self.recordVisitOutcome = dependencies.makeRecordVisitOutcome()
    }

    //MARK: - COMPUTED PROPERTIES
    // Live counter under the note, e.g. "4 / 10 characters"
    var noteCounter: String {
        let count = clinicalNote.trimmingCharacters(in: .whitespacesAndNewlines).count
        return "\(count) / \(RecordVisitOutcomeUseCase.minimumNoteLength) characters minimum"
    }

    //MARK: - FUNCTION

    // Returns the documented visit, or nil (with errorMessage set) if a business rule failed
    func saveOutcome() -> CareVisit? {
        do {
            let documentedVisit = try recordVisitOutcome.execute(visitID: visit.id, outcome: outcome, clinicalNote: clinicalNote)
            return documentedVisit
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
