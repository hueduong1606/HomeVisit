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
    var noteCharacterCount: Int {
        clinicalNote.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    var minimumNoteLength: Int {
        RecordVisitOutcomeUseCase.minimumNoteLength
    }

    // Live guidance under the note field
    var noteGuidance: String {
        if noteCharacterCount >= minimumNoteLength {
            return "Ready to save to the clinical record."
        }
        return "\(minimumNoteLength - noteCharacterCount) more characters needed."
    }

    //MARK: - FUNCTION

    // Returns the documented visit, or nil (with errorMessage set) if a business rule failed
    func saveOutcome() -> CareVisit? {
        do {
            let documentedVisit = try recordVisitOutcome.execute(
                visitID: visit.id,
                outcome: outcome,
                clinicalNote: clinicalNote
            )
            errorMessage = nil
            return documentedVisit
        } catch {
            errorMessage = NurseFacingMessage.from(error)
            return nil
        }
    }
}
