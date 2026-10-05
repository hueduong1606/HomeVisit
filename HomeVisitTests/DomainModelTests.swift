//  DomainModelTests.swift
//  HomeVisitTests
//
//  Rules that live on the domain models and on the shared referral parser.

import Testing
import Foundation
@testable import HomeVisit

@MainActor
struct DomainModelTests {

    //MARK: - CARE VISIT

    @Test("Two visits clash when the second starts before the first has finished")
    func overlappingVisits_clash() {
        let nineToTen = CaseloadFixtures.visit(for: CaseloadFixtures.margaret, at: CaseloadFixtures.tuesday(hour: 9), durationMinutes: 60)
        let nineThirty = CaseloadFixtures.visit(for: CaseloadFixtures.arthur, at: CaseloadFixtures.tuesday(hour: 9, minute: 30))
        let tenOClock = CaseloadFixtures.visit(for: CaseloadFixtures.arthur, at: CaseloadFixtures.tuesday(hour: 10))

        #expect(nineToTen.clashes(with: nineThirty))
        #expect(!nineToTen.clashes(with: tenOClock), "Back-to-back visits do not clash")
    }

    //MARK: - REFERRAL PARSER (Share Extension)

    @Test("A labelled GP referral pre-fills the patient's name and address")
    func labelledReferral_prefillsNameAndAddress() {
        let referralText = """
        Dear Community Nursing Team,
        Patient name: Beatrice Collins
        Address: 5 Marsden Street, Parramatta NSW 2150
        Post hip replacement – please review wound within 48 hours.
        """

        #expect(ReferralTextParser.suggestedPatientName(in: referralText) == "Beatrice Collins")
        #expect(ReferralTextParser.suggestedHomeAddress(in: referralText) == "5 Marsden Street, Parramatta NSW 2150")
    }

    @Test("A referral without labels leaves the fields blank for the nurse to fill in")
    func unlabelledReferral_leavesFieldsBlank() {
        let referralText = "Please see Mrs Collins at home this week for a wound review."

        #expect(ReferralTextParser.suggestedPatientName(in: referralText).isEmpty)
        #expect(ReferralTextParser.suggestedHomeAddress(in: referralText).isEmpty)
    }

    //MARK: - NURSE-FACING ERRORS

    @Test("Every scheduling error tells the nurse what went wrong AND what to do next")
    func everySchedulingError_hasNextStep() {
        let errors: [ScheduleHomeVisitError] = [
            .patientNotOnCaseload,
            .visitTimeInThePast,
            .durationOutsideSafeRange(minutes: 200),
            .dailyVisitLimitReached(limit: 10),
            .clashesWithVisit(patientName: "Arthur Nguyen", startTime: CaseloadFixtures.tuesday(hour: 10)),
            .roundCouldNotBeSaved
        ]

        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
            #expect(error.recoverySuggestion?.isEmpty == false)
        }
    }
}
