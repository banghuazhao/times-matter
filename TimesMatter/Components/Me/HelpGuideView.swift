//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SwiftUI

struct HelpGuideView: View {
    @Dependency(\.themeManager) private var themeManager

    private let sections: [HelpSection] = [
        HelpSection(
            title: String(localized: "Getting started"),
            icon: "sparkles",
            bullets: [
                String(localized: "Create a countdown with + or pick a template from the Events Gallery."),
                String(localized: "Set a reminder so you get notified before the day arrives."),
                String(localized: "Favorite important events for quicker filtering."),
            ]
        ),
        HelpSection(
            title: String(localized: "Best practices"),
            icon: "star.fill",
            bullets: [
                String(localized: "Use categories (Birthday, Work, Holiday…) so Today insights stay useful."),
                String(localized: "Archive past one-off events instead of deleting—keeps history without clutter."),
                String(localized: "For yearly events, set Repeat to Yearly so next year’s date updates automatically."),
                String(localized: "Export a backup from Me → Backup before switching phones."),
            ]
        ),
        HelpSection(
            title: String(localized: "Customize your look"),
            icon: "paintbrush.fill",
            bullets: [
                String(localized: "Open a countdown → Edit → Background to change image, video, music, colors, and layout."),
                String(localized: "Layouts include Top, Upper Middle, Middle, Lower Middle, and Bottom."),
                String(localized: "Video backgrounds loop the first few seconds for a living wallpaper feel."),
                String(localized: "Ambient music plays when you open a countdown (mute from the toolbar)."),
            ]
        ),
        HelpSection(
            title: String(localized: "Widgets"),
            icon: "rectangle.on.rectangle",
            bullets: [
                String(localized: "Touch and hold the Home Screen → tap Edit → Add Widget → search “Times Matter”."),
                String(localized: "Choose Small, Medium, or Large. Lock Screen supports Circular, Rectangular, and Inline."),
                String(localized: "Tap a widget to open that countdown in the app."),
                String(localized: "Widgets refresh when you add or edit events—open the app once after big changes."),
            ]
        ),
        HelpSection(
            title: String(localized: "Today tab"),
            icon: "sun.max.fill",
            bullets: [
                String(localized: "See what’s next, events this week, and a stable category breakdown."),
                String(localized: "Use Suggested to add famous dates and seasonal moments in one tap."),
            ]
        ),
        HelpSection(
            title: String(localized: "Premium"),
            icon: "crown.fill",
            bullets: [
                String(localized: "Free includes up to 5 active countdowns."),
                String(localized: "Premium unlocks unlimited countdowns, ad-free use, photo & video backgrounds, custom reminder sounds, exclusive themes, and premium share cards."),
            ]
        ),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                Text(String(localized: "How to use Times Matter"))
                    .font(AppFont.title2)
                Text(String(localized: "Tips for countdowns, widgets, customization, and backups."))
                    .font(AppFont.body)
                    .foregroundStyle(.secondary)

                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Label(section.title, systemImage: section.icon)
                            .font(AppFont.headline)
                            .foregroundStyle(themeManager.current.primaryColor)

                        ForEach(section.bullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                Text(bullet)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .font(AppFont.body)
                            .foregroundStyle(themeManager.current.textPrimary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(themeManager.current.card)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
                }
            }
            .padding()
        }
        .background(themeManager.current.background)
        .navigationTitle(String(localized: "How to Use"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HelpSection: Identifiable {
    var id: String { title }
    let title: String
    let icon: String
    let bullets: [String]
}

#Preview {
    NavigationStack {
        HelpGuideView()
    }
}
