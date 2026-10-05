//  AdmitPatientView.swift
//  HomeVisit
//
//  Screen 7 – admit a patient to the caseload, typed in by hand
//  or pre-filled from a referral in the Referral Inbox.

import SwiftUI

struct AdmitPatientView: View {

    //MARK: - PROPERTIES
    @StateObject var viewModel: AdmitPatientViewModel
    var onPatientAdmitted: () -> Void

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    //MARK: - INITIALIZER
    init(viewModel: AdmitPatientViewModel, onPatientAdmitted: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onPatientAdmitted = onPatientAdmitted
    }

    //MARK: - BODY
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Form {
                    if viewModel.isFromReferral {
                        Section {
                            Label("Pre-filled from a shared referral. Check every detail before admitting.", systemImage: "doc.text.magnifyingglass")
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                        }
                    }

                    // Patient details
                    Section(header: Text("Patient")) {
                        TextField("Full name", text: $viewModel.fullName)
                            .textContentType(.name)
                            .autocorrectionDisabled()
                        TextField("Home address (street number and street)", text: $viewModel.homeAddress, axis: .vertical)
                            .textContentType(.fullStreetAddress)
                        TextField("Contact number (optional)", text: $viewModel.contactNumber)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                    }

                    // Safety
                    Section(
                        header: Text("Clinical alert"),
                        footer: Text("Shown before every visit, on the reminder and on the visit screen – e.g. \"Dog on premises – call ahead\".")
                    ) {
                        TextField("Safety or access alert (optional)", text: $viewModel.clinicalAlert, axis: .vertical)
                    }

                    // Referral
                    Section(header: Text("Reason for referral")) {
                        TextEditor(text: $viewModel.referralNote)
                            .frame(minHeight: 120)
                    }
                } //: Form

                if let message = viewModel.errorMessage {
                    ErrorBannerView(message: message) {
                        viewModel.errorMessage = nil
                    }
                }
            } //: ZStack
            .animation(.spring(), value: viewModel.errorMessage)
            .navigationTitle(viewModel.isFromReferral ? "Accept Referral" : "Admit to Caseload")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Admit") {
                        if viewModel.admitPatient() != nil {
                            onPatientAdmitted()
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .disabled(!viewModel.canAdmit)
                }
            }
        } //: NavigationView
    }
}

//MARK: - PREVIEW
struct AdmitPatientView_Previews: PreviewProvider {
    static var previews: some View {
        AdmitPatientView(
            viewModel: AdmitPatientViewModel(
                referral: PreviewReferralInbox().pendingReferrals().first,
                dependencies: .preview
            )
        )
    }
}
