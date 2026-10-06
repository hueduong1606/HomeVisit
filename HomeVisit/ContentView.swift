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
            VisitReminderScheduler.requestPermission()  // Ask once for permission to send visit reminders
            dependencies.roundSync.roundDidChange()      // Give the widget today's round as soon as the app opens
        }
    }
}

//MARK: - PREVIEW
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(dependencies: .preview)
    }
}
