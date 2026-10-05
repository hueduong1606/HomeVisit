//  WidgetAndReminderRoundSync.swift
//  HomeVisit
//
//  Keeps everything OUTSIDE the app in step with the round:
//  1. writes a RoundSnapshot into the App Group for the NextVisitWidget
//  2. asks WidgetKit to reload the widget timelines
//  3. reschedules the visit reminder notifications

import Foundation
import WidgetKit

final class WidgetAndReminderRoundSync: RoundSyncing {

    //MARK: - PROPERTIES
    private let repository: CaseloadRepository

    //MARK: - INITIALIZER
    init(repository: CaseloadRepository) {
        self.repository = repository
    }

    //MARK: - FUNCTION
    func roundDidChange() {
        let now = Date()

        // Today's visits drive the widget
        let todaysVisits = (try? repository.fetchVisits(scheduledOn: now)) ?? []
        SharedContainerStore.saveRoundSnapshot(makeSnapshot(from: todaysVisits, now: now))
        WidgetCenter.shared.reloadAllTimelines() // Widget shows the change straight away

        // Reminders cover today and tomorrow's outstanding visits
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        let outstandingToday = (try? repository.fetchOutstandingVisits(scheduledOn: now)) ?? []
        let outstandingTomorrow = (try? repository.fetchOutstandingVisits(scheduledOn: tomorrow)) ?? []
        VisitReminderScheduler.reschedule(for: outstandingToday + outstandingTomorrow, now: now)
    }

    //MARK: - PRIVATE
    private func makeSnapshot(from visits: [CareVisit], now: Date) -> RoundSnapshot {
        let outstandingVisits = visits
            .filter { $0.status == .scheduled }
            .sorted { $0.scheduledStart < $1.scheduledStart }

        return RoundSnapshot(
            roundDate: Calendar.current.startOfDay(for: now),
            generatedAt: now,
            closedVisitCount: visits.filter { $0.status.isClosed }.count,
            totalVisitCount: visits.count,
            upcomingVisits: outstandingVisits.map { visit in
                RoundSnapshotVisit(
                    id: visit.id,
                    patientName: visit.patientName,
                    homeAddress: visit.homeAddress,
                    careTypeTitle: visit.careType.rawValue,
                    careTypeSymbol: visit.careType.symbolName,
                    scheduledStart: visit.scheduledStart,
                    durationMinutes: visit.durationMinutes,
                    clinicalAlert: visit.clinicalAlert
                )
            }
        )
    }
}
