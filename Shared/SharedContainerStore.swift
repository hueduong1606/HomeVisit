//  SharedContainerStore.swift
//  Shared by: HomeVisit app, NextVisitWidget, ReferralShareExtension
//

import Foundation

enum SharedContainerStore {

    //TODAY'S ROUND (app -> widget)

    // Called by the app after every successful change to the round
    static func saveRoundSnapshot(_ snapshot: RoundSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: AppGroup.todaysRoundSnapshotURL(), options: .atomic)
    }

    // Called by the widget – nil means the app has not published a round yet
    static func loadRoundSnapshot() -> RoundSnapshot? {
        guard let url = try? AppGroup.todaysRoundSnapshotURL(),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(RoundSnapshot.self, from: data)
    }

    //REFERRAL INBOX (share extension -> app)

    // Oldest referral first. Throws ReferralSharingError if the inbox exists but cannot be read.
    static func loadReferrals() throws -> [PatientReferral] {
        let url = try AppGroup.referralInboxURL()
        var coordinatorError: NSError?
        var readError: Error?
        var referrals: [PatientReferral] = []

        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinatorError) { coordinatedURL in
            do {
                referrals = try SharedContainerStore.readReferrals(at: coordinatedURL)
            } catch {
                readError = error
            }
        }

        // Only domain errors leave this file – never a technical file-system message
        if let sharingError = readError as? ReferralSharingError { throw sharingError }
        if coordinatorError != nil || readError != nil { throw ReferralSharingError.referralsWaitingUnreadable }
        return referrals.sorted { $0.receivedAt < $1.receivedAt }
    }

    // Called by the share extension when the nurse taps "Save Referral"
    static func appendReferral(_ referral: PatientReferral) throws {
        try updateReferrals { referrals in
            referrals + [referral]
        }
    }

    // Called by the app once the patient has been admitted
    static func removeReferral(id: UUID) throws {
        try updateReferrals { referrals in
            referrals.filter { $0.id != id }
        }
    }

    //PRIVATE

    // Read -> change -> write the inbox as one coordinated step
    private static func updateReferrals(_ change: ([PatientReferral]) -> [PatientReferral]) throws {
        let url = try AppGroup.referralInboxURL()
        var coordinatorError: NSError?
        var updateError: Error?

        NSFileCoordinator().coordinate(writingItemAt: url, options: .forMerging, error: &coordinatorError) { coordinatedURL in
            do {
                // If the current file can't be read, stop here – never overwrite it with an empty inbox
                let currentReferrals = try SharedContainerStore.readReferrals(at: coordinatedURL)
                let data = try JSONEncoder().encode(change(currentReferrals))
                try data.write(to: coordinatedURL, options: .atomic)
            } catch {
                updateError = error
            }
        }

        // Only domain errors leave this file – never a technical file-system message
        if let sharingError = updateError as? ReferralSharingError { throw sharingError }
        if coordinatorError != nil || updateError != nil { throw ReferralSharingError.referralsWaitingNotUpdated }
    }

    // No file yet = empty inbox. A file that exists but can't be decoded = error.
    private static func readReferrals(at url: URL) throws -> [PatientReferral] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([PatientReferral].self, from: data)
        } catch {
            throw ReferralSharingError.referralsWaitingUnreadable
        }
    }
}
