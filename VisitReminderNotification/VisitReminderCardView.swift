//  VisitReminderCardView.swift
//  VisitReminderNotification (Notification Content Extension)
//
//  The rich card shown when the nurse presses and holds a visit reminder:
//  patient, time, address, care type and – most importantly – the safety alert.

import SwiftUI

struct VisitReminderCardView: View {

    //MARK: - PROPERTIES
    let payload: VisitReminderPayload?
    let fallbackTitle: String
    let fallbackBody: String

    //MARK: - BODY
    var body: some View {
        if let payload = payload {
            visitCard(for: payload)
        } else {
            // Not a HomeVisit payload – show the standard text rather than an empty card
            VStack(alignment: .leading, spacing: 6) {
                Text(fallbackTitle)
                    .font(.headline)
                Text(fallbackBody)
                    .font(.subheadline)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    //MARK: - VISIT CARD
    private func visitCard(for payload: VisitReminderPayload) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            // Time and care type
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next home visit")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Text(payload.scheduledStart, style: .time)
                        .font(.largeTitle.bold())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(payload.scheduledStart, style: .relative)
                        .font(.subheadline.bold())
                        .foregroundColor(.accentColor)
                    Text("\(payload.durationMinutes) min visit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } //: HStack

            // Patient
            VStack(alignment: .leading, spacing: 4) {
                Text(payload.patientName)
                    .font(.title3.bold())
                Label(payload.careTypeTitle, systemImage: payload.careTypeSymbol)
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }

            // Address
            Label(payload.homeAddress, systemImage: "mappin.and.ellipse")
                .font(.body)

            // Safety alert – the reason a rich notification matters
            if payload.hasClinicalAlert {
                Label(payload.clinicalAlert, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.bold())
                    .foregroundColor(.orange)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.15))
                    )
            }
        } //: VStack
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

//MARK: - PREVIEW
struct VisitReminderCardView_Previews: PreviewProvider {
    static var previews: some View {
        VisitReminderCardView(
            payload: VisitReminderPayload(
                visitID: UUID().uuidString,
                patientName: "Margaret Thompson",
                homeAddress: "14 Wattle Street, Parramatta NSW 2150",
                careTypeTitle: "Wound care",
                careTypeSymbol: "bandage.fill",
                scheduledStart: Date().addingTimeInterval(15 * 60),
                durationMinutes: 45,
                clinicalAlert: "Dog on premises – call ahead"
            ),
            fallbackTitle: "",
            fallbackBody: ""
        )
        .previewLayout(.sizeThatFits)
    }
}
