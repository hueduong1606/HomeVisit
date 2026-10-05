//  RecordOutcomeView.swift
//  HomeVisit
//
//  Screen 3 – document the visit at the door: care completed (clinical note)
//  or no access (reason). Business rules live in RecordVisitOutcomeUseCase.

import SwiftUI

struct RecordOutcomeView: View {

    //MARK: - PROPERTIES
    @StateObject var viewModel: RecordOutcomeViewModel
    var onOutcomeSaved: (CareVisit) -> Void

    // Used to dismiss the sheet programmatically
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    //MARK: - INITIALIZER
    init(viewModel: RecordOutcomeViewModel, onOutcomeSaved: @escaping (CareVisit) -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onOutcomeSaved = onOutcomeSaved
    }

    //MARK: - BODY
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Form {
                    // Which visit is being documented
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.visit.patientName)
                                .font(.headline)
                            Text("\(viewModel.visit.careType.rawValue) · \(viewModel.visit.scheduledStart.formatted(date: .omitted, time: .shortened))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Outcome picker
                    Section(header: Text("Outcome")) {
                        Picker("Outcome", selection: $viewModel.outcome) {
                            ForEach(VisitOutcome.allCases) { outcome in
                                Text(outcome.rawValue).tag(outcome)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Clinical note
                    Section(
                        header: Text(viewModel.outcome.notePrompt),
                        footer: Text(viewModel.noteGuidance)
                    ) {
                        TextEditor(text: $viewModel.clinicalNote)
                            .frame(minHeight: 160)
                    }
                } //: Form

                if let message = viewModel.errorMessage {
                    ErrorBannerView(message: message) {
                        viewModel.errorMessage = nil
                    }
                }
            } //: ZStack
            .animation(.spring(), value: viewModel.errorMessage)
            .navigationTitle("Record Visit Outcome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Outcome") {
                        if let documentedVisit = viewModel.saveOutcome() {
                            onOutcomeSaved(documentedVisit)
                            presentationMode.wrappedValue.dismiss() // Dismiss the sheet
                        }
                    }
                }
            }
        } //: NavigationView
    }
}

//MARK: - PREVIEW
struct RecordOutcomeView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleVisit = CareVisit(
            patientID: UUID(),
            patientName: "Arthur Nguyen",
            homeAddress: "3/7 Banksia Road, Granville NSW 2142",
            careType: .medicationReview,
            scheduledStart: Date(),
            durationMinutes: 30
        )
        RecordOutcomeView(
            viewModel: RecordOutcomeViewModel(visit: sampleVisit, dependencies: .preview),
            onOutcomeSaved: { _ in }
        )
    }
}
