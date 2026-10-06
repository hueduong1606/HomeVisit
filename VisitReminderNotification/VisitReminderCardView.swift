//  VisitReminderCardView.swift
//  VisitReminderNotification (Notification Content Extension)
//
//  The custom card shown when the nurse presses and holds a visit reminder:
//  time, patient, care type, address and – most importantly – the safety alert.

import SwiftUI

struct VisitReminderCardView: View {

    //MARK: - PROPERTIES
    let payload: VisitReminderPayload

    //MARK: - BODY
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Next home visit")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(payload.scheduledStart, style: .time)
                .font(.largeTitle)
                .bold()

            Text(payload.patientName)
                .font(.title3)
                .bold()

            Text(payload.careTypeTitle)
                .foregroundColor(.accentColor)

            Label(payload.homeAddress, systemImage: "house.fill")

            // Safety alert – the reason this notification has a custom view
            if !payload.clinicalAlert.isEmpty {
                Label(payload.clinicalAlert, systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
        } //: VStack
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

//MARK: - PREVIEW
struct VisitReminderCardView_Previews: PreviewProvider {
    static var previews: some View {
        VisitReminderCardView(payload: VisitReminderPayload(
            patientName: "Margaret Thompson",
            homeAddress: "14 Wattle Street, Parramatta NSW 2150",
            careTypeTitle: "Wound care",
            scheduledStart: Date(),
            clinicalAlert: "Dog on premises – call ahead"
        ))
        .previewLayout(.sizeThatFits)
    }
}
