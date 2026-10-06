//  TodaysRoundView.swift
//  HomeVisit
//


import SwiftUI

struct TodaysRoundView: View {

    //PROPERTIES
    @ObservedObject var viewModel: TodaysRoundViewModel
    @State private var showScheduleVisitView = false

    // BODY
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

                    // Planned ahead – booked for the coming days
                    if !viewModel.comingUpVisits.isEmpty {
                        Section(header: Text("Coming up")) {
                            ForEach(viewModel.comingUpVisits) { visit in
                                NavigationLink(destination: VisitDetailView(visit: visit, dependencies: viewModel.dependencies)) {
                                    VStack(alignment: .leading) {
                                        Text(visit.scheduledStart, style: .date)
                                            .font(.caption)
                                            .bold()
                                            .foregroundColor(.secondary)
                                        VisitCardView(visit: visit)
                                    }
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

// PREVIEW
struct TodaysRoundView_Previews: PreviewProvider {
    static var previews: some View {
        TodaysRoundView(viewModel: TodaysRoundViewModel(dependencies: .preview))
    }
}
