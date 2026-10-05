//  VisitDetailView.swift
//  HomeVisit
//
//  Screen 2 – everything the nurse needs at the door: who, where, why,
//  safety alerts, a one-tap route and call, and the visit outcome.

import SwiftUI

struct VisitDetailView: View {

    //MARK: - PROPERTIES
    @State var visit: CareVisit
    let dependencies: AppDependencies
    var onVisitChanged: () -> Void

    @State private var isShowingRecordOutcome = false
    @State private var reminderConfirmation: String? = nil

    //MARK: - INITIALIZER
    init(visit: CareVisit, dependencies: AppDependencies, onVisitChanged: @escaping () -> Void = {}) {
        _visit = State(initialValue: visit)
        self.dependencies = dependencies
        self.onVisitChanged = onVisitChanged
    }

    //MARK: - COMPUTED PROPERTIES
    // Apple Maps driving directions to the patient's home
    var directionsURL: URL? {
        guard let encodedAddress = visit.homeAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "https://maps.apple.com/?daddr=\(encodedAddress)&dirflg=d")
    }

    var callURL: URL? {
        guard !visit.dialableContactNumber.isEmpty else { return nil }
        return URL(string: "tel:\(visit.dialableContactNumber)")
    }

    //MARK: - BODY
    var body: some View {
        List {

            // Who and why
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(visit.patientName)
                        .font(.title2)
                        .fontWeight(.bold)
                    Label(visit.careType.rawValue, systemImage: visit.careType.symbolName)
                        .foregroundColor(.accentColor)
                    HStack {
                        Text(visit.scheduledStart, style: .date)
                        Text("at")
                        Text(visit.scheduledStart, style: .time)
                        Text("· \(visit.durationMinutes) min")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                } //: VStack
                .padding(.vertical, 4)
            }

            // Safety first – shown above the address on purpose
            if visit.hasClinicalAlert {
                Section(header: Text("Clinical alert")) {
                    Label(visit.clinicalAlert, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.headline)
                }
            }

            // Getting there
            Section(header: Text("Getting there")) {
                Label(visit.homeAddress, systemImage: "house.fill")
                if let directionsURL = directionsURL {
                    Link(destination: directionsURL) {
                        Label("Directions in Maps", systemImage: "car.fill")
                    }
                }
                if let callURL = callURL {
                    Link(destination: callURL) {
                        Label("Call patient (\(visit.contactNumber))", systemImage: "phone.fill")
                    }
                }
            }

            // Outcome
            Section(header: Text("Visit outcome")) {
                if visit.status.isClosed {
                    Label(visit.status.rawValue, systemImage: visit.status.symbolName)
                        .font(.headline)
                        .foregroundColor(visit.status == .completed ? Color.green : Color.orange)
                    Text(visit.outcomeNote)
                    if let recordedAt = visit.outcomeRecordedAt {
                        Text("Documented \(recordedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button {
                        isShowingRecordOutcome = true
                    } label: {
                        Label("Record Visit Outcome", systemImage: "square.and.pencil")
                            .font(.headline)
                    }
                }
            }

            // Visit reminder (lets the nurse – or a marker – see the rich notification now)
            if !visit.status.isClosed {
                Section(
                    header: Text("Visit reminder"),
                    footer: Text("Reminders arrive \(VisitReminderScheduler.reminderLeadTimeMinutes) minutes before each visit. Press and hold the reminder to see the full visit card.")
                ) {
                    Button {
                        VisitReminderScheduler.sendPreviewReminder(for: visit)
                        reminderConfirmation = "Reminder arriving in 5 seconds – lock the screen or go Home to see it."
                    } label: {
                        Label("Preview Visit Reminder", systemImage: "bell.badge")
                    }
                    if let reminderConfirmation = reminderConfirmation {
                        Text(reminderConfirmation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } //: List
        .listStyle(.insetGrouped)
        .navigationTitle("Home Visit")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingRecordOutcome) {
            RecordOutcomeView(
                viewModel: RecordOutcomeViewModel(visit: visit, dependencies: dependencies),
                onOutcomeSaved: { documentedVisit in
                    visit = documentedVisit   // Show the outcome on this screen
                    onVisitChanged()          // Refresh Today's Round behind it
                }
            )
        }
    }
}

//MARK: - PREVIEW
struct VisitDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleVisit = CareVisit(
            patientID: UUID(),
            patientName: "Dorothy Williams",
            homeAddress: "88 Church Street, Westmead NSW 2145",
            contactNumber: "0400 111 222",
            clinicalAlert: "Falls risk – uses walking frame",
            careType: .postDischargeCheck,
            scheduledStart: Date(),
            durationMinutes: 60
        )
        NavigationView {
            VisitDetailView(visit: sampleVisit, dependencies: .preview)
        }
    }
}
