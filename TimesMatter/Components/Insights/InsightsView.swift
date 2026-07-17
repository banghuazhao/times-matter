//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SQLiteData
import SwiftUI

@Observable
@MainActor
final class InsightsViewModel {
    @ObservationIgnored
    @FetchAll(Countdown.all, animation: .default) var allCountdowns

    @ObservationIgnored
    @FetchAll(Category.all, animation: .default) var allCategories

    @ObservationIgnored
    @Dependency(\.timerService) var timerService

    @ObservationIgnored
    @Dependency(\.themeManager) var themeManager

    @ObservationIgnored
    @Dependency(\.purchaseManager) var purchaseManager

    var activeCountdowns: [Countdown] {
        allCountdowns.filter { !$0.isArchived }
    }

    var nextUp: Countdown? {
        let now = timerService.currentTime
        return activeCountdowns
            .filter { ($0.nextOccurrence ?? $0.date) >= now }
            .sorted { ($0.nextOccurrence ?? $0.date) < ($1.nextOccurrence ?? $1.date) }
            .first
    }

    var thisWeek: [Countdown] {
        let now = timerService.currentTime
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        return activeCountdowns
            .filter {
                let target = $0.nextOccurrence ?? $0.date
                return target >= now && target <= weekEnd
            }
            .sorted { ($0.nextOccurrence ?? $0.date) < ($1.nextOccurrence ?? $1.date) }
    }

    var favorites: [Countdown] {
        activeCountdowns.filter(\.isFavorite)
    }

    var upcomingCount: Int {
        let now = timerService.currentTime
        return activeCountdowns.filter { ($0.nextOccurrence ?? $0.date) >= now }.count
    }

    var pastCount: Int {
        let now = timerService.currentTime
        return activeCountdowns.filter { ($0.nextOccurrence ?? $0.date) < now }.count
    }

    var categoryBreakdown: [(title: String, count: Int)] {
        let grouped = Dictionary(grouping: activeCountdowns, by: \.categoryID)
        return grouped.compactMap { id, items in
            let title = allCategories.first(where: { $0.id == id })?.title ?? String(localized: "Uncategorized")
            return (title, items.count)
        }
        .sorted { $0.count > $1.count }
    }
}

struct InsightsView: View {
    @State private var model = InsightsViewModel()
    @Dependency(\.themeManager) private var themeManager
    @Dependency(\.purchaseManager) private var purchaseManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    nextUpCard
                    weekSection
                    statsRow
                    categoriesSection
                    tipCard

                    if !purchaseManager.isPremiumUserPurchased {
                        AdBannerView()
                    }
                }
                .padding(AppSpacing.medium)
            }
            .background(themeManager.current.background)
            .navigationTitle(String(localized: "Today"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var nextUpCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Next up"))
                .appSectionHeader(theme: themeManager.current)

            if let next = model.nextUp {
                CountdownRow(countdown: next)
                    .accessibilityLabel(Text("\(next.title), \(next.calculateRelativeTime(currentTime: model.timerService.currentTime).label)"))
            } else {
                ContentUnavailableView(
                    String(localized: "Nothing upcoming"),
                    systemImage: "calendar",
                    description: Text(String(localized: "Add a countdown to see what’s next."))
                )
                .frame(maxWidth: .infinity)
                .padding()
                .background(themeManager.current.card)
                .clipShape(.rect(cornerRadius: AppCornerRadius.card))
            }
        }
    }

    private var weekSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "This week"))
                .appSectionHeader(theme: themeManager.current)

            if model.thisWeek.isEmpty {
                Text(String(localized: "No events in the next 7 days."))
                    .font(AppFont.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(themeManager.current.card)
                    .clipShape(.rect(cornerRadius: AppCornerRadius.card))
            } else {
                VStack(spacing: AppSpacing.small) {
                    ForEach(model.thisWeek) { countdown in
                        CountdownRow(countdown: countdown)
                    }
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: AppSpacing.medium) {
            statCard(value: "\(model.upcomingCount)", label: String(localized: "Upcoming"), icon: "arrow.up.right")
            statCard(value: "\(model.pastCount)", label: String(localized: "Past"), icon: "clock.arrow.circlepath")
            statCard(value: "\(model.favorites.count)", label: String(localized: "Favorites"), icon: "heart.fill")
        }
        .accessibilityElement(children: .contain)
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: icon)
                .foregroundStyle(themeManager.current.primaryColor)
                .accessibilityHidden(true)
            Text(value)
                .font(AppFont.title2)
                .monospacedDigit()
            Text(label)
                .font(AppFont.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.medium)
        .background(themeManager.current.card)
        .clipShape(.rect(cornerRadius: AppCornerRadius.card))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "By category"))
                .appSectionHeader(theme: themeManager.current)

            if model.categoryBreakdown.isEmpty {
                Text(String(localized: "Categories will appear as you add events."))
                    .font(AppFont.body)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: AppSpacing.small) {
                    ForEach(model.categoryBreakdown, id: \.title) { item in
                        HStack {
                            Text(item.title)
                                .font(AppFont.body)
                            Spacer()
                            Text("\(item.count)")
                                .font(AppFont.headline)
                                .monospacedDigit()
                                .foregroundStyle(themeManager.current.primaryColor)
                        }
                        .padding(.horizontal, AppSpacing.medium)
                        .padding(.vertical, AppSpacing.smallMedium)
                        .background(themeManager.current.card)
                        .clipShape(.rect(cornerRadius: AppCornerRadius.button))
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Label(String(localized: "Pro tip"), systemImage: "lightbulb.fill")
                .font(AppFont.headline)
                .foregroundStyle(themeManager.current.primaryColor)
            Text(String(localized: "Add a Home Screen or Lock Screen widget to glance at your next countdown without opening the app."))
                .font(AppFont.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(themeManager.current.card)
        .clipShape(.rect(cornerRadius: AppCornerRadius.card))
    }
}

#Preview {
    InsightsView()
}
