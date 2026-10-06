//  VisitDetailView.swift
//  HomeVisit
//
//  Screen 2 – what the nurse needs at the door: who, where, the care needed,
//  the safety alert, and the visit outcome.

import SwiftUI

struct VisitDetailView: View {

    //MARK: - PROPERTIES
    @State var visit: CareVisit
    let dependencies: AppDependencies
    var onVisitChanged: () -> Void

    @State private var showRecordOutcomeView = false
    @State private var reminderMessage: String = ""

    //MARK: - INITIALIZER
    init(visit: CareVisit, dependencies: AppDependencies, onVisitChanged: @escaping () -> Void = {}) {
        _visit = State(initialValue: visit)
        self.dependencies = dependencies
        self.onVisitChanged = onVisitChanged
    }

    //MARK: - BODY
    var body: some View {
        List {
            // Who and why
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(visit.patientName)
                        .font(.title2)
                        .bold()
                    Label(visit.careType.rawValue, systemImage: visit.careType.symbolName)
                        .foregroundColor(.accentColor)
                    Text("\(visit.scheduledStart.formatted(date: .abbreviated, time: .shortened)) · \(visit.durationMinutes) min")
                        .foregroundColor(.secondary)
                }
            }

            // Safety first – shown above the address on purpose
            if visit.hasClinicalAlert {
                Section(header: Text("Clinical alert")) {
                    Label(visit.clinicalAlert, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
            }

            // Where to go
            Section(header: Text("Home address")) {
                Label(visit.homeAddress, systemImage: "house.fill")
            }

            // Visit outcome
            Section(header: Text("Visit outcome")) {
                if visit.status.isClosed {
                    Text(visit.status.rawValue)
                        .font(.headline)
                        .foregroundColor(.green)
                    Text(visit.outcomeNote)
                } else {
                    Button("Record Visit Outcome") {
                        showRecordOutcomeView = true
                    }
                }
            }

            // Visit reminder – lets the nurse see the reminder card straight away
            if !visit.status.isClosed {
                Section(header: Text("Visit reminder")) {
                    Button("Preview Visit Reminder") {
                        VisitReminderScheduler.sendPreviewReminder(for: visit)
                        reminderMessage = "Reminder arriving in 5 seconds. Lock the screen or go to the Home Screen to see it."
                    }
                    if !reminderMessage.isEmpty {
                        Text(reminderMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } //: List
        .navigationTitle("Home Visit")
        .sheet(isPresented: $showRecordOutcomeView) {
            RecordOutcomeView(viewModel: RecordOutcomeViewModel(visit: visit, dependencies: dependencies)) { documentedVisit in
                visit = documentedVisit   // Show the outcome on this screen
                onVisitChanged()          // Refresh Today's Round behind it
            }
        }
    }
}

//MARK: - PREVIEW
struct VisitDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleVisit = CareVisit(
            patientID: UUID(),
            patientName: "Margaret Thompson",
            homeAddress: "14 Wattle Street, Parramatta NSW 2150",
            clinicalAlert: "Dog on premises – call ahead",
            careType: .woundCare,
            scheduledStart: Date(),
            durationMinutes: 45
        )
        NavigationView {
            VisitDetailView(visit: sampleVisit, dependencies: .preview)
        }
    }
}
