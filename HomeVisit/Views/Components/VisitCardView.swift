//  VisitCardView.swift
//  HomeVisit
//
//  One visit on Today's Round: time, patient, address, care type and alerts.
//  Has zero knowledge of the database.

import SwiftUI

struct VisitCardView: View {

    //MARK: - PROPERTIES
    let visit: CareVisit
    var isRunningLate: Bool = false

    // Green = completed, orange = no access, grey = still to visit
    var statusColor: Color {
        switch visit.status {
        case .completed:
            return Color.green
        case .noAccess:
            return Color.orange
        case .scheduled:
            return Color.secondary
        }
    }

    //MARK: - BODY
    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // Time column
            VStack(alignment: .center, spacing: 2) {
                Text(visit.scheduledStart, style: .time)
                    .font(.headline)
                Text("\(visit.durationMinutes) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } //: VStack
            .frame(width: 74)

            // Patient column
            VStack(alignment: .leading, spacing: 4) {
                Text(visit.patientName)
                    .font(.headline)

                Label(visit.homeAddress, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Label(visit.careType.rawValue, systemImage: visit.careType.symbolName)
                    .font(.caption)
                    .foregroundColor(.accentColor)

                if visit.hasClinicalAlert {
                    Label(visit.clinicalAlert, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                if isRunningLate {
                    Label("Running late – consider calling ahead", systemImage: "clock.badge.exclamationmark")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                }
            } //: VStack

            Spacer(minLength: 0)

            Image(systemName: visit.status.symbolName)
                .foregroundColor(statusColor)
                .accessibilityLabel(visit.status.rawValue)
        } //: HStack
        .padding(.vertical, 6)
    }
}

//MARK: - PREVIEW
struct VisitCardView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleVisit = CareVisit(
            patientID: UUID(),
            patientName: "Margaret Thompson",
            homeAddress: "14 Wattle Street, Parramatta NSW 2150",
            contactNumber: "0412 345 678",
            clinicalAlert: "Dog on premises – call ahead",
            careType: .woundCare,
            scheduledStart: Date(),
            durationMinutes: 45
        )
        List {
            VisitCardView(visit: sampleVisit, isRunningLate: true)
        }
    }
}
