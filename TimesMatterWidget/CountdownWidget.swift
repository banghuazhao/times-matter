//
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import WidgetKit

// MARK: - Timeline Provider

struct CountdownWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownWidgetEntry {
        CountdownWidgetEntry(date: Date(), items: WidgetDataManager.load())
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownWidgetEntry) -> Void) {
        let items = WidgetDataManager.load()
        completion(CountdownWidgetEntry(date: Date(), items: items))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownWidgetEntry>) -> Void) {
        let items = WidgetDataManager.load()
        let entry = CountdownWidgetEntry(date: Date(), items: items)
        // Refresh again in 15 minutes so "X minutes left" stays roughly accurate
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry

struct CountdownWidgetEntry: TimelineEntry {
    let date: Date
    let items: [WidgetCountdownItem]
}

// MARK: - Widget outer frame color (softer orange, lower saturation for a fresher look)

private let widgetBackgroundOrange = Color(red: 1.0, green: 0.82, blue: 0.62) // Softer peach-orange

// MARK: - Views

struct CountdownWidgetEntryView: View {
    var entry: CountdownWidgetProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            if entry.items.isEmpty {
                emptyView
            } else {
                switch family {
                case .systemSmall:
                    SmallWidgetView(item: entry.items[0])
                case .systemMedium:
                    MediumWidgetView(items: Array(entry.items.prefix(3)))
                default:
                    SmallWidgetView(item: entry.items[0])
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(8)
        .containerBackground(for: .widget) {
            widgetBackgroundOrange
        }
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.secondary.opacity(0.8))
            Text("No upcoming events")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SmallWidgetView: View {
    let item: WidgetCountdownItem

    var body: some View {
        let bg = desaturatedColor(fromHex: item.backgroundColor)
        let fg = readableTextColor(backgroundColorHex: item.backgroundColor, preferredTextColorHex: item.textColor, desaturatedBlend: 0.38)
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(fg)
                .shadow(color: .black.opacity(0.12), radius: 0.5, x: 0, y: 0.5)
                .lineLimit(2)
            Spacer(minLength: 0)
            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text(item.number)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(fg)
                    .shadow(color: .black.opacity(0.12), radius: 0.5, x: 0, y: 0.5)
                Text(item.label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(fg.opacity(0.88))
                    .shadow(color: .black.opacity(0.1), radius: 0.5, x: 0, y: 0.5)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(bg)
    }
}

struct MediumWidgetView: View {
    let items: [WidgetCountdownItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(items) { item in
                mediumWidgetRow(item: item)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func mediumWidgetRow(item: WidgetCountdownItem) -> some View {
        let bg = desaturatedColor(fromHex: item.backgroundColor)
        let fg = readableTextColor(backgroundColorHex: item.backgroundColor, preferredTextColorHex: item.textColor, desaturatedBlend: 0.38)
        return HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(fg)
                    .shadow(color: .black.opacity(0.12), radius: 0.5, x: 0, y: 0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("\(item.number) \(item.label)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(fg.opacity(0.88))
                    .shadow(color: .black.opacity(0.1), radius: 0.5, x: 0, y: 0.5)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bg.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private func colorFromHex(_ hex: Int) -> Color {
    let a = Double((hex >> 24) & 0xFF) / 255
    let r = Double((hex >> 16) & 0xFF) / 255
    let g = Double((hex >> 8) & 0xFF) / 255
    let b = Double(hex & 0xFF) / 255
    return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
}

/// Softer, lower-saturation version of the color (blend with white) for a fresher card look.
private func desaturatedColor(fromHex hex: Int, blendWithWhite amount: Double = 0.38) -> Color {
    let r = Double((hex >> 16) & 0xFF) / 255
    let g = Double((hex >> 8) & 0xFF) / 255
    let b = Double(hex & 0xFF) / 255
    let a = Double((hex >> 24) & 0xFF) / 255
    let nr = r + (1 - r) * amount
    let ng = g + (1 - g) * amount
    let nb = b + (1 - b) * amount
    return Color(.sRGB, red: nr, green: ng, blue: nb, opacity: a)
}

/// Relative luminance from sRGB components (0 = black, 1 = white). Used to pick readable text color.
private func luminanceFromSRGB(red r: Double, green g: Double, blue b: Double) -> Double {
    let rs = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4)
    let gs = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4)
    let bs = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4)
    return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs
}

private func luminance(hex: Int) -> Double {
    let r = Double((hex >> 16) & 0xFF) / 255
    let g = Double((hex >> 8) & 0xFF) / 255
    let b = Double(hex & 0xFF) / 255
    return luminanceFromSRGB(red: r, green: g, blue: b)
}

/// Luminance of the desaturated card background (same blend as desaturatedColor). Use this for widget card text contrast.
private func desaturatedLuminance(hex: Int, blendWithWhite amount: Double = 0.38) -> Double {
    let r = Double((hex >> 16) & 0xFF) / 255
    let g = Double((hex >> 8) & 0xFF) / 255
    let b = Double(hex & 0xFF) / 255
    let nr = r + (1 - r) * amount
    let ng = g + (1 - g) * amount
    let nb = b + (1 - b) * amount
    return luminanceFromSRGB(red: nr, green: ng, blue: nb)
}

/// Returns a text color that contrasts well with the background. When desaturatedBlend is set (widget cards), always use dark text so all events stay readable on light desaturated backgrounds.
private func readableTextColor(backgroundColorHex: Int, preferredTextColorHex: Int, desaturatedBlend: Double? = nil) -> Color {
    if desaturatedBlend != nil {
        return Color(white: 0.18)  // widget cards: always dark text for readability on any pastel background
    }
    let L = luminance(hex: backgroundColorHex)
    if L > 0.55 {
        return Color(white: 0.18)
    }
    return colorFromHex(preferredTextColorHex)
}

// MARK: - Widget Configuration

struct CountdownWidget: Widget {
    let kind: String = "CountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountdownWidgetProvider()) { entry in
            CountdownWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Countdown")
        .description("Shows your nearest upcoming event.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview("Small") {
    CountdownWidgetEntryView(
        entry: CountdownWidgetEntry(
            date: Date(),
            items: [
                WidgetCountdownItem(
                    title: "🎂 Birthday",
                    targetDate: Date().timeIntervalSince1970 + 86400 * 5,
                    number: "5",
                    label: "days left",
                    backgroundColor: 0xFF6B9DCC,
                    textColor: 0xFFFFFFFF
                )
            ]
        )
    )
    .previewContext(WidgetPreviewContext(family: .systemSmall))
}
