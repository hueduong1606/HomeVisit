//  NextVisitWidgetView.swift
//  NextVisitWidget (WidgetKit extension)
//
//  One layout per widget family. Patient names are marked privacySensitive()
//  so they are redacted on a locked device – the address and time stay visible
//  because those are what the nurse needs while driving.

import WidgetKit
import SwiftUI

struct NextVisitWidgetView: View {

    //MARK: - PROPERTIES
    let entry: NextVisitEntry
    @Environment(\.widgetFamily) var family

    //MARK: - BODY
    var body: some View {
        switch family {
        case .accessoryInline:
            inlineView
        case .accessoryRectangular:
            rectangularView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    //MARK: - LOCK SCREEN: INLINE
    private var inlineView: some View {
        Group {
            if let nextVisit = entry.nextVisit {
                Text("\(Image(systemName: "car.fill")) \(nextVisit.scheduledStart, style: .time) · \(nextVisit.homeAddress)")
            } else {
                Text("\(Image(systemName: "checkmark.seal.fill")) \(statusHeadline)")
            }
        }
    }

    //MARK: - LOCK SCREEN: RECTANGULAR
    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let nextVisit = entry.nextVisit {
                HStack(spacing: 4) {
                    Image(systemName: nextVisit.careTypeSymbol)
                    Text(nextVisit.scheduledStart, style: .time)
                        .fontWeight(.semibold)
                    if nextVisit.hasClinicalAlert {
                        Image(systemName: "exclamationmark.triangle.fill")
                    }
                }
                .font(.headline)
                Text(nextVisit.patientShortName)
                    .font(.caption)
                    .privacySensitive()
                Text(nextVisit.homeAddress)
                    .font(.caption)
                    .lineLimit(1)
            } else {
                Label(statusHeadline, systemImage: "house.fill")
                    .font(.headline)
                Text(statusDetail)
                    .font(.caption)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    //MARK: - HOME SCREEN: SMALL
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Next visit", systemImage: "car.fill")
                .font(.caption.bold())
                .foregroundColor(.accentColor)

            if let nextVisit = entry.nextVisit {
                Text(nextVisit.scheduledStart, style: .time)
                    .font(.title2.bold())
                Text(nextVisit.patientName)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .privacySensitive()
                Text(nextVisit.homeAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Spacer(minLength: 0)
                if nextVisit.hasClinicalAlert {
                    Label("Alert", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2.bold())
                        .foregroundColor(.orange)
                }
            } else {
                Text(statusHeadline)
                    .font(.headline)
                Text(statusDetail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    //MARK: - HOME SCREEN: MEDIUM
    private var mediumView: some View {
        HStack(alignment: .top, spacing: 12) {
            smallView

            if let snapshot = entry.todaysSnapshot {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(snapshot.closedVisitCount) of \(snapshot.totalVisitCount) closed")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    // The two visits after the next one
                    ForEach(snapshot.upcomingVisits.dropFirst().prefix(2)) { visit in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(visit.scheduledStart, style: .time)
                                .font(.caption.bold())
                            Text(visit.patientShortName)
                                .font(.caption)
                                .lineLimit(1)
                                .privacySensitive()
                        }
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    //MARK: - EMPTY / ROUND COMPLETE STATES (never a bare "No data")
    private var statusHeadline: String {
        guard let snapshot = entry.todaysSnapshot else {
            return "Open HomeVisit"
        }
        return snapshot.totalVisitCount == 0 ? "No visits today" : "Round complete"
    }

    private var statusDetail: String {
        guard let snapshot = entry.todaysSnapshot else {
            return "Open the app to load today's round."
        }
        if snapshot.totalVisitCount == 0 {
            return "Add a visit in HomeVisit to see it here."
        }
        return "All \(snapshot.totalVisitCount) visits documented."
    }
}

//MARK: - PREVIEW
struct NextVisitWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NextVisitWidgetView(entry: NextVisitEntry(date: Date(), snapshot: .sample))
                .containerBackground(.fill.tertiary, for: .widget)
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            NextVisitWidgetView(entry: NextVisitEntry(date: Date(), snapshot: .sample))
                .containerBackground(.fill.tertiary, for: .widget)
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            NextVisitWidgetView(entry: NextVisitEntry(date: Date(), snapshot: .sample))
                .containerBackground(.fill.tertiary, for: .widget)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
        }
    }
}
