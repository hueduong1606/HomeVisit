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

    //MARK: - BODY
    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // Time column
            VStack {
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

                Text(visit.homeAddress)
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
                    Text("Running late – call the patient ahead")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.red)
                }

                if visit.status.isClosed {
                    Text(visit.status.rawValue)
                        .font(.caption)
                        .bold()
                        .foregroundColor(.green)
                }
            } //: VStack
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
            clinicalAlert: "Dog on premises – call ahead",
            careType: .woundCare,
            scheduledStart: Date(),
            durationMinutes: 45
        )
        VisitCardView(visit: sampleVisit, isRunningLate: true)
            .previewLayout(.sizeThatFits)
    }
}
