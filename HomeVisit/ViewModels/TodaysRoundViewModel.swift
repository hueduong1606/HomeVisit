//  TodaysRoundViewModel.swift
//  HomeVisit
//

import Foundation

class TodaysRoundViewModel: ObservableObject {

    //MPROPERTIES
    // Published properties trigger a SwiftUI redraw whenever they change
    @Published var round: TodaysRound? = nil
    @Published var errorMessage: String? = nil

    let dependencies: AppDependencies
    private let planTodaysRound: PlanTodaysRoundUseCase

    // INITIALIZER
    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
        self.planTodaysRound = dependencies.makePlanTodaysRound()
    }

   
    var outstandingVisits: [CareVisit] {
        round?.outstandingVisits ?? []
    }

    var closedVisits: [CareVisit] {
        round?.closedVisits ?? []
    }

    var comingUpVisits: [CareVisit] {
        round?.comingUpVisits ?? []
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

    //FUNCTIONS

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
