//  ContentView.swift
//  HomeVisit
//
//  Tabs that follow the nurse's working day. Caseload and Referrals tabs follow.

import SwiftUI

struct ContentView: View {

    //MARK: - PROPERTIES
    let dependencies: AppDependencies

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var roundViewModel: TodaysRoundViewModel

    //MARK: - INITIALIZER
    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
        _roundViewModel = StateObject(wrappedValue: TodaysRoundViewModel(dependencies: dependencies))
    }

    //MARK: - BODY
    var body: some View {
        TabView {
            TodaysRoundView(viewModel: roundViewModel)
                .tabItem {
                    Image(systemName: "car.fill")
                    Text("Today's Round")
                }
        } //: TabView
        .task {
            // Ask once for permission to send visit reminders, then schedule them
            VisitReminderScheduler.requestPermission { granted in
                if granted {
                    dependencies.roundSync.roundDidChange()
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                dependencies.roundSync.roundDidChange()
                roundViewModel.loadRound()
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
