//  ReferralTextParser.swift
//  Shared by: ReferralShareExtension and HomeVisit app
//
//  GP and hospital referrals usually contain labelled lines such as
//  "Patient: Margaret Thompson" and "Address: 14 Wattle Street".
//  The parser pulls those values out so the nurse does not have to retype them.

import Foundation

enum ReferralTextParser {
    //MARK: - PROPERTIES
    static let patientNameLabels = ["Patient name", "Patient", "Name", "Re"]
    static let homeAddressLabels = ["Home address", "Address"]

    //MARK: - FUNCTIONS
    static func suggestedPatientName(in referralText: String) -> String {
        value(forLabels: patientNameLabels, in: referralText)
    }

    static func suggestedHomeAddress(in referralText: String) -> String {
        value(forLabels: homeAddressLabels, in: referralText)
    }

    // Returns the text after the first "Label:" match, or "" when nothing matches
    static func value(forLabels labels: [String], in referralText: String) -> String {
        let lines = referralText.components(separatedBy: .newlines)

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let lowercasedLine = trimmedLine.lowercased()

            for label in labels {
                let prefix = label.lowercased() + ":"
                if lowercasedLine.hasPrefix(prefix) {
                    let value = trimmedLine
                        .dropFirst(prefix.count)
                        .trimmingCharacters(in: .whitespaces)
                    if !value.isEmpty {
                        return value
                    }
                }
            }
        }
        return ""
    }
}
