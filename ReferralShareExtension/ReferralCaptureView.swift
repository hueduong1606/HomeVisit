//  ReferralCaptureView.swift
//  ReferralShareExtension
//
//  The sheet the nurse sees after choosing HomeVisit in the share sheet.
//  They check the name and address, then save the referral to the inbox.

import SwiftUI

struct ReferralCaptureView: View {

    //MARK: - PROPERTIES
    @ObservedObject var draft: ReferralDraft
    var onSave: () -> Void
    var onCancel: () -> Void

    //MARK: - BODY
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Label("Saved referrals wait in HomeVisit's Referral Inbox until you admit the patient.", systemImage: "tray.and.arrow.down.fill")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }

                Section(header: Text("Patient")) {
                    TextField("Patient name", text: $draft.patientName)
                    TextField("Home address", text: $draft.homeAddress, axis: .vertical)
                }

                Section(header: Text("Referral")) {
                    if draft.isLoading && draft.referralText.isEmpty {
                        ProgressView("Reading shared referral…")
                    } else {
                        TextEditor(text: $draft.referralText)
                            .frame(minHeight: 180)
                    }
                }

                if let message = draft.errorMessage {
                    Section {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }
            } //: Form
            .navigationTitle("Save Referral")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save to Inbox") {
                        onSave()
                    }
                    .disabled(!draft.canSave)
                }
            }
        } //: NavigationView
    }
}

//MARK: - PREVIEW
struct ReferralCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        let draft = ReferralDraft()
        let _ = draft.append("Patient: Beatrice Collins\nAddress: 5 Marsden Street, Parramatta NSW 2150\nPost hip replacement – wound and mobility review within 48 hours.")
        ReferralCaptureView(draft: draft, onSave: {}, onCancel: {})
    }
}
