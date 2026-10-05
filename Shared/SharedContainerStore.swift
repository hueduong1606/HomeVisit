//  SharedContainerStore.swift
//  Shared by: HomeVisit app, NextVisitWidget, ReferralShareExtension
//
//  Reads and writes the JSON files that live in the App Group container.
//  Each extension runs in its own process, so files in the shared container
//  are how they talk to the main app.

import Foundation

enum SharedContainerStore {

    //MARK: - TODAY'S ROUND (app -> widget)

    // Called by the app after every change to the round
    static func saveRoundSnapshot(_ snapshot: RoundSnapshot) {
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: AppGroup.todaysRoundSnapshotURL, options: .atomic)
        } catch {
            print("Could not publish today's round to the widget: \(error.localizedDescription)")
        }
    }

    // Called by the widget's timeline provider
    static func loadRoundSnapshot() -> RoundSnapshot? {
        guard let data = try? Data(contentsOf: AppGroup.todaysRoundSnapshotURL) else {
            return nil // App has not published a round yet
        }
        do {
            return try JSONDecoder().decode(RoundSnapshot.self, from: data)
        } catch {
            print("Today's round snapshot could not be read: \(error.localizedDescription)")
            return nil
        }
    }

    //MARK: - REFERRAL INBOX (share extension -> app)

    static func loadReferrals() -> [PatientReferral] {
        guard let data = try? Data(contentsOf: AppGroup.referralInboxURL) else {
            return [] // Inbox file does not exist until the first referral is shared
        }
        do {
            let referrals = try JSONDecoder().decode([PatientReferral].self, from: data)
            return referrals.sorted { $0.receivedAt < $1.receivedAt } // Oldest referral first
        } catch {
            print("Referral inbox could not be read: \(error.localizedDescription)")
            return []
        }
    }

    static func saveReferrals(_ referrals: [PatientReferral]) throws {
        let data = try JSONEncoder().encode(referrals)
        try data.write(to: AppGroup.referralInboxURL, options: .atomic)
    }

    // Called by the share extension when the nurse taps "Save to Referral Inbox"
    static func appendReferral(_ referral: PatientReferral) throws {
        var referrals = loadReferrals()
        referrals.append(referral)
        try saveReferrals(referrals)
    }

    // Called by the app once the patient is admitted or the referral is declined
    static func removeReferral(id: UUID) {
        let remainingReferrals = loadReferrals().filter { $0.id != id }
        do {
            try saveReferrals(remainingReferrals)
        } catch {
            print("Referral could not be removed from the inbox: \(error.localizedDescription)")
        }
    }
}
