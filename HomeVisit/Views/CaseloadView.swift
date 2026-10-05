//  CaseloadView.swift
//  HomeVisit
//
//  Screen 5 – every patient the nurse is responsible for.
//  Patients without a visit booked this week are flagged first.

import SwiftUI

struct CaseloadView: View {

    //MARK: - PROPERTIES
    @ObservedObject var viewModel: CaseloadViewModel
    @State private var isShowingAdmitPatient = false

    //MARK: - BODY
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Group {
                    if viewModel.entries.isEmpty {
                        ContentUnavailableView(
                            "No patients on your caseload",
                            systemImage: "person.2.slash",
                            description: Text("Tap + to admit a patient, or accept a GP referral from the Referrals tab.")
                        )
                    } else {
                        caseloadList
                    }
                } //: Group

                if let message = viewModel.errorMessage {
                    ErrorBannerView(message: message) {
                        viewModel.errorMessage = nil
                    }
                }
            } //: ZStack
            .animation(.spring(), value: viewModel.errorMessage)
            .navigationTitle("Caseload")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingAdmitPatient = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                    .accessibilityLabel("Admit patient to caseload")
                }
            }
            .sheet(isPresented: $isShowingAdmitPatient, onDismiss: {
                viewModel.loadCaseload()
            }) {
                AdmitPatientView(viewModel: AdmitPatientViewModel(dependencies: viewModel.dependencies))
            }
            .onAppear {
                viewModel.loadCaseload()
            }
        } //: NavigationView
    }

    //MARK: - CASELOAD LIST
    private var caseloadList: some View {
        List {
            // Continuity-of-care warning from ReviewCaseloadUseCase
            if viewModel.patientsNeedingVisitCount > 0 {
                Section {
                    Label(
                        "\(viewModel.patientsNeedingVisitCount) patient(s) have no visit booked in the next \(ReviewCaseloadUseCase.continuityOfCareWindowDays) days",
                        systemImage: "calendar.badge.exclamationmark"
                    )
                    .foregroundColor(.orange)
                }
            }

            Section(header: Text("Patients")) {
                ForEach(viewModel.entries) { entry in
                    NavigationLink(destination: PatientDetailView(viewModel: viewModel, patientID: entry.id)) {
                        PatientRowView(entry: entry)
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            viewModel.discharge(entry)
                        } label: {
                            Label("Discharge", systemImage: "person.fill.xmark")
                        }
                        .tint(.red)
                    }
                } //: ForEach
            } //: Section
        } //: List
        .listStyle(.insetGrouped)
        .refreshable {
            viewModel.loadCaseload()
        }
    }
}

// MARK: - PatientRowView
struct PatientRowView: View {

    //MARK: - PROPERTIES
    let entry: CaseloadEntry

    //MARK: - BODY
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.patient.fullName)
                    .font(.headline)
                if entry.patient.hasClinicalAlert {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .accessibilityLabel("Has clinical alert")
                }
            }

            Text(entry.patient.homeAddress)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let nextVisit = entry.nextScheduledVisit {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                    Text("Next visit")
                    Text(nextVisit.scheduledStart, style: .date)
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }

            if entry.needsVisitBooked {
                Label("Needs a visit booked", systemImage: "calendar.badge.exclamationmark")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
            }
        } //: VStack
        .padding(.vertical, 4)
    }
}

//MARK: - PREVIEW
struct CaseloadView_Previews: PreviewProvider {
    static var previews: some View {
        CaseloadView(viewModel: CaseloadViewModel(dependencies: .preview))
    }
}
