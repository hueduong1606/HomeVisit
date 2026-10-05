//  HomeVisitWidgetBundle.swift
//  NextVisitWidget (WidgetKit extension)
//
//  Template placeholder – replaced by NextVisitWidget on feature/next-visit-widget.

import WidgetKit
import SwiftUI

struct PlaceholderEntry: TimelineEntry {
    let date: Date
}

struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlaceholderEntry {
        PlaceholderEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (PlaceholderEntry) -> Void) {
        completion(PlaceholderEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
        completion(Timeline(entries: [PlaceholderEntry(date: Date())], policy: .never))
    }
}

struct PlaceholderWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HomeVisitPlaceholder", provider: PlaceholderProvider()) { _ in
            Text("HomeVisit")
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("HomeVisit")
    }
}

@main
struct HomeVisitWidgetBundle: WidgetBundle {
    var body: some Widget {
        PlaceholderWidget()
    }
}
