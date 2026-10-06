//  AppDependencies.swift
//  HomeVisit
//
//  Creates the repository, the extension sync and the referral inbox in one place.
//  ViewModels get their Use Cases from here, so they never see Core Data.

import Foundation

class AppDependencies {

    //MARK: - SHARED INSTANCES
    // Real Core Data store in the App Group container
    static let live = AppDependencies(
        repository: CoreDataCaseloadRepository(persistenceController: .shared),
        roundSync: nil,
        referralInbox: AppGroupReferralInbox()
    )

    // In-memory store with sample data, used by SwiftUI previews
    static let preview = AppDependencies(
        repository: CoreDataCaseloadRepository(persistenceController: .preview),
        roundSync: PreviewRoundSync(),
        referralInbox: PreviewReferralInbox()
    )

    //MARK: - PROPERTIES
    let repository: CaseloadRepository
    let roundSync: RoundSyncing
    let referralInbox: ReferralInbox

    //MARK: - INITIALIZER
    // When no roundSync is given, the real widget + reminder sync is used
    init(repository: CaseloadRepository, roundSync: RoundSyncing?, referralInbox: ReferralInbox) {
        self.repository = repository
        self.roundSync = roundSync ?? WidgetAndReminderRoundSync(repository: repository)
        self.referralInbox = referralInbox
    }

    //MARK: - USE CASES
    func makePlanTodaysRound() -> PlanTodaysRoundUseCase {
        PlanTodaysRoundUseCase(repository: repository)
    }

    func makeScheduleHomeVisit() -> ScheduleHomeVisitUseCase {
        ScheduleHomeVisitUseCase(repository: repository, roundSync: roundSync)
    }

    func makeRecordVisitOutcome() -> RecordVisitOutcomeUseCase {
        RecordVisitOutcomeUseCase(repository: repository, roundSync: roundSync)
    }

    func makeAdmitPatientToCaseload() -> AdmitPatientToCaseloadUseCase {
        AdmitPatientToCaseloadUseCase(repository: repository, referralInbox: referralInbox)
    }
}
