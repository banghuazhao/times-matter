//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SQLiteData
import SwiftUI
import SwiftUINavigation

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

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    @CasePathable
    enum Route {
        case detail(CountdownDetailModel)
        case form(CountdownFormModel)
        case purchase
        case limitReached
    }

    var route: Route?

    var activeCountdowns: [Countdown] {
        allCountdowns.filter { !$0.isArchived }
    }

    var activeCountdownCount: Int {
        activeCountdowns.count
    }

    var nextUp: Countdown? {
        let now = timerService.currentTime
        return activeCountdowns
            .filter { ($0.nextOccurrence ?? $0.date) >= now }
            .sorted {
                let lhs = $0.nextOccurrence ?? $0.date
                let rhs = $1.nextOccurrence ?? $1.date
                if lhs != rhs { return lhs < rhs }
                return $0.id < $1.id
            }
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
            .sorted {
                let lhs = $0.nextOccurrence ?? $0.date
                let rhs = $1.nextOccurrence ?? $1.date
                if lhs != rhs { return lhs < rhs }
                return $0.id < $1.id
            }
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

    /// Stable category breakdown (count desc, then title asc) so the list doesn't reshuffle.
    var categoryBreakdown: [(title: String, count: Int)] {
        let grouped = Dictionary(grouping: activeCountdowns, by: \.categoryID)
        return grouped.map { id, items in
            let title = allCategories.first(where: { $0.id == id })?.title
                ?? String(localized: "Uncategorized")
            return (title, items.count)
        }
        .sorted {
            if $0.count != $1.count { return $0.count > $1.count }
            return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    var suggestedTemplates: [GalleryTemplate] {
        GalleryTemplate.todaySuggestions
    }

    func openCountdown(_ countdown: Countdown) {
        route = .detail(
            CountdownDetailModel(countdown: countdown) { [weak self] in
                self?.route = nil
            }
        )
    }

    func addTemplate(_ template: GalleryTemplate) {
        let isPremium = purchaseManager.isPremiumUserPurchased
        guard PremiumLimits.canCreateCountdown(activeCount: activeCountdownCount, isPremium: isPremium) else {
            route = .limitReached
            return
        }
        route = .form(
            CountdownFormModel(countdown: template.makeDraft()) { [weak self] _ in
                self?.route = nil
                WidgetDataExporter.export(countdowns: self?.allCountdowns ?? [])
            }
        )
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
                    suggestionsSection
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
            .navigationDestination(item: $model.route.detail) { detailModel in
                CountdownDetailView(model: detailModel)
            }
            .sheet(item: $model.route.form, id: \.self) { formModel in
                CountdownFormView(model: formModel)
            }
            .sheet(isPresented: Binding($model.route.purchase)) {
                PurchaseSheet()
            }
            .alert(
                String(localized: "Free limit reached"),
                isPresented: Binding($model.route.limitReached)
            ) {
                Button(String(localized: "Upgrade to Premium")) {
                    model.route = .purchase
                }
                Button(String(localized: "Not Now"), role: .cancel) {
                    model.route = nil
                }
            } message: {
                Text(String(localized: "Free accounts can track up to \(PremiumLimits.freeCountdownLimit) active countdowns."))
            }
        }
    }

    @ViewBuilder
    private var nextUpCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Next up"))
                .appSectionHeader(theme: themeManager.current)

            if let next = model.nextUp {
                Button {
                    Haptics.shared.vibrateIfEnabled()
                    model.openCountdown(next)
                } label: {
                    CountdownRow(countdown: next)
                }
                .buttonStyle(.plain)
                .accessibilityHint(String(localized: "Opens countdown details"))
            } else {
                ContentUnavailableView(
                    String(localized: "Nothing upcoming"),
                    systemImage: "calendar",
                    description: Text(String(localized: "Try a suggested event below, or add your own countdown."))
                )
                .frame(maxWidth: .infinity)
                .padding()
                .background(themeManager.current.card)
                .clipShape(.rect(cornerRadius: AppCornerRadius.card))
            }
        }
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Suggested to add"))
                .appSectionHeader(theme: themeManager.current)

            Text(String(localized: "Famous dates and seasonal moments—tap to customize and save."))
                .font(AppFont.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.small) {
                    ForEach(model.suggestedTemplates) { template in
                        Button {
                            Haptics.shared.vibrateIfEnabled()
                            model.addTemplate(template)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(template.emoji)
                                    .font(.system(size: 28))
                                Text(template.title)
                                    .font(AppFont.subheadlineSemibold)
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                Text(template.season.title)
                                    .font(AppFont.caption)
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                            .padding(AppSpacing.medium)
                            .frame(width: 150, height: 120, alignment: .topLeading)
                            .background(
                                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                                    .fill(Color(rgba: template.backgroundColor))
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(String(localized: "Add \(template.title)"))
                    }
                }
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
                        Button {
                            Haptics.shared.vibrateIfEnabled()
                            model.openCountdown(countdown)
                        } label: {
                            CountdownRow(countdown: countdown)
                        }
                        .buttonStyle(.plain)
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

private extension Color {
    init(rgba: Int) {
        let a = Double((rgba >> 24) & 0xFF) / 255.0
        let r = Double((rgba >> 16) & 0xFF) / 255.0
        let g = Double((rgba >> 8) & 0xFF) / 255.0
        let b = Double(rgba & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a == 0 ? 1 : a)
    }
}

#Preview {
    InsightsView()
}
