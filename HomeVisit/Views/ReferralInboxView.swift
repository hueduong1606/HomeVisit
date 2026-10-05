//  ReferralInboxView.swift
//  HomeVisit
//
//  Screen 8 – referrals the nurse shared into HomeVisit from Mail, Messages
//  or Notes using the Share Extension. Tap to admit, swipe to decline.

import SwiftUI

struct ReferralInboxView: View {

    //MARK: - PROPERTIES
    @ObservedObject var viewModel: ReferralInboxViewModel
    var onPatientAdmitted: () -> Void = {}

    @State private var selectedReferral: PatientReferral? = nil

    //MARK: - BODY
    var body: some View {
        NavigationView {
            Group {
                if viewModel.referrals.isEmpty {
                    ContentUnavailableView(
                        "No referrals waiting",
                        systemImage: "tray",
                        description: Text("When a GP or hospital sends you a referral, select the text in Mail, Messages or Notes, tap Share and choose HomeVisit.")
                    )
                } else {
                    referralList
                }
            } //: Group
            .navigationTitle("Referral Inbox")
            .sheet(item: $selectedReferral, onDismiss: {
                viewModel.loadReferrals()
            }) { referral in
                AdmitPatientView(
                    viewModel: AdmitPatientViewModel(referral: referral, dependencies: viewModel.dependencies),
                    onPatientAdmitted: onPatientAdmitted
                )
            }
            .onAppear {
                viewModel.loadReferrals()
            }
        } //: NavigationView
    }

    //MARK: - REFERRAL LIST
    private var referralList: some View {
        List {
            Section(
                header: Text("Waiting to be admitted"),
                footer: Text("Oldest referral first. Swipe left to decline a referral you can't accept.")
            ) {
                ForEach(viewModel.referrals) { referral in
                    Button {
                        selectedReferral = referral
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(referral.inboxTitle)
                                .font(.headline)
                                .foregroundColor(.primary)
                            if !referral.suggestedHomeAddress.isEmpty {
                                Label(referral.suggestedHomeAddress, systemImage: "mappin.and.ellipse")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Text(referral.previewLine)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            Text("Received \(referral.receivedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } //: VStack
                        .padding(.vertical, 4)
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            viewModel.decline(referral)
                        } label: {
                            Label("Decline", systemImage: "xmark.bin")
                        }
                        .tint(.red)
                    }
                } //: ForEach
            } //: Section
        } //: List
        .listStyle(.insetGrouped)
        .refreshable {
            viewModel.loadReferrals()
        }
    }
}

//MARK: - PREVIEW
struct ReferralInboxView_Previews: PreviewProvider {
    static var previews: some View {
        ReferralInboxView(viewModel: ReferralInboxViewModel(dependencies: .preview))
    }
}
