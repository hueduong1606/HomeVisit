//  ScheduleHomeVisitUseCase.swift
//  HomeVisit


import Foundation

// ScheduleHomeVisitError

enum ScheduleHomeVisitError: LocalizedError, Equatable {
    case patientNotOnCaseload                       // Patient was never admitted (or no longer exists)
    case visitTimeInThePast                         // Start time has already gone
    case visitBeyondPlanningWindow(days: Int)       // More than 14 days ahead
    case visitRunsPastMidnight                      // Visit would spill into the next day's round
    case durationOutsideSafeRange(minutes: Int)     // Shorter than 15 or longer than 180 minutes
    case clashesWithVisit(patientName: String)      // Nurse would be in two homes at once
    case roundCouldNotBeSaved                       // Device could not store the booking – nothing changed

    // What went wrong + what the nurse can do next
    var errorDescription: String? {
        switch self {
        case .patientNotOnCaseload:
            return "This patient is not on your caseload. Admit them from the Caseload tab first, then book the visit."
        case .visitTimeInThePast:
            return "That visit time has already passed. Choose a time later today or on a coming day."
        case .visitBeyondPlanningWindow(let days):
            return "Visits can be planned up to \(days) days ahead. Choose an earlier date, or book this visit closer to the time."
        case .visitRunsPastMidnight:
            return "This visit would finish after midnight. Choose an earlier start time or a shorter visit."
        case .durationOutsideSafeRange(let minutes):
            return "A \(minutes)-minute visit is outside the safe range of 15–180 minutes. Adjust the duration, or split long care into two visits."
        case .clashesWithVisit(let patientName):
            return "This visit overlaps your visit with \(patientName). Pick a start time after that visit finishes."
        case .roundCouldNotBeSaved:
            return "The visit couldn't be saved to your round, so nothing was changed. Your booking is still here – tap Add to Round again."
        }
    }
}

// ScheduleHomeVisitUseCase
struct ScheduleHomeVisitUseCase {

    // PROPERTIES
    let repository: CaseloadRepository
    let roundSync: RoundSyncing

    // shortest and longest visit a nurse can safely book
    static let safeDurationRange = 15...180
    // rounds can be planned today and up to 14 days ahead (e.g. tomorrow's round the day before)
    static let planningWindowDays = 14

    //FUNCTION
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

        // Rule 4: within the planning window (today + 14 days)
        let calendar = Calendar.current
        let endOfPlanningWindow = calendar.date(byAdding: .day, value: ScheduleHomeVisitUseCase.planningWindowDays + 1, to: calendar.startOfDay(for: now))!
        guard scheduledStart < endOfPlanningWindow else {
            throw ScheduleHomeVisitError.visitBeyondPlanningWindow(days: ScheduleHomeVisitUseCase.planningWindowDays)
        }

        // Rule 5: a visit belongs to one day's round, so it must finish before midnight
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: scheduledStart))!
        guard newVisit.scheduledEnd <= startOfNextDay else {
            throw ScheduleHomeVisitError.visitRunsPastMidnight
        }

        // Rule 6: the nurse cannot be in two homes at once
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
