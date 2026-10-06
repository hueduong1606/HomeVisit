//  CaseloadView.swift
//  HomeVisit
//
//  Screen 5 – the nurse's caseload. Referrals shared in through the
//  Share Extension wait at the top until the patient is admitted.

import SwiftUI

struct CaseloadView: View {

    //MARK: - PROPERTIES
    @ObservedObject var viewModel: CaseloadViewModel
    @State private var showAdmitPatientView = false
    @State private var selectedReferral: PatientReferral? = nil

    //MARK: - BODY
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                List {
                    // Referrals saved by the Share Extension (App Group)
                    Section(header: Text("Referrals waiting")) {
                        if viewModel.referrals.isEmpty {
                            Text("No referrals waiting. Share a GP referral from Notes, Mail or Messages to HomeVisit.")
                                .foregroundColor(.secondary)
                        }
                        ForEach(viewModel.referrals) { referral in
                            Button {
                                selectedReferral = referral
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(referral.patientName)
                                        .font(.headline)
                                    Text(referral.referralText)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                    Text("Tap to admit to caseload")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                }
                            }
                        } //: ForEach
                    } //: Section

                    // Patients on the caseload
                    Section(header: Text("Patients")) {
                        if viewModel.patients.isEmpty {
                            Text("No patients on your caseload yet. Tap the person icon to admit a patient.")
                                .foregroundColor(.secondary)
                        }
                        ForEach(viewModel.patients) { patient in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(patient.fullName)
                                    .font(.headline)
                                Text(patient.homeAddress)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if patient.hasClinicalAlert {
                                    Label(patient.clinicalAlert, systemImage: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        } //: ForEach
                    } //: Section
                } //: List

                // Error banner – e.g. patients or shared referrals could not be loaded
                if let message = viewModel.errorMessage {
                    ErrorBannerView(message: message) {
                        viewModel.errorMessage = nil
                    }
                }
            } //: ZStack
            .sheet(item: $selectedReferral, onDismiss: {
                viewModel.loadCaseload()
            }) { referral in
                AdmitPatientView(viewModel: AdmitPatientViewModel(referral: referral, dependencies: viewModel.dependencies))
            }
            .navigationTitle("Caseload")
            .navigationBarItems(trailing: Button(action: {
                showAdmitPatientView = true
            }) {
                Image(systemName: "person.badge.plus")
            })
            .sheet(isPresented: $showAdmitPatientView, onDismiss: {
                viewModel.loadCaseload()
            }) {
                AdmitPatientView(viewModel: AdmitPatientViewModel(dependencies: viewModel.dependencies))
            }
            .onAppear {
                viewModel.loadCaseload()
            }
        } //: NavigationView
    }
}

//MARK: - PREVIEW
struct CaseloadView_Previews: PreviewProvider {
    static var previews: some View {
        CaseloadView(viewModel: CaseloadViewModel(dependencies: .preview))
    }
}
