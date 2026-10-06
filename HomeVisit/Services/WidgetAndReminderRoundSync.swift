//  WidgetAndReminderRoundSync.swift
//  HomeVisit
//
//  Keeps everything OUTSIDE the app in step with today's round:
//  1. saves a RoundSnapshot into the App Group for the NextVisitWidget
//  2. asks WidgetKit to reload the widget
//  3. reschedules the visit reminder notifications
//  Use Cases only call this after a successful save.

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
        // If today's round can't be read, keep the widget and reminders the nurse already has
        let todaysVisits: [CareVisit]
        do {
            todaysVisits = try repository.fetchVisits(scheduledOn: Date())
        } catch {
            print("Today's round could not be loaded – widget and reminders left unchanged: \(error)")
            return
        }
        let outstandingVisits = todaysVisits.filter { $0.status == .scheduled }

        // 1. Save today's round for the widget, then 2. ask the widget to redraw
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
        do {
            try SharedContainerStore.saveRoundSnapshot(snapshot)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Widget not updated: \(error.localizedDescription)")
        }

        // 3. One reminder before each visit still to do
        VisitReminderScheduler.rescheduleReminders(for: outstandingVisits)
    }
}
