//  ScheduleHomeVisitUseCase.swift
//  HomeVisit
//
//  Business operation: add a home visit for a patient to the nurse's round.

import Foundation

// MARK: - ScheduleHomeVisitError
enum ScheduleHomeVisitError: LocalizedError, Equatable {
    case patientNotOnCaseload
    case visitTimeInThePast
    case durationOutsideSafeRange(minutes: Int)
    case dailyVisitLimitReached(limit: Int)
    case clashesWithVisit(patientName: String, startTime: Date)
    case roundCouldNotBeSaved

    // What went wrong – in the nurse's words
    var errorDescription: String? {
        switch self {
        case .patientNotOnCaseload:
            return "This patient is no longer on your caseload."
        case .visitTimeInThePast:
            return "That visit time has already passed."
        case .durationOutsideSafeRange(let minutes):
            return "A \(minutes)-minute visit is outside the safe range of \(ScheduleHomeVisitUseCase.safeDurationRange.lowerBound)–\(ScheduleHomeVisitUseCase.safeDurationRange.upperBound) minutes."
        case .dailyVisitLimitReached(let limit):
            return "Your round already has \(limit) visits on that day – the safe daily limit."
        case .clashesWithVisit(let patientName, let startTime):
            return "This visit overlaps your \(startTime.formatted(date: .omitted, time: .shortened)) visit with \(patientName)."
        case .roundCouldNotBeSaved:
            return "The visit couldn't be saved to your round."
        }
    }

    // What the nurse can do next
    var recoverySuggestion: String? {
        switch self {
        case .patientNotOnCaseload:
            return "Admit the patient again from the Caseload tab, then book the visit."
        case .visitTimeInThePast:
            return "Choose a start time later today or on another day."
        case .durationOutsideSafeRange:
            return "Adjust the duration, or split long care into two visits."
        case .dailyVisitLimitReached:
            return "Book the visit on another day or ask your team leader to reallocate it."
        case .clashesWithVisit:
            return "Pick a start time after that visit finishes."
        case .roundCouldNotBeSaved:
            return "Nothing was changed. Try again in a moment."
        }
    }
}

// MARK: - ScheduleHomeVisitUseCase
struct ScheduleHomeVisitUseCase {

    //MARK: - PROPERTIES
    let repository: CaseloadRepository
    let roundSync: RoundSyncing

    // Business rule: shortest and longest visit a nurse can safely book
    static let safeDurationRange: ClosedRange<Int> = 15...180
    // Business rule: maximum visits one nurse can safely make in a day
    static let maximumVisitsPerDay = 10
    // Business rule: a visit "starting now" may be booked up to 5 minutes late
    static let bookingGraceMinutes = 5

    //MARK: - FUNCTION
    func execute(
        patientID: UUID,
        careType: CareType,
        scheduledStart: Date,
        durationMinutes: Int,
        now: Date = Date()
    ) throws(ScheduleHomeVisitError) -> CareVisit {

        // Rule 1: the patient must still be on the caseload
        let foundPatient: Patient?
        do {
            foundPatient = try repository.findPatient(id: patientID)
        } catch {
            throw ScheduleHomeVisitError.roundCouldNotBeSaved
        }
        guard let patient = foundPatient else {
            throw ScheduleHomeVisitError.patientNotOnCaseload
        }

        // Rule 2: a visit cannot be booked in the past
        let earliestAllowedStart = now.addingTimeInterval(TimeInterval(-ScheduleHomeVisitUseCase.bookingGraceMinutes * 60))
        guard scheduledStart >= earliestAllowedStart else {
            throw ScheduleHomeVisitError.visitTimeInThePast
        }

        // Rule 3: the duration must be within the safe range
        guard ScheduleHomeVisitUseCase.safeDurationRange.contains(durationMinutes) else {
            throw ScheduleHomeVisitError.durationOutsideSafeRange(minutes: durationMinutes)
        }

        let newVisit = CareVisit(
            patientID: patient.id,
            patientName: patient.fullName,
            homeAddress: patient.homeAddress,
            contactNumber: patient.contactNumber,
            clinicalAlert: patient.clinicalAlert,
            careType: careType,
            scheduledStart: scheduledStart,
            durationMinutes: durationMinutes
        )

        let visitsThatDay: [CareVisit]
        do {
            visitsThatDay = try repository.fetchVisits(scheduledOn: scheduledStart)
        } catch {
            throw ScheduleHomeVisitError.roundCouldNotBeSaved
        }

        // Rule 4: never exceed the safe number of visits in one day
        guard visitsThatDay.count < ScheduleHomeVisitUseCase.maximumVisitsPerDay else {
            throw ScheduleHomeVisitError.dailyVisitLimitReached(limit: ScheduleHomeVisitUseCase.maximumVisitsPerDay)
        }

        // Rule 5: the nurse cannot be in two homes at once (no-access visits free their slot)
        if let clashingVisit = visitsThatDay.first(where: { $0.status != .noAccess && $0.clashes(with: newVisit) }) {
            throw ScheduleHomeVisitError.clashesWithVisit(
                patientName: clashingVisit.patientName,
                startTime: clashingVisit.scheduledStart
            )
        }

        do {
            try repository.saveVisit(newVisit)
        } catch {
            throw ScheduleHomeVisitError.roundCouldNotBeSaved
        }

        // Keep the widget and reminders in step with the new round
        roundSync.roundDidChange()
        return newVisit
    }
}
