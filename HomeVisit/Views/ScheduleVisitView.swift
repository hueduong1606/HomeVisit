//  ScheduleVisitView.swift
//  HomeVisit
//
//  Screen 4 – add a home visit to the round.
//  The rules (no clashes, safe duration, not in the past) live in ScheduleHomeVisitUseCase.

import SwiftUI

struct ScheduleVisitView: View {

    //MARK: - PROPERTIES
    @StateObject var viewModel: ScheduleVisitViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    //MARK: - INITIALIZER
    init(viewModel: ScheduleVisitViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    //MARK: - BODY
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Form {
                    Section(header: Text("Patient")) {
                        if viewModel.patients.isEmpty {
                            Text("No patients on your caseload yet. Admit a patient from the Caseload tab first.")
                                .foregroundColor(.secondary)
                        } else {
                            Picker("Patient", selection: $viewModel.selectedPatientID) {
                                Text("Choose a patient").tag(UUID?.none)
                                ForEach(viewModel.patients) { patient in
                                    Text(patient.fullName).tag(UUID?.some(patient.id))
                                }
                            }
                        }
                    }

                    Section(header: Text("Visit")) {
                        Picker("Care type", selection: $viewModel.careType) {
                            ForEach(CareType.allCases) { careType in
                                Text(careType.rawValue).tag(careType)
                            }
                        }
                        DatePicker("Visit time", selection: $viewModel.scheduledStart)
                        Stepper("Duration: \(viewModel.durationMinutes) min", value: $viewModel.durationMinutes, in: 5...240, step: 5)
                    }

                    Button("Add to Round") {
                        if viewModel.addVisitToRound() {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                } //: Form

                if let message = viewModel.errorMessage {
                    ErrorBannerView(message: message) {
                        viewModel.errorMessage = nil
                    }
                }
            } //: ZStack
            .navigationTitle("Add Visit to Round")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                viewModel.loadPatients()
            }
        } //: NavigationView
    }
}

//MARK: - PREVIEW
struct ScheduleVisitView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleVisitView(viewModel: ScheduleVisitViewModel(dependencies: .preview))
    }
}
