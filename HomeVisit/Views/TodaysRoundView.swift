//  TodaysRoundView.swift
//  HomeVisit
//
//  Screen 1 – the nurse's day. Outstanding visits in driving order,
//  running-late warnings, and the visits already documented.

import SwiftUI

struct TodaysRoundView: View {

    //MARK: - PROPERTIES
    @ObservedObject var viewModel: TodaysRoundViewModel
    @State private var isShowingScheduleVisit = false

    //MARK: - BODY
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {

                // Main content: empty state OR the round
                Group {
                    if viewModel.hasNoVisitsToday {
                        ContentUnavailableView(
                            "No visits on today's round",
                            systemImage: "car",
                            description: Text("Tap + to add a home visit for a patient on your caseload.")
                        )
                    } else {
                        roundList
                    }
                } //: Group

                // Error banner – appears on top when a Use Case rejects an action
                if let message = viewModel.errorMessage {
                    ErrorBannerView(message: message) {
                        viewModel.errorMessage = nil
                    }
                }
            } //: ZStack
            .animation(.spring(), value: viewModel.errorMessage)
            .navigationTitle("Today's Round")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingScheduleVisit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add visit to round")
                }
            }
            .sheet(isPresented: $isShowingScheduleVisit, onDismiss: {
                viewModel.loadRound()
            }) {
                ScheduleVisitView(
                    viewModel: ScheduleVisitViewModel(dependencies: viewModel.dependencies)
                )
            }
            .onAppear {
                viewModel.loadRound()
            }
        } //: NavigationView
    }

    //MARK: - ROUND LIST
    private var roundList: some View {
        List {
            if let round = viewModel.round {
                Section {
                    RoundProgressView(round: round)
                }
            }

            Section(header: Text("Still to visit")) {
                if viewModel.outstandingVisits.isEmpty {
                    Label("Round complete – every visit is documented.", systemImage: "checkmark.seal.fill")
                        .foregroundColor(.green)
                }
                ForEach(viewModel.outstandingVisits) { visit in
                    NavigationLink(destination: VisitDetailView(
                        visit: visit,
                        dependencies: viewModel.dependencies,
                        onVisitChanged: { viewModel.loadRound() }
                    )) {
                        VisitCardView(visit: visit, isRunningLate: viewModel.isRunningLate(visit))
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            viewModel.cancelVisit(visit)
                        } label: {
                            Label("Cancel Visit", systemImage: "calendar.badge.minus")
                        }
                        .tint(.red)
                    }
                } //: ForEach
            } //: Section

            if !viewModel.closedVisits.isEmpty {
                Section(header: Text("Visited today")) {
                    ForEach(viewModel.closedVisits) { visit in
                        NavigationLink(destination: VisitDetailView(
                            visit: visit,
                            dependencies: viewModel.dependencies,
                            onVisitChanged: { viewModel.loadRound() }
                        )) {
                            VisitCardView(visit: visit)
                        }
                    } //: ForEach
                } //: Section
            }
        } //: List
        .listStyle(.insetGrouped)
        .refreshable {
            viewModel.loadRound()
        }
    }
}

//MARK: - PREVIEW
struct TodaysRoundView_Previews: PreviewProvider {
    static var previews: some View {
        TodaysRoundView(viewModel: TodaysRoundViewModel(dependencies: .preview))
    }
}
