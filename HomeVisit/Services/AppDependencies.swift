//  AppDependencies.swift
//  HomeVisit
//
//  Builds the repository, the extension sync and every Use Case in one place.
//  ViewModels ask this object for Use Cases, so they never see Core Data.

import Foundation

final class AppDependencies {

    //MARK: - SHARED INSTANCES
    // Real Core Data store in the App Group container
    static let live = AppDependencies(persistenceController: .shared)

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

    //MARK: - INITIALIZERS
    convenience init(persistenceController: PersistenceController) {
        let repository = CoreDataCaseloadRepository(persistenceController: persistenceController)
        self.init(
            repository: repository,
            roundSync: WidgetAndReminderRoundSync(repository: repository),
            referralInbox: AppGroupReferralInbox()
        )
    }

    init(repository: CaseloadRepository, roundSync: RoundSyncing, referralInbox: ReferralInbox) {
        self.repository = repository
        self.roundSync = roundSync
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

    func makeCancelHomeVisit() -> CancelHomeVisitUseCase {
        CancelHomeVisitUseCase(repository: repository, roundSync: roundSync)
    }

    func makeAdmitPatientToCaseload() -> AdmitPatientToCaseloadUseCase {
        AdmitPatientToCaseloadUseCase(repository: repository, referralInbox: referralInbox)
    }

    func makeReviewCaseload() -> ReviewCaseloadUseCase {
        ReviewCaseloadUseCase(repository: repository)
    }

    func makeDischargePatient() -> DischargePatientUseCase {
        DischargePatientUseCase(repository: repository, roundSync: roundSync)
    }
}
