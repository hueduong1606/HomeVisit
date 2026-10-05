//  ScheduleVisitView.swift
//  HomeVisit
//
//  Screen 4 – add a home visit to the round.
//  Business rules (no clashes, safe duration, daily limit) live in ScheduleHomeVisitUseCase.

import SwiftUI

struct ScheduleVisitView: View {

    //MARK: - PROPERTIES
    @StateObject var viewModel: ScheduleVisitViewModel
    var onVisitScheduled: () -> Void

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    //MARK: - INITIALIZER
    init(viewModel: ScheduleVisitViewModel, onVisitScheduled: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onVisitScheduled = onVisitScheduled
    }

    //MARK: - BODY
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Form {
                    // Patient
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

                    // Safety alert for the chosen patient
                    if let patient = viewModel.selectedPatient, patient.hasClinicalAlert {
                        Section(header: Text("Clinical alert")) {
                            Label(patient.clinicalAlert, systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                    }

                    // Care, time and duration
                    Section(header: Text("Visit")) {
                        Picker("Care type", selection: $viewModel.careType) {
                            ForEach(CareType.allCases) { careType in
                                Label(careType.rawValue, systemImage: careType.symbolName).tag(careType)
                            }
                        }

                        DatePicker(
                            "Visit time",
                            selection: $viewModel.scheduledStart,
                            in: Calendar.current.startOfDay(for: Date())...,
                            displayedComponents: [.date, .hourAndMinute]
                        )

                        Stepper(
                            "Duration: \(viewModel.durationMinutes) min",
                            value: $viewModel.durationMinutes,
                            in: viewModel.safeDurationRange,
                            step: 5
                        )
                    }
                } //: Form

                if let message = viewModel.errorMessage {
                    ErrorBannerView(message: message) {
                        viewModel.errorMessage = nil
                    }
                }
            } //: ZStack
            .animation(.spring(), value: viewModel.errorMessage)
            .navigationTitle("Add Visit to Round")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add to Round") {
                        if viewModel.addVisitToRound() {
                            onVisitScheduled()
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .disabled(!viewModel.canAddToRound)
                }
            }
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
