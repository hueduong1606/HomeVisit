//  CancelHomeVisitUseCase.swift
//  HomeVisit
//
//  Business operation: take a booked visit off the round (e.g. booked by mistake,
//  or the patient phoned to reschedule).

import Foundation

// MARK: - CancelHomeVisitError
enum CancelHomeVisitError: LocalizedError, Equatable {
    case visitNoLongerOnRound
    case visitAlreadyDocumented
    case roundCouldNotBeUpdated

    var errorDescription: String? {
        switch self {
        case .visitNoLongerOnRound:
            return "This visit has already been removed from your round."
        case .visitAlreadyDocumented:
            return "This visit is already documented, so it is part of the clinical record."
        case .roundCouldNotBeUpdated:
            return "The visit couldn't be removed from your round."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .visitNoLongerOnRound:
            return "Pull down to refresh Today's Round."
        case .visitAlreadyDocumented:
            return "Documented visits can't be cancelled. Book a new visit if the patient needs to be seen again."
        case .roundCouldNotBeUpdated:
            return "Nothing was changed. Try again in a moment."
        }
    }
}

// MARK: - CancelHomeVisitUseCase
struct CancelHomeVisitUseCase {

    //MARK: - PROPERTIES
    let repository: CaseloadRepository
    let roundSync: RoundSyncing

    //MARK: - FUNCTION
    func execute(visitID: UUID) throws(CancelHomeVisitError) {
        let foundVisit: CareVisit?
        do {
            foundVisit = try repository.findVisit(id: visitID)
        } catch {
            throw CancelHomeVisitError.roundCouldNotBeUpdated
        }
        guard let visit = foundVisit else {
            throw CancelHomeVisitError.visitNoLongerOnRound
        }

        // Business rule: completed and no-access visits are part of the clinical record
        guard visit.status == .scheduled else {
            throw CancelHomeVisitError.visitAlreadyDocumented
        }

        do {
            try repository.deleteVisit(id: visitID)
        } catch {
            throw CancelHomeVisitError.roundCouldNotBeUpdated
        }

        roundSync.roundDidChange()
    }
}
