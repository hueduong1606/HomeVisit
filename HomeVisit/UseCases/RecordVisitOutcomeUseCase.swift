//  RecordVisitOutcomeUseCase.swift
//  HomeVisit
//
//  Business operation: document what happened at the patient's home –
//  care completed (with a clinical note) or no access (with a reason).

import Foundation

// MARK: - RecordVisitOutcomeError
enum RecordVisitOutcomeError: LocalizedError, Equatable {
    case visitNoLongerOnRound
    case outcomeAlreadyRecorded(VisitStatus)
    case visitHasNotStarted(startTime: Date)
    case clinicalNoteTooShort(minimumCharacters: Int)
    case outcomeCouldNotBeSaved

    // What went wrong – in the nurse's words
    var errorDescription: String? {
        switch self {
        case .visitNoLongerOnRound:
            return "This visit is no longer on your round."
        case .outcomeAlreadyRecorded(let status):
            return "This visit is already documented as \"\(status.rawValue)\"."
        case .visitHasNotStarted(let startTime):
            return "This visit isn't due until \(startTime.formatted(date: .omitted, time: .shortened))."
        case .clinicalNoteTooShort(let minimumCharacters):
            return "The note needs at least \(minimumCharacters) characters to be part of the clinical record."
        case .outcomeCouldNotBeSaved:
            return "The visit outcome couldn't be saved."
        }
    }

    // What the nurse can do next
    var recoverySuggestion: String? {
        switch self {
        case .visitNoLongerOnRound:
            return "Go back to Today's Round to see your current visits."
        case .outcomeAlreadyRecorded:
            return "Documented visits can't be changed here. Add any late entry in the patient's main record."
        case .visitHasNotStarted:
            return "Record the outcome once you have arrived at the home."
        case .clinicalNoteTooShort:
            return "Describe the care given, or why you could not get in, before saving."
        case .outcomeCouldNotBeSaved:
            return "Your note is still on screen. Try saving again in a moment."
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
    // Business rule: a nurse who arrives early may document up to 30 minutes before the booked time
    static let earlyArrivalAllowanceMinutes = 30

    //MARK: - FUNCTION
    func execute(
        visitID: UUID,
        outcome: VisitOutcome,
        clinicalNote: String,
        now: Date = Date()
    ) throws(RecordVisitOutcomeError) -> CareVisit {

        let foundVisit: CareVisit?
        do {
            foundVisit = try repository.findVisit(id: visitID)
        } catch {
            throw RecordVisitOutcomeError.outcomeCouldNotBeSaved
        }
        guard var visit = foundVisit else {
            throw RecordVisitOutcomeError.visitNoLongerOnRound
        }

        // Rule 1: an outcome is recorded once – the clinical record is not overwritten
        guard visit.status == .scheduled else {
            throw RecordVisitOutcomeError.outcomeAlreadyRecorded(visit.status)
        }

        // Rule 2: the nurse cannot document a visit that has not started yet
        let earliestDocumentationTime = visit.scheduledStart.addingTimeInterval(
            TimeInterval(-RecordVisitOutcomeUseCase.earlyArrivalAllowanceMinutes * 60)
        )
        guard now >= earliestDocumentationTime else {
            throw RecordVisitOutcomeError.visitHasNotStarted(startTime: visit.scheduledStart)
        }

        // Rule 3: the clinical note must be meaningful
        let trimmedNote = clinicalNote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedNote.count >= RecordVisitOutcomeUseCase.minimumNoteLength else {
            throw RecordVisitOutcomeError.clinicalNoteTooShort(minimumCharacters: RecordVisitOutcomeUseCase.minimumNoteLength)
        }

        visit.status = outcome.resultingStatus
        visit.outcomeNote = trimmedNote
        visit.outcomeRecordedAt = now

        do {
            try repository.saveVisit(visit)
        } catch {
            throw RecordVisitOutcomeError.outcomeCouldNotBeSaved
        }

        // The widget moves on to the next patient and this visit's reminder is removed
        roundSync.roundDidChange()
        return visit
    }
}
