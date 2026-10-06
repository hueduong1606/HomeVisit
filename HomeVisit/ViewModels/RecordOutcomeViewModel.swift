//  RecordOutcomeViewModel.swift
//  HomeVisit
//


import Foundation

class RecordOutcomeViewModel: ObservableObject {

    //PROPERTIES
    @Published var outcome: VisitOutcome = .completed
    @Published var clinicalNote: String = ""
    @Published var errorMessage: String? = nil

    let visit: CareVisit
    private let recordVisitOutcome: RecordVisitOutcomeUseCase

    //INITIALIZER
    init(visit: CareVisit, dependencies: AppDependencies = .live) {
        self.visit = visit
        self.recordVisitOutcome = dependencies.makeRecordVisitOutcome()
    }

    
    // Live counter under the note
    var noteCounter: String {
        let count = clinicalNote.trimmingCharacters(in: .whitespacesAndNewlines).count
        return "\(count) / \(RecordVisitOutcomeUseCase.minimumNoteLength) characters minimum"
    }

    //FUNCTION

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
