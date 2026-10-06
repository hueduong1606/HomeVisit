//  TodaysRoundView.swift
//  HomeVisit
//
//  Screen 1 – the nurse's day: visits still to do in driving order,
//  outcome-overdue warnings, and the visits already documented.

import SwiftUI

struct TodaysRoundView: View {

    //MARK: - PROPERTIES
    @ObservedObject var viewModel: TodaysRoundViewModel
    @State private var showScheduleVisitView = false

    //MARK: - BODY
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                List {
                    // Progress
                    Section {
                        Text(viewModel.progressSummary)
                            .font(.headline)
                    }

                    // Still to visit
                    Section(header: Text("Still to visit")) {
                        if viewModel.outstandingVisits.isEmpty {
                            Text(viewModel.emptyRoundMessage)
                                .foregroundColor(.secondary)
                        }
                        ForEach(viewModel.outstandingVisits) { visit in
                            NavigationLink(destination: VisitDetailView(visit: visit, dependencies: viewModel.dependencies, onVisitChanged: {
                                viewModel.loadRound()
                            })) {
                                VisitCardView(visit: visit, isOutcomeOverdue: viewModel.isOutcomeOverdue(visit))
                            }
                        } //: ForEach
                    } //: Section

                    // Already documented
                    if !viewModel.closedVisits.isEmpty {
                        Section(header: Text("Visited today")) {
                            ForEach(viewModel.closedVisits) { visit in
                                NavigationLink(destination: VisitDetailView(visit: visit, dependencies: viewModel.dependencies)) {
                                    VisitCardView(visit: visit)
                                }
                            } //: ForEach
                        } //: Section
                    }
                } //: List

                // Error banner – appears on top when a Use Case rejects an action
                if let message = viewModel.errorMessage {
                    ErrorBannerView(message: message) {
                        viewModel.errorMessage = nil
                    }
                }
            } //: ZStack
            .navigationTitle("Today's Round")
            .navigationBarItems(trailing: Button(action: {
                showScheduleVisitView = true
            }) {
                Image(systemName: "plus")  // SF Symbols plus icon
            })
            .sheet(isPresented: $showScheduleVisitView, onDismiss: {
                viewModel.loadRound()
            }) {
                ScheduleVisitView(viewModel: ScheduleVisitViewModel(dependencies: viewModel.dependencies))
            }
            .onAppear {
                viewModel.loadRound()
            }
        } //: NavigationView
    }
}

//MARK: - PREVIEW
struct TodaysRoundView_Previews: PreviewProvider {
    static var previews: some View {
        TodaysRoundView(viewModel: TodaysRoundViewModel(dependencies: .preview))
    }
}
