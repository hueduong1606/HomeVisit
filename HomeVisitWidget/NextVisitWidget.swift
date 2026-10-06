//  NextVisitWidget.swift
//  NextVisitWidget (WidgetKit extension)
//
//  User scenario: between homes, the nurse needs the next visit time and address
//  at a glance – on the Lock Screen while the phone sits in the car cradle,
//  or on the Home Screen – without opening the app.
//
//  Data source: TodaysRound.json in the App Group container, written by the app
//  after every change to the round (WidgetAndReminderRoundSync).

import WidgetKit
import SwiftUI

// MARK: - NextVisitEntry
struct NextVisitEntry: TimelineEntry {
    let date: Date
    let snapshot: RoundSnapshot?

    // Only trust a snapshot that belongs to today
    var todaysSnapshot: RoundSnapshot? {
        guard let snapshot = snapshot, snapshot.isForToday(now: date) else { return nil }
        return snapshot
    }
}

// MARK: - NextVisitProvider
struct NextVisitProvider: TimelineProvider {

    // Shown while the widget loads for the first time
    func placeholder(in context: Context) -> NextVisitEntry {
        NextVisitEntry(date: Date(), snapshot: RoundSnapshot.sample)
    }

    // Shown in the widget gallery
    func getSnapshot(in context: Context, completion: @escaping (NextVisitEntry) -> Void) {
        let savedSnapshot = SharedContainerStore.loadRoundSnapshot()
        completion(NextVisitEntry(date: Date(), snapshot: savedSnapshot ?? RoundSnapshot.sample))
    }

    // Reads the latest round from the App Group container.
    // The app reloads the widget after every change; as a safety net it also refreshes every 30 minutes.
    func getTimeline(in context: Context, completion: @escaping (Timeline<NextVisitEntry>) -> Void) {
        let entry = NextVisitEntry(date: Date(), snapshot: SharedContainerStore.loadRoundSnapshot())
        let nextRefresh = Date().addingTimeInterval(30 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

// MARK: - NextVisitWidgetView
struct NextVisitWidgetView: View {

    //MARK: - PROPERTIES
    let entry: NextVisitEntry
    @Environment(\.widgetFamily) var family

    //MARK: - BODY
    var body: some View {
        if let snapshot = entry.todaysSnapshot, let nextVisit = snapshot.nextVisit {
            // There is a visit still to do
            if family == .accessoryRectangular {
                // Lock Screen
                VStack(alignment: .leading) {
                    Text(nextVisit.scheduledStart, style: .time)
                        .font(.headline)
                    Text(nextVisit.patientName)
                        .font(.caption)
                    Text(nextVisit.homeAddress)
                        .font(.caption)
                }
            } else {
                // Home Screen
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next visit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(nextVisit.scheduledStart, style: .time)
                        .font(.title2)
                        .bold()
                    Text(nextVisit.patientName)
                        .font(.subheadline)
                        .bold()
                    Text(nextVisit.homeAddress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if !nextVisit.clinicalAlert.isEmpty {
                        Text("⚠️ \(nextVisit.clinicalAlert)")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
        } else {
            // Never a bare "No data" – tell the nurse what the round looks like
            VStack(alignment: .leading, spacing: 4) {
                Text(statusHeadline)
                    .font(.headline)
                Text(statusDetail)
                    .font(.caption)
            }
        }
    }

    //MARK: - EMPTY STATES
    var statusHeadline: String {
        guard let snapshot = entry.todaysSnapshot else { return "Open HomeVisit" }
        return snapshot.totalVisitCount == 0 ? "No visits today" : "Round complete"
    }

    var statusDetail: String {
        guard let snapshot = entry.todaysSnapshot else { return "Open the app to load today's round." }
        if snapshot.totalVisitCount == 0 {
            return "Add a visit in HomeVisit to see it here."
        }
        return "All \(snapshot.totalVisitCount) visits documented."
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
        .description("Your next patient, visit time and address.")
        .supportedFamilies([.systemSmall, .accessoryRectangular]) // Home Screen + Lock Screen
    }
}

//MARK: - PREVIEW
struct NextVisitWidget_Previews: PreviewProvider {
    static var previews: some View {
        NextVisitWidgetView(entry: NextVisitEntry(date: Date(), snapshot: RoundSnapshot.sample))
            .containerBackground(.fill.tertiary, for: .widget)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
