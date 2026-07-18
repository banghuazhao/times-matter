//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SwiftUI

/// Compact “?” control that presents a short plain-language explanation.
struct InfoTipButton: View {
    let title: String
    let message: String

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
        .accessibilityLabel(String(localized: "About \(title)"))
        .popover(isPresented: $isPresented) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(title)
                    .font(AppFont.headline)
                Text(message)
                    .font(AppFont.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: 280, alignment: .leading)
            .presentationCompactAdaptation(.popover)
        }
    }
}

enum FeatureTips {
    static let `repeat` = (
        String(localized: "Repeat"),
        String(localized: "How often this event comes back. Choose No Repeat for one-time dates, or Daily / Weekly / Monthly / Yearly so the next occurrence updates automatically.")
    )

    static let reminder = (
        String(localized: "Reminder"),
        String(localized: "A notification that alerts you before or when the event happens. Tap to choose how often it notifies you, how early, and which sound to use.")
    )

    static let reminderType = (
        String(localized: "Reminder Type"),
        String(localized: "How often the notification fires. Only Once alerts you for the next event. Every Day / Week / Month / Year keeps reminding on that schedule. No Reminder turns alerts off.")
    )

    static let reminderTime = (
        String(localized: "Reminder Time"),
        String(localized: "How early you want to be notified—right at the event time, or minutes/days before so you can prepare.")
    )
}
