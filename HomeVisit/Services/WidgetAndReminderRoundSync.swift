//  WidgetAndReminderRoundSync.swift
//  HomeVisit
//
//  Keeps everything OUTSIDE the app in step with today's round:
//  1. saves a RoundSnapshot into the App Group for the NextVisitWidget
//  2. asks WidgetKit to reload the widget
//  3. reschedules the visit reminder notifications

import Foundation
import WidgetKit

class WidgetAndReminderRoundSync: RoundSyncing {

    //MARK: - PROPERTIES
    private let repository: CaseloadRepository

    //MARK: - INITIALIZER
    init(repository: CaseloadRepository) {
        self.repository = repository
    }

    //MARK: - FUNCTION
    func roundDidChange() {
        let todaysVisits = (try? repository.fetchVisits(scheduledOn: Date())) ?? []
        let outstandingVisits = todaysVisits.filter { $0.status == .scheduled }

        // 1. Save today's round for the widget
        let snapshot = RoundSnapshot(
            roundDate: Date(),
            closedVisitCount: todaysVisits.count - outstandingVisits.count,
            totalVisitCount: todaysVisits.count,
            upcomingVisits: outstandingVisits.map { visit in
                RoundSnapshotVisit(
                    id: visit.id,
                    patientName: visit.patientName,
                    homeAddress: visit.homeAddress,
                    careTypeTitle: visit.careType.rawValue,
                    scheduledStart: visit.scheduledStart,
                    clinicalAlert: visit.clinicalAlert
                )
            }
        )
        SharedContainerStore.saveRoundSnapshot(snapshot)

        // 2. Ask the widget to redraw with the new round
        WidgetCenter.shared.reloadAllTimelines()

        // 3. One reminder before each visit still to do
        VisitReminderScheduler.rescheduleReminders(for: outstandingVisits)
    }
}
