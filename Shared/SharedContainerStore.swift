//  SharedContainerStore.swift
//  Shared by: HomeVisit app, NextVisitWidget, ReferralShareExtension
//
//  Reads and writes the JSON files in the App Group container.
//  Each extension runs in its own process, so these files are how they talk to the app.

import Foundation

enum SharedContainerStore {

    //MARK: - TODAY'S ROUND (app -> widget)

    // Called by the app after every change to the round
    static func saveRoundSnapshot(_ snapshot: RoundSnapshot) {
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: AppGroup.todaysRoundSnapshotURL)
        } catch {
            print("Could not publish today's round to the widget: \(error.localizedDescription)")
        }
    }

    // Called by the widget
    static func loadRoundSnapshot() -> RoundSnapshot? {
        guard let data = try? Data(contentsOf: AppGroup.todaysRoundSnapshotURL) else {
            return nil // The app has not published a round yet
        }
        return try? JSONDecoder().decode(RoundSnapshot.self, from: data)
    }

    //MARK: - REFERRAL INBOX (share extension -> app)

    static func loadReferrals() -> [PatientReferral] {
        guard let data = try? Data(contentsOf: AppGroup.referralInboxURL) else {
            return [] // No referral has been shared yet
        }
        let referrals = (try? JSONDecoder().decode([PatientReferral].self, from: data)) ?? []
        return referrals.sorted { $0.receivedAt < $1.receivedAt } // Oldest referral first
    }

    // Called by the share extension when the nurse taps "Save Referral"
    static func appendReferral(_ referral: PatientReferral) throws {
        var referrals = loadReferrals()
        referrals.append(referral)
        let data = try JSONEncoder().encode(referrals)
        try data.write(to: AppGroup.referralInboxURL)
    }

    // Called by the app once the patient has been admitted
    static func removeReferral(id: UUID) {
        let remainingReferrals = loadReferrals().filter { $0.id != id }
        do {
            let data = try JSONEncoder().encode(remainingReferrals)
            try data.write(to: AppGroup.referralInboxURL)
        } catch {
            print("Referral could not be removed: \(error.localizedDescription)")
        }
    }
}
