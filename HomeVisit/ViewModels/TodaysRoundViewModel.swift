//  TodaysRoundViewModel.swift
//  HomeVisit
//
//  Single source of truth for the Today's Round screen.
//  Talks only to Use Cases – never to Core Data.

import Foundation

class TodaysRoundViewModel: ObservableObject {

    //MARK: - PROPERTIES
    // Published properties trigger a SwiftUI redraw whenever they change
    @Published var round: TodaysRound? = nil
    @Published var errorMessage: String? = nil

    let dependencies: AppDependencies
    private let planTodaysRound: PlanTodaysRoundUseCase
    private let cancelHomeVisit: CancelHomeVisitUseCase

    //MARK: - INITIALIZER
    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
        self.planTodaysRound = dependencies.makePlanTodaysRound()
        self.cancelHomeVisit = dependencies.makeCancelHomeVisit()
    }

    //MARK: - COMPUTED PROPERTIES
    var outstandingVisits: [CareVisit] {
        round?.outstandingVisits ?? []
    }

    var closedVisits: [CareVisit] {
        round?.closedVisits ?? []
    }

    var hasNoVisitsToday: Bool {
        (round?.totalVisitCount ?? 0) == 0
    }

    var runningLateCount: Int {
        round?.runningLateVisitIDs.count ?? 0
    }

    //MARK: - FUNCTIONS

    // Loads today's visits through PlanTodaysRoundUseCase
    func loadRound() {
        do {
            round = try planTodaysRound.execute()
        } catch {
            errorMessage = NurseFacingMessage.from(error)
        }
    }

    func isRunningLate(_ visit: CareVisit) -> Bool {
        round?.isRunningLate(visit) ?? false
    }

    // Swipe action "Cancel Visit" on an outstanding visit
    func cancelVisit(_ visit: CareVisit) {
        do {
            try cancelHomeVisit.execute(visitID: visit.id)
        } catch {
            errorMessage = NurseFacingMessage.from(error)
        }
        loadRound() // Refresh so the list matches the round
    }
}
