//  NurseFacingMessage.swift
//  HomeVisit
//
//  Turns any error thrown by a Use Case into one sentence a nurse can act on:
//  what went wrong (errorDescription) + what to do next (recoverySuggestion).

import Foundation

enum NurseFacingMessage {

    static func from(_ error: Error) -> String {
        guard let domainError = error as? LocalizedError else {
            return "HomeVisit couldn't finish that. Your round has not changed – please try again."
        }
        let parts = [domainError.errorDescription, domainError.recoverySuggestion].compactMap { $0 }
        return parts.joined(separator: " ")
    }
}
