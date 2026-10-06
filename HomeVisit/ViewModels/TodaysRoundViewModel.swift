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

    //MARK: - INITIALIZER
    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
        self.planTodaysRound = dependencies.makePlanTodaysRound()
    }

    //MARK: - COMPUTED PROPERTIES
    var outstandingVisits: [CareVisit] {
        round?.outstandingVisits ?? []
    }

    var closedVisits: [CareVisit] {
        round?.closedVisits ?? []
    }

    var progressSummary: String {
        round?.progressSummary ?? ""
    }

    // Empty-state message in the nurse's words
    var emptyRoundMessage: String {
        if closedVisits.isEmpty {
            return "No visits on today's round yet. Tap + to add a home visit."
        }
        return "Round complete – every visit today is documented."
    }

    //MARK: - FUNCTIONS

    // Loads today's visits through PlanTodaysRoundUseCase
    func loadRound() {
        do {
            round = try planTodaysRound.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isOutcomeOverdue(_ visit: CareVisit) -> Bool {
        round?.isOutcomeOverdue(visit) ?? false
    }
}
