//  ReferralCaptureView.swift
//  ReferralShareExtension
//
//  The sheet the nurse sees after choosing HomeVisit in the share sheet.
//  She types the patient's name, checks the referral text, and saves it.

import SwiftUI

// MARK: - ReferralDraft
// The referral being saved, filled in from the shared text
class ReferralDraft: ObservableObject {
    @Published var patientName: String = ""
    @Published var referralText: String = ""
    @Published var errorMessage: String? = nil
}

// MARK: - ReferralCaptureView
struct ReferralCaptureView: View {

    //MARK: - PROPERTIES
    @ObservedObject var draft: ReferralDraft
    var onSave: () -> Void
    var onCancel: () -> Void

    //MARK: - BODY
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Patient")) {
                    TextField("Patient name", text: $draft.patientName)
                }

                Section(header: Text("Referral")) {
                    TextEditor(text: $draft.referralText)
                        .frame(minHeight: 180)
                }

                if let message = draft.errorMessage {
                    Text(message)
                        .foregroundColor(.red)
                }

                Button("Save Referral to HomeVisit") {
                    onSave()
                }
            } //: Form
            .navigationTitle("New Referral")
            .navigationBarItems(leading: Button("Cancel") {
                onCancel()
            })
        } //: NavigationView
    }
}

//MARK: - PREVIEW
struct ReferralCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        ReferralCaptureView(draft: ReferralDraft(), onSave: {}, onCancel: {})
    }
}
