//  PatientDetailView.swift
//  HomeVisit
//
//  Screen 6 – one patient's record: contact, safety alert, referral reason,
//  upcoming visits and documented visit history.

import SwiftUI

struct PatientDetailView: View {

    //MARK: - PROPERTIES
    @ObservedObject var viewModel: CaseloadViewModel
    let patientID: UUID
    @State private var isShowingScheduleVisit = false

    // Always read the latest entry so the screen updates after booking a visit
    var entry: CaseloadEntry? {
        viewModel.entry(for: patientID)
    }

    //MARK: - BODY
    var body: some View {
        Group {
            if let entry = entry {
                patientRecord(for: entry)
            } else {
                ContentUnavailableView(
                    "Patient discharged",
                    systemImage: "person.fill.checkmark",
                    description: Text("This patient is no longer on your caseload.")
                )
            }
        } //: Group
        .navigationTitle("Patient")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingScheduleVisit, onDismiss: {
            viewModel.loadCaseload()
        }) {
            ScheduleVisitView(
                viewModel: ScheduleVisitViewModel(preselectedPatientID: patientID, dependencies: viewModel.dependencies)
            )
        }
    }

    //MARK: - PATIENT RECORD
    private func patientRecord(for entry: CaseloadEntry) -> some View {
        List {
            // Identity and contact
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.patient.fullName)
                        .font(.title2)
                        .fontWeight(.bold)
                    Label(entry.patient.homeAddress, systemImage: "house.fill")
                    if !entry.patient.contactNumber.isEmpty {
                        Label(entry.patient.contactNumber, systemImage: "phone.fill")
                    }
                    Text("On caseload since \(entry.patient.admittedOn.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } //: VStack
                .padding(.vertical, 4)
            }

            if entry.patient.hasClinicalAlert {
                Section(header: Text("Clinical alert")) {
                    Label(entry.patient.clinicalAlert, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
            }

            if !entry.patient.referralNote.isEmpty {
                Section(header: Text("Reason for referral")) {
                    Text(entry.patient.referralNote)
                        .font(.subheadline)
                }
            }

            // Upcoming visits
            Section(header: Text("Booked visits")) {
                if entry.needsVisitBooked {
                    Label("No visit booked in the next \(ReviewCaseloadUseCase.continuityOfCareWindowDays) days", systemImage: "calendar.badge.exclamationmark")
                        .foregroundColor(.orange)
                }
                ForEach(entry.outstandingVisits) { visit in
                    NavigationLink(destination: VisitDetailView(
                        visit: visit,
                        dependencies: viewModel.dependencies,
                        onVisitChanged: { viewModel.loadCaseload() }
                    )) {
                        VisitCardView(visit: visit)
                    }
                }
                Button {
                    isShowingScheduleVisit = true
                } label: {
                    Label("Book a Visit", systemImage: "calendar.badge.plus")
                }
            }

            // Documented history
            Section(header: Text("Visit history")) {
                if entry.visitHistory.isEmpty {
                    Text("No documented visits yet.")
                        .foregroundColor(.secondary)
                }
                ForEach(entry.visitHistory) { visit in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label(visit.status.rawValue, systemImage: visit.status.symbolName)
                                .font(.subheadline.bold())
                                .foregroundColor(visit.status == .completed ? Color.green : Color.orange)
                            Spacer()
                            Text(visit.scheduledStart, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(visit.careType.rawValue)
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        Text(visit.outcomeNote)
                            .font(.subheadline)
                    } //: VStack
                    .padding(.vertical, 2)
                }
            }
        } //: List
        .listStyle(.insetGrouped)
    }
}

//MARK: - PREVIEW
struct PatientDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CaseloadViewModel(dependencies: .preview)
        viewModel.loadCaseload()
        return NavigationView {
            PatientDetailView(viewModel: viewModel, patientID: viewModel.entries.first?.id ?? UUID())
        }
    }
}
