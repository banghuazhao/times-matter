//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SwiftUI

/// Compact “?” control that presents a short plain-language explanation.
/// Sizing follows `CompactTimeFormatPopover` so the popover grows with its content.
struct InfoTipButton: View {
    let tip: FeatureTip

    @State private var isPresented = false
    @Dependency(\.themeManager) private var themeManager

    var body: some View {
        Button {
            Haptics.shared.vibrateIfEnabled()
            isPresented = true
        } label: {
            Image(systemName: "questionmark.circle")
                .font(AppFont.subheadline)
                .foregroundStyle(themeManager.current.secondaryGray)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "About \(tip.title)"))
        .popover(isPresented: $isPresented) {
            FeatureTipPopover(tip: tip)
        }
    }
}

struct FeatureTipPopover: View {
    let tip: FeatureTip

    @Dependency(\.themeManager) private var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: tip.systemImage)
                    .font(.title2)
                    .foregroundStyle(themeManager.current.primaryColor)

                Text(tip.title)
                    .font(AppFont.headline)
                    .foregroundStyle(themeManager.current.textPrimary)
            }

            Text(tip.summary)
                .font(AppFont.subheadline)
                .foregroundStyle(themeManager.current.textSecondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            if !tip.points.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    ForEach(tip.points) { point in
                        tipPointRow(point)
                    }
                }
            }
        }
        // Fixed width + vertical fitting — same pattern that keeps Compact Time Format readable.
        .padding(AppSpacing.large)
        .frame(width: 300, alignment: .leading)
        .fixedSize(horizontal: true, vertical: true)
        .background(themeManager.current.card)
        .presentationCompactAdaptation(.popover)
    }

    private func tipPointRow(_ point: FeatureTip.Point) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            Image(systemName: point.systemImage)
                .font(.subheadline)
                .foregroundStyle(themeManager.current.primaryColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(point.title)
                    .font(AppFont.subheadlineSemibold)
                    .foregroundStyle(themeManager.current.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(point.detail)
                    .font(AppFont.caption)
                    .foregroundStyle(themeManager.current.textSecondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.small)
        .background(themeManager.current.secondaryGray.opacity(0.05))
        .clipShape(.rect(cornerRadius: AppCornerRadius.info))
    }
}

struct FeatureTip: Identifiable {
    struct Point: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let systemImage: String
    }

    let id = UUID()
    let title: String
    let summary: String
    let systemImage: String
    let points: [Point]
}

enum FeatureTips {
    static let `repeat` = FeatureTip(
        title: String(localized: "Repeat"),
        summary: String(localized: "How often this event comes back after the date you set."),
        systemImage: "arrow.triangle.2.circlepath",
        points: [
            .init(
                title: String(localized: "No Repeat"),
                detail: String(localized: "One-time date. The countdown ends after that day."),
                systemImage: "1.circle"
            ),
            .init(
                title: String(localized: "Daily / Weekly / Monthly / Yearly"),
                detail: String(localized: "The next occurrence updates automatically when the date passes."),
                systemImage: "calendar"
            ),
        ]
    )

    static let reminder = FeatureTip(
        title: String(localized: "Reminder"),
        summary: String(localized: "A notification that alerts you before or when the event happens."),
        systemImage: "bell.badge",
        points: [
            .init(
                title: String(localized: "What you can set"),
                detail: String(localized: "How often it notifies you, how early, and which sound to use."),
                systemImage: "slider.horizontal.3"
            ),
        ]
    )

    static let reminderType = FeatureTip(
        title: String(localized: "Reminder Type"),
        summary: String(localized: "How often the notification fires."),
        systemImage: "bell",
        points: [
            .init(
                title: String(localized: "Only Once"),
                detail: String(localized: "Alerts you for the next event only."),
                systemImage: "1.circle"
            ),
            .init(
                title: String(localized: "Every Day / Week / Month / Year"),
                detail: String(localized: "Keeps reminding on that schedule."),
                systemImage: "arrow.triangle.2.circlepath"
            ),
            .init(
                title: String(localized: "No Reminder"),
                detail: String(localized: "Turns alerts off for this event."),
                systemImage: "bell.slash"
            ),
        ]
    )

    static let reminderTime = FeatureTip(
        title: String(localized: "Reminder Time"),
        summary: String(localized: "How early you want to be notified."),
        systemImage: "clock",
        points: [
            .init(
                title: String(localized: "At Event Time"),
                detail: String(localized: "Notify you right when the event happens."),
                systemImage: "alarm"
            ),
            .init(
                title: String(localized: "Minutes or days early"),
                detail: String(localized: "Get a heads-up so you can prepare beforehand."),
                systemImage: "hourglass"
            ),
        ]
    )
}
