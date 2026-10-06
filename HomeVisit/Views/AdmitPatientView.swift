//  AdmitPatientView.swift
//  HomeVisit
//

import SwiftUI

struct AdmitPatientView: View {

    //PROPERTIES
    @StateObject var viewModel: AdmitPatientViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    //INITIALIZER
    init(viewModel: AdmitPatientViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // BODY
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Form {
                    Section(header: Text("Patient")) {
                        TextField("Full name", text: $viewModel.fullName)
                        TextField("Home address (street number and street)", text: $viewModel.homeAddress)
                    }

                    Section(header: Text("Clinical alert"), footer: Text("e.g. Dog on premises – call ahead")) {
                        TextField("Safety or access alert (optional)", text: $viewModel.clinicalAlert)
                    }

                    Section(header: Text("Reason for referral")) {
                        TextEditor(text: $viewModel.referralNote)
                            .frame(minHeight: 120)
                    }

                    Button("Admit to Caseload") {
                        if viewModel.admitPatient() {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                } //: Form

                if let message = viewModel.errorMessage {
                    ErrorBannerView(message: message) {
                        viewModel.errorMessage = nil
                    }
                }
            } //: ZStack
            .navigationTitle("Admit Patient")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        } //: NavigationView
    }
}

// PREVIEW
struct AdmitPatientView_Previews: PreviewProvider {
    static var previews: some View {
        AdmitPatientView(viewModel: AdmitPatientViewModel(dependencies: .preview))
    }
}
