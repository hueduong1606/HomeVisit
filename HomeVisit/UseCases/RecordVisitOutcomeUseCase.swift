//  RecordVisitOutcomeUseCase.swift
//  HomeVisit
//
//  Business operation: document what happened at the patient's home –
//  care completed (with a clinical note) or no access (with a reason).

import Foundation

// MARK: - RecordVisitOutcomeError
enum RecordVisitOutcomeError: LocalizedError, Equatable {
    case visitNoLongerOnRound
    case outcomeAlreadyRecorded
    case clinicalNoteTooShort(minimumCharacters: Int)
    case outcomeCouldNotBeSaved

    // What went wrong + what the nurse can do next
    var errorDescription: String? {
        switch self {
        case .visitNoLongerOnRound:
            return "This visit is no longer on your round. Go back to Today's Round to see your current visits."
        case .outcomeAlreadyRecorded:
            return "This visit is already documented, so it can't be changed here. Add any late entry to the patient's main clinical record."
        case .clinicalNoteTooShort(let minimumCharacters):
            return "The note needs at least \(minimumCharacters) characters. Describe the care given, or why you could not get in, before saving."
        case .outcomeCouldNotBeSaved:
            return "The visit outcome couldn't be saved. Your note is still on screen – please try saving again."
        }
    }
}

// MARK: - RecordVisitOutcomeUseCase
struct RecordVisitOutcomeUseCase {

    //MARK: - PROPERTIES
    let repository: CaseloadRepository
    let roundSync: RoundSyncing

    // Business rule: every documented visit needs a meaningful note
    static let minimumNoteLength = 10

    //MARK: - FUNCTION
    func execute(visitID: UUID, outcome: VisitOutcome, clinicalNote: String) throws(RecordVisitOutcomeError) -> CareVisit {

        let foundVisit: CareVisit?
        do {
            foundVisit = try repository.findVisit(id: visitID)
        } catch {
            throw RecordVisitOutcomeError.outcomeCouldNotBeSaved
        }
        guard var visit = foundVisit else {
            throw RecordVisitOutcomeError.visitNoLongerOnRound
        }

        // Rule 1: an outcome is recorded once – the clinical record is never overwritten
        guard visit.status == .scheduled else {
            throw RecordVisitOutcomeError.outcomeAlreadyRecorded
        }

        // Rule 2: the clinical note must be meaningful
        let trimmedNote = clinicalNote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedNote.count >= RecordVisitOutcomeUseCase.minimumNoteLength else {
            throw RecordVisitOutcomeError.clinicalNoteTooShort(minimumCharacters: RecordVisitOutcomeUseCase.minimumNoteLength)
        }

        visit.status = outcome.resultingStatus
        visit.outcomeNote = trimmedNote

        do {
            try repository.saveVisit(visit)
        } catch {
            throw RecordVisitOutcomeError.outcomeCouldNotBeSaved
        }

        // The widget moves on to the next patient
        roundSync.roundDidChange()
        return visit
    }
}
