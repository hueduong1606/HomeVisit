//  ContentView.swift
//  HomeVisit
//
//  Three tabs that follow the nurse's working day:
//  Today's Round (drive and document) -> Caseload (plan) -> Referrals (new patients).

import SwiftUI

struct ContentView: View {

    //MARK: - PROPERTIES
    let dependencies: AppDependencies

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var roundViewModel: TodaysRoundViewModel
    @StateObject private var caseloadViewModel: CaseloadViewModel
    @StateObject private var referralInboxViewModel: ReferralInboxViewModel

    //MARK: - INITIALIZER
    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
        _roundViewModel = StateObject(wrappedValue: TodaysRoundViewModel(dependencies: dependencies))
        _caseloadViewModel = StateObject(wrappedValue: CaseloadViewModel(dependencies: dependencies))
        _referralInboxViewModel = StateObject(wrappedValue: ReferralInboxViewModel(dependencies: dependencies))
    }

    //MARK: - BODY
    var body: some View {
        TabView {
            TodaysRoundView(viewModel: roundViewModel)
                .tabItem {
                    Image(systemName: "car.fill")
                    Text("Today's Round")
                }

            CaseloadView(viewModel: caseloadViewModel)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Caseload")
                }

            ReferralInboxView(viewModel: referralInboxViewModel, onPatientAdmitted: {
                caseloadViewModel.loadCaseload()
            })
                .tabItem {
                    Image(systemName: "tray.and.arrow.down.fill")
                    Text("Referrals")
                }
                .badge(referralInboxViewModel.referrals.count)
        } //: TabView
        .task {
            // Ask once for permission to send visit reminders, then schedule them
            VisitReminderScheduler.requestPermission { granted in
                if granted {
                    dependencies.roundSync.roundDidChange()
                }
            }
            referralInboxViewModel.loadReferrals()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Coming back to the app: pick up new referrals and refresh the widget for today
            if newPhase == .active {
                dependencies.roundSync.roundDidChange()
                roundViewModel.loadRound()
                referralInboxViewModel.loadReferrals()
            }
        }
    }
}

//MARK: - PREVIEW
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(dependencies: .preview)
    }
}
