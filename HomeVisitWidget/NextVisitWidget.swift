//  NextVisitWidget.swift
//  NextVisitWidget (WidgetKit extension)
//
//  User scenario: between homes the nurse needs the next patient's time and
//  address at a glance – on the Lock Screen while the phone sits in the car
//  cradle, or on the Home Screen – without opening the app.
//
//  Data source: RoundSnapshot JSON in the App Group container, written by the app
//  after every change to the round (WidgetAndReminderRoundSync).

import WidgetKit
import SwiftUI

// MARK: - NextVisitEntry
struct NextVisitEntry: TimelineEntry {
    let date: Date
    let snapshot: RoundSnapshot?

    //MARK: - COMPUTED PROPERTIES
    // Only trust a snapshot that belongs to today
    var todaysSnapshot: RoundSnapshot? {
        guard let snapshot = snapshot, snapshot.isForToday(now: date) else { return nil }
        return snapshot
    }

    var nextVisit: RoundSnapshotVisit? {
        todaysSnapshot?.nextVisit
    }
}

// MARK: - NextVisitProvider
struct NextVisitProvider: TimelineProvider {

    // Shown while the widget is loading for the first time
    func placeholder(in context: Context) -> NextVisitEntry {
        NextVisitEntry(date: Date(), snapshot: .sample)
    }

    // Shown in the widget gallery
    func getSnapshot(in context: Context, completion: @escaping (NextVisitEntry) -> Void) {
        let savedSnapshot = SharedContainerStore.loadRoundSnapshot()
        let snapshot: RoundSnapshot? = context.isPreview ? (savedSnapshot ?? RoundSnapshot.sample) : savedSnapshot
        completion(NextVisitEntry(date: Date(), snapshot: snapshot))
    }

    // Real timeline: read the latest round from the App Group container
    func getTimeline(in context: Context, completion: @escaping (Timeline<NextVisitEntry>) -> Void) {
        let now = Date()
        let entry = NextVisitEntry(date: now, snapshot: SharedContainerStore.loadRoundSnapshot())

        // The app reloads the widget after every change; as a safety net refresh
        // every 30 minutes and just after midnight so yesterday's round never shows.
        let calendar = Calendar.current
        let justAfterMidnight = calendar.date(byAdding: .minute, value: 1, to: calendar.startOfDay(for: now).addingTimeInterval(24 * 60 * 60)) ?? now
        let inThirtyMinutes = now.addingTimeInterval(30 * 60)
        let nextRefresh = min(justAfterMidnight, inThirtyMinutes)

        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

// MARK: - NextVisitWidget
struct NextVisitWidget: Widget {
    let kind: String = "NextVisitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextVisitProvider()) { entry in
            NextVisitWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next Home Visit")
        .description("Your next patient, visit time and address – without unlocking HomeVisit.")
        .supportedFamilies([
            .systemSmall,            // Home Screen
            .systemMedium,           // Home Screen
            .accessoryRectangular,   // Lock Screen
            .accessoryInline         // Lock Screen (above the clock)
        ])
    }
}
