//  RecordOutcomeView.swift
//  HomeVisit
//
//  Screen 3 – document the visit at the door: care completed (clinical note)
//  or no access (reason). The rules live in RecordVisitOutcomeUseCase.

import SwiftUI

struct RecordOutcomeView: View {

    //MARK: - PROPERTIES
    @StateObject var viewModel: RecordOutcomeViewModel
    var onOutcomeSaved: (CareVisit) -> Void

    // A binding to the presentation mode, used to dismiss the sheet
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
                    Section(header: Text("Patient")) {
                        Text(viewModel.visit.patientName)
                            .font(.headline)
                    }

                    Section(header: Text("Outcome")) {
                        Picker("Outcome", selection: $viewModel.outcome) {
                            ForEach(VisitOutcome.allCases) { outcome in
                                Text(outcome.rawValue).tag(outcome)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section(header: Text("Clinical note"), footer: Text(viewModel.noteCounter)) {
                        TextEditor(text: $viewModel.clinicalNote)
                            .frame(minHeight: 150)
                    }

                    Button("Save Outcome") {
                        if let documentedVisit = viewModel.saveOutcome() {
                            onOutcomeSaved(documentedVisit)
                            presentationMode.wrappedValue.dismiss() // Dismiss the sheet
                        }
                    }
                } //: Form

                if let message = viewModel.errorMessage {
                    ErrorBannerView(message: message) {
                        viewModel.errorMessage = nil
                    }
                }
            } //: ZStack
            .navigationTitle("Record Visit Outcome")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        } //: NavigationView
    }
}

//MARK: - PREVIEW
struct RecordOutcomeView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleVisit = CareVisit(
            patientID: UUID(),
            patientName: "Margaret Thompson",
            homeAddress: "14 Wattle Street, Parramatta NSW 2150",
            careType: .woundCare,
            scheduledStart: Date(),
            durationMinutes: 45
        )
        RecordOutcomeView(viewModel: RecordOutcomeViewModel(visit: sampleVisit, dependencies: .preview), onOutcomeSaved: { _ in })
    }
}
