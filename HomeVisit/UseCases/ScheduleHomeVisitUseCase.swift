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
    case clashesWithVisit(patientName: String)
    case roundCouldNotBeSaved

    // What went wrong + what the nurse can do next
    var errorDescription: String? {
        switch self {
        case .patientNotOnCaseload:
            return "This patient is not on your caseload. Admit them from the Caseload tab first, then book the visit."
        case .visitTimeInThePast:
            return "That visit time has already passed. Choose a time later today or on another day."
        case .durationOutsideSafeRange(let minutes):
            return "A \(minutes)-minute visit is outside the safe range of 15–180 minutes. Adjust the duration, or split long care into two visits."
        case .clashesWithVisit(let patientName):
            return "This visit overlaps your visit with \(patientName). Pick a start time after that visit finishes."
        case .roundCouldNotBeSaved:
            return "The visit couldn't be saved to your round. Nothing was changed – please try again."
        }
    }
}

// MARK: - ScheduleHomeVisitUseCase
struct ScheduleHomeVisitUseCase {

    //MARK: - PROPERTIES
    let repository: CaseloadRepository
    let roundSync: RoundSyncing

    // Business rule: shortest and longest visit a nurse can safely book
    static let safeDurationRange = 15...180

    //MARK: - FUNCTION
    func execute(
        patientID: UUID,
        careType: CareType,
        scheduledStart: Date,
        durationMinutes: Int,
        now: Date = Date()
    ) throws(ScheduleHomeVisitError) -> CareVisit {

        // Rule 1: the patient must be on the caseload
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
        guard scheduledStart >= now else {
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
            clinicalAlert: patient.clinicalAlert,
            careType: careType,
            scheduledStart: scheduledStart,
            durationMinutes: durationMinutes
        )

        // Rule 4: the nurse cannot be in two homes at once
        let outstandingVisitsThatDay: [CareVisit]
        do {
            outstandingVisitsThatDay = try repository.fetchOutstandingVisits(scheduledOn: scheduledStart)
        } catch {
            throw ScheduleHomeVisitError.roundCouldNotBeSaved
        }
        for bookedVisit in outstandingVisitsThatDay {
            if bookedVisit.clashes(with: newVisit) {
                throw ScheduleHomeVisitError.clashesWithVisit(patientName: bookedVisit.patientName)
            }
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
