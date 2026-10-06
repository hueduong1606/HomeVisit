//  ContentView.swift
//  HomeVisit
//
//  Two tabs that follow the nurse's working day:
//  Today's Round (drive and document) and Caseload (referrals and patients).

import SwiftUI

struct ContentView: View {

    //MARK: - PROPERTIES
    @StateObject var roundViewModel: TodaysRoundViewModel
    @StateObject var caseloadViewModel: CaseloadViewModel
    let dependencies: AppDependencies

    // Tells us when the nurse comes back to the app (e.g. after sharing a referral)
    @Environment(\.scenePhase) var scenePhase

    //MARK: - INITIALIZER
    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
        _roundViewModel = StateObject(wrappedValue: TodaysRoundViewModel(dependencies: dependencies))
        _caseloadViewModel = StateObject(wrappedValue: CaseloadViewModel(dependencies: dependencies))
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
        } //: TabView
        .onAppear {
            // Ask once for permission to send visit reminders, and explain if they are off
            VisitReminderScheduler.requestPermission { message in
                if let message = message {
                    roundViewModel.errorMessage = message
                }
                dependencies.roundSync.roundDidChange()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Back in the app: refresh the round, the caseload, new referrals and the widget
            if newPhase == .active {
                roundViewModel.loadRound()
                caseloadViewModel.loadCaseload()
                dependencies.roundSync.roundDidChange()
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
