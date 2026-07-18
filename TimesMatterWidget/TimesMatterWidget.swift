//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import WidgetKit

struct CountdownEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct CountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(
            date: .now,
            snapshot: WidgetSnapshot(
                updatedAt: .now,
                items: [
                    WidgetCountdownItem(
                        id: 1,
                        title: "New Year",
                        targetDate: Calendar.current.date(byAdding: .day, value: 12, to: .now) ?? .now,
                        isFavorite: true,
                        backgroundColor: 0xE76B5ECC,
                        textColor: 0xFFFFFFFF
                    )
                ],
                upcomingCount: 3,
                pastCount: 1,
                favoriteCount: 1
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        completion(CountdownEntry(date: .now, snapshot: WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load()
        let entry = CountdownEntry(date: .now, snapshot: snapshot)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct TimesMatterWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: CountdownEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                accessoryCircular.widgetURL(primaryURL)
            case .accessoryRectangular:
                accessoryRectangular.widgetURL(primaryURL)
            case .accessoryInline:
                accessoryInline.widgetURL(primaryURL)
            case .systemSmall:
                smallWidget.widgetURL(primaryURL)
            case .systemMedium:
                mediumWidget.widgetURL(primaryURL)
            default:
                // Large uses per-row Link destinations instead of a single widget URL.
                largeWidget
            }
        }
    }

    private var nextItem: WidgetCountdownItem? {
        entry.snapshot.items.first
    }

    private var primaryURL: URL {
        if let nextItem {
            AppDeepLink.countdownURL(id: nextItem.id)
        } else {
            AppDeepLink.homeURL
        }
    }

    private var accessoryCircular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Text(nextItem.map { "\($0.daysLeft())" } ?? "–")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("days")
                    .font(.system(size: 10, weight: .medium))
            }
        }
    }

    private var accessoryRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(nextItem?.title ?? String(localized: "No events"))
                .font(.headline)
                .lineLimit(1)
            Text(nextItem?.relativeLabel() ?? String(localized: "Add a countdown"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var accessoryInline: some View {
        if let nextItem {
            Text("\(nextItem.title): \(nextItem.relativeLabel())")
        } else {
            Text(String(localized: "Times Matter"))
        }
    }

    private var smallWidget: some View {
        ZStack {
            if let item = nextItem {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color(rgba: item.textColor))
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    Text("\(item.daysLeft())")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(rgba: item.textColor))
                    Text(item.relativeLabel())
                        .font(.caption)
                        .foregroundStyle(Color(rgba: item.textColor).opacity(0.9))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(4)
            } else {
                emptyState
            }
        }
    }

    private var mediumWidget: some View {
        ZStack {
            if entry.snapshot.items.isEmpty {
                emptyState
            } else {
                HStack(spacing: 12) {
                    if let item = nextItem {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(String(localized: "Next up"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(rgba: item.textColor).opacity(0.85))
                            Text(item.title)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Color(rgba: item.textColor))
                                .lineLimit(2)
                            Text(item.relativeLabel())
                                .font(.subheadline)
                                .foregroundStyle(Color(rgba: item.textColor).opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    VStack(alignment: .trailing, spacing: 6) {
                        metric(value: "\(entry.snapshot.upcomingCount)", label: String(localized: "Upcoming"))
                        metric(value: "\(entry.snapshot.favoriteCount)", label: String(localized: "Favorites"))
                    }
                }
                .padding(4)
            }
        }
    }

    private var largeWidget: some View {
        ZStack {
            if entry.snapshot.items.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(String(localized: "Upcoming"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color(rgba: nextItem?.textColor ?? 0xFFFFFFFF))
                    ForEach(entry.snapshot.items.prefix(4)) { item in
                        Link(destination: AppDeepLink.countdownURL(id: item.id)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color(rgba: item.textColor))
                                        .lineLimit(1)
                                    Text(item.relativeLabel())
                                        .font(.caption)
                                        .foregroundStyle(Color(rgba: item.textColor).opacity(0.85))
                                }
                                Spacer()
                                Text("\(item.daysLeft())")
                                    .font(.title2.weight(.bold).monospacedDigit())
                                    .foregroundStyle(Color(rgba: item.textColor))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(4)
            }
        }
    }

    private func metric(value: String, label: String) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(Color(rgba: nextItem?.textColor ?? 0xFFFFFFFF))
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color(rgba: nextItem?.textColor ?? 0xFFFFFFFF).opacity(0.85))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.title2)
            Text(String(localized: "Add a countdown"))
                .font(.subheadline.weight(.semibold))
            Text(String(localized: "Open Times Matter to get started"))
                .font(.caption2)
                .multilineTextAlignment(.center)
                .opacity(0.85)
        }
        .foregroundStyle(.white)
        .padding()
    }
}

struct TimesMatterWidget: Widget {
    let kind = "TimesMatterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountdownProvider()) { entry in
            TimesMatterWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    let color = Color(rgba: entry.snapshot.items.first?.backgroundColor ?? 0xE76B5ECC)
                    LinearGradient(
                        colors: [color, color.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName(String(localized: "Countdowns"))
        .description(String(localized: "See your next events at a glance."))
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

private extension Color {
    init(rgba: Int) {
        let a = Double((rgba >> 24) & 0xFF) / 255.0
        let r = Double((rgba >> 16) & 0xFF) / 255.0
        let g = Double((rgba >> 8) & 0xFF) / 255.0
        let b = Double(rgba & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a == 0 ? 1 : a)
    }
}
