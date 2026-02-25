//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SharingGRDB
import SwiftUI
import SwiftUINavigation
import WidgetKit

@Observable
@MainActor
class CountdownListModel {
    @ObservationIgnored
    @FetchAll(Countdown.all, animation: .default) var allCountdowns

    @ObservationIgnored
    @FetchAll(Category.all, animation: .default) var allCategories

    @ObservationIgnored
    @Shared(.appStorage("selectedCategory")) var selectedCategory: Category.ID?

    @ObservationIgnored
    @Shared(.appStorage("isFirstLaunch")) var isFirstLaunch = true
    
    var searchText: String = ""
    
    @ObservationIgnored
    @Shared(.appStorage("showArchivedCountdowns")) var showArchivedCountdowns: Bool = false

    // MARK: Filter & Order State

    enum OrderType: String, CaseIterable, Identifiable {
        case `default`, futureToPast, pastToFuture
        var id: String { rawValue }
        var label: String {
            switch self {
            case .default: return String(localized: "Default")
            case .futureToPast: return String(localized: "Date (Future → Past)")
            case .pastToFuture: return String(localized: "Date (Past → Future)")
            }
        }
    }

    enum FilterOption: String, CaseIterable, Identifiable {
        case all, favorites, inThePast, inTheFuture
        var id: String { rawValue }
        var label: String {
            switch self {
            case .all: return String(localized: "All")
            case .favorites: return String(localized: "Favorites")
            case .inThePast: return String(localized: "In the Past")
            case .inTheFuture: return String(localized: "In the Future")
            }
        }
    }

    @ObservationIgnored
    @Shared(.appStorage("countdownOrderType")) var orderType: OrderType = .default
    @ObservationIgnored
    @Shared(.appStorage("countdownFilterOption")) var filterOption: FilterOption = .all

    @ObservationIgnored
    @Dependency(\.timerService) var timerService

    var countdowns: [Countdown] {
        var countdowns = allCountdowns
        if let selectedCategory {
            countdowns = countdowns.filter { $0.categoryID == selectedCategory }
        }
        
        if !showArchivedCountdowns {
            countdowns = countdowns.filter { !$0.isArchived }
        }
        
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty {
            countdowns = countdowns.filter { $0.title.localizedCaseInsensitiveContains(trimmedQuery) }
        }
        
        switch filterOption {
        case .all:
            break
        case .favorites:
            countdowns = countdowns.filter { $0.isFavorite }
        case .inThePast:
            countdowns = countdowns.filter { ($0.nextOccurrence ?? $0.date) < Date() }
        case .inTheFuture:
            countdowns = countdowns.filter { ($0.nextOccurrence ?? $0.date) >= Date() }
        }
        countdowns.sort {
            switch orderType {
            case .default:
                let now = timerService.currentTime
                let lhsTime = ($0.nextOccurrence ?? $0.date).timeIntervalSince(now)
                let rhsTime = ($1.nextOccurrence ?? $1.date).timeIntervalSince(now)
                // Future first (X left), sorted soonest to furthest; then past (X ago), sorted soonest to furthest
                if lhsTime >= 0 && rhsTime < 0 {
                    return true // lhs is in future, rhs is in past
                } else if lhsTime < 0 && rhsTime >= 0 {
                    return false // lhs is in past, rhs is in future
                } else if lhsTime >= 0 && rhsTime >= 0 {
                    // Both in future: sort ascending (soonest first)
                    return lhsTime < rhsTime
                } else {
                    // Both in past: sort ascending (most recent past first)
                    return lhsTime > rhsTime // -1 > -5 (closer to now is greater)
                }
            case .pastToFuture:
                return ($0.nextOccurrence ?? $0.date) < ($1.nextOccurrence ?? $1.date)
            case .futureToPast:
                return ($0.nextOccurrence ?? $0.date) > ($1.nextOccurrence ?? $1.date)
            }
        }
        return countdowns
    }

    @CasePathable
    enum Route {
        case countdownForm(CountdownFormModel)
        case countdownDetail(CountdownDetailModel)
        case selectCategory
        case showDeleteConfirmation(Countdown)
    }

    var route: Route?

    func onTapCountDown(_ countdown: Countdown) {
        route = .countdownDetail(
            CountdownDetailModel(countdown: countdown) { [weak self] in
                guard let self else { return }
                route = nil
            }
        )
    }

    func onTapAddCountDown() {
        route = .countdownForm(
            CountdownFormModel(
                countdown: Countdown.Draft()
            ) { [weak self] _ in
                guard let self else { return }
                route = nil
                Task { @MainActor in self.updateWidgetData() }
            }
        )
    }

    func onTapSelectCategory() {
        route = .selectCategory
    }

    func onSelectCategory(_ category: Category?) {
        withAnimation {
            $selectedCategory.withLock {
                $0 = category?.id
            }
        }
        Task {
            route = nil
        }
    }

    func onSelectOrder(_ order: OrderType) {
        withAnimation {
            $orderType.withLock { $0 = order }
        }
    }

    func onSelectFilter(_ option: FilterOption) {
        withAnimation {
            $filterOption.withLock { $0 = option }
        }
    }

    func onToggleShowArchived() {
        withAnimation {
            $showArchivedCountdowns.withLock { $0.toggle() }
        }
    }

    // MARK: Context Menu Actions

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    func onEditCountdown(_ countdown: Countdown) {
        route = .countdownForm(
            CountdownFormModel(
                countdown: Countdown.Draft(countdown)
            ) { [weak self] _ in
                guard let self else { return }
                route = nil
                Task { @MainActor in self.updateWidgetData() }
            }
        )
    }

    func onToggleFavorite(_ countdown: Countdown) {
        withErrorReporting {
            var newCountdown = countdown
            newCountdown.isFavorite.toggle()
            try database.write { db in
                try Countdown
                    .update(newCountdown)
                    .execute(db)
            }
        }
    }

    func onToggleArchived(_ countdown: Countdown) {
        withErrorReporting {
            var newCountdown = countdown
            newCountdown.isArchived.toggle()
            try database.write { db in
                try Countdown
                    .update(newCountdown)
                    .execute(db)
            }
            
            if newCountdown.isArchived {
                ReminderNotificationManager.shared.removeNotification(for: newCountdown)
            } else {
                ReminderNotificationManager.shared.removeNotification(for: newCountdown)
                ReminderNotificationManager.shared.scheduleNotification(for: newCountdown)
            }
        }
    }
    
    func onTapDelete(_ countdown: Countdown) {
        route = .showDeleteConfirmation(countdown)
    }

    func onDeleteCountdown(_ countdown: Countdown) {
        withErrorReporting {
            try database.write { db in
                try Countdown
                    .delete(countdown)
                    .execute(db)
            }

            ReminderNotificationManager.shared.removeNotification(for: countdown)
            Task { @MainActor in updateWidgetData() }
        }
    }

    func scheduleRemindersForFirstLaunch() {
        if isFirstLaunch {
            for countdown in countdowns {
                ReminderNotificationManager.shared.removeNotification(for: countdown)
                ReminderNotificationManager.shared.scheduleNotification(for: countdown)
            }
            $isFirstLaunch.withLock {
                $0 = false
            }
        }
    }

    /// Upcoming countdowns for widget: non-archived, future only, sorted by next occurrence (soonest first), max 5.
    private var widgetUpcomingCountdowns: [Countdown] {
        let now = timerService.currentTime
        var list = allCountdowns.filter { !$0.isArchived }
        list = list.filter { ($0.nextOccurrence ?? $0.date) >= now }
        list.sort { ($0.nextOccurrence ?? $0.date) < ($1.nextOccurrence ?? $1.date) }
        return Array(list.prefix(5))
    }

    /// Writes current upcoming countdowns to App Group and reloads widget timeline.
    func updateWidgetData() {
        let now = timerService.currentTime
        let items: [WidgetCountdownItem] = widgetUpcomingCountdowns.map { c in
            let target = c.nextOccurrence ?? c.date
            let time = c.calculateRelativeTime(currentTime: now)
            return WidgetCountdownItem(
                title: c.title,
                targetDate: target.timeIntervalSince1970,
                number: time.number,
                label: time.label,
                backgroundColor: c.backgroundColor,
                textColor: c.textColor
            )
        }
        WidgetDataManager.save(items)
        WidgetCenter.shared.reloadTimelines(ofKind: "CountdownWidget")
    }
}

struct CountdownEmptyStateView: View {
    var onAdd: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.secondary)
            Text("No Countdowns Yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Tap the + button to add your first countdown!")
                .font(.body)
                .foregroundColor(.secondary)
            Button(action: onAdd) {
                Label("Add Countdown", systemImage: "plus")
            }
            .buttonStyle(.appRect)
        }
        .padding(.horizontal, AppSpacing.large)
        .padding(.top, AppSpacing.large)
    }
}

struct CountdownListView: View {
    @State var model = CountdownListModel()
    @Dependency(\.themeManager) var themeManager

    var body: some View {
        NavigationStack {
            mainNavigationContent
        }
    }

    @ViewBuilder
    private var mainNavigationContent: some View {
        ScrollView {
            countdownListContent
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(ThemeManager.shared.current.background)
        .searchable(text: $model.searchText, prompt: Text("Search"))
        .task {
            model.scheduleRemindersForFirstLaunch()
            model.updateWidgetData()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                filterMenu
            }
            ToolbarItem(placement: .principal) {
                categoryButton
            }
            ToolbarItem(placement: .topBarTrailing) {
                addButton
            }
        }
        .sheet(item: $model.route.countdownForm, id: \.self) { model in
            CountdownFormView(model: model)
        }
        .navigationDestination(item: $model.route.countdownDetail) { model in
            CountdownDetailView(model: model)
        }
        .sheet(isPresented: Binding($model.route.selectCategory)) {
            CategorySelectionSheet(
                selectedCategory: model.selectedCategory,
                onSelect: { category in
                    model.onSelectCategory(category)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert(
            item: $model.route.showDeleteConfirmation,
            title: { countdown in
                Text(String(localized: "Delete ‘\(countdown.truncatedTitle)’?"))
            },
            actions: { countdown in
                Button("Delete", role: .destructive) {
                    Haptics.shared.vibrateIfEnabled()
                    model.onDeleteCountdown(countdown)
                }
                Button("Cancel", role: .cancel) {}
            },
            message: { countdown in
                Text(String(localized: "This will permanently delete ‘\(countdown.truncatedTitle)’. This action cannot be undone. Are you sure you want to proceed?"))
            }
        )
    }

    private var filterMenu: some View {
        Menu {
            Section("Filter By") {
                ForEach(CountdownListModel.FilterOption.allCases) { option in
                    Button(action: {
                        Haptics.shared.vibrateIfEnabled()
                        model.onSelectFilter(option)
                    }) {
                        HStack {
                            Text(option.label)
                            if option == model.filterOption {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            Divider()
            Section("Sort By") {
                ForEach(CountdownListModel.OrderType.allCases) { order in
                    Button(action: {
                        Haptics.shared.vibrateIfEnabled()
                        model.onSelectOrder(order)
                    }) {
                        HStack {
                            Text(order.label)
                            if order == model.orderType {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            Divider()
            Section("Archived") {
                Button(action: {
                    Haptics.shared.vibrateIfEnabled()
                    model.onToggleShowArchived()
                }) {
                    HStack {
                        Text("Show Archived")
                        if model.showArchivedCountdowns {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(
                systemName: model.filterOption != .all || model.orderType != .default || model.showArchivedCountdowns ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle"
            )
            .font(AppFont.headline)
            .frame(width: 38, height: 38)
            .background(themeManager.current.primaryColor.opacity(0.1))
            .foregroundColor(themeManager.current.primaryColor)
            .clipShape(Circle())
        }
    }

    private var categoryButton: some View {
        Button(action: {
            Haptics.shared.vibrateIfEnabled()
            model.onTapSelectCategory()
        }) {
            if let selected = model.allCategories.first(where: { $0.id == model.selectedCategory }) {
                Text(selected.title)
            } else {
                Text("📅 All")
            }
        }
        .buttonStyle(.appRect)
    }

    private var addButton: some View {
        Button(action: {
            Haptics.shared.vibrateIfEnabled()
            model.onTapAddCountDown()
        }) {
            Image(systemName: "plus")
        }
        .buttonStyle(.appCircular)
    }

    @ViewBuilder
    private var countdownListContent: some View {
        VStack(spacing: 16) {
            if model.countdowns.isEmpty {
                CountdownEmptyStateView {
                    Haptics.shared.vibrateIfEnabled()
                    model.onTapAddCountDown()
                }
            } else if model.orderType == .default {
                upcomingAndPastSections
            } else {
                flatCountdownList
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppSpacing.medium)
        .padding(.bottom, AppSpacing.medium)
    }

    @ViewBuilder
    private var upcomingAndPastSections: some View {
        let now = model.timerService.currentTime
        let futureCountdowns = model.countdowns.filter { ($0.nextOccurrence ?? $0.date) >= now }
        let pastCountdowns = model.countdowns.filter { ($0.nextOccurrence ?? $0.date) < now }
        if !futureCountdowns.isEmpty {
            countdownSection(title: "Upcoming", countdowns: futureCountdowns)
        }
        if !pastCountdowns.isEmpty {
            countdownSection(title: "Past", countdowns: pastCountdowns)
        }
    }

    private func countdownSection(title: String, countdowns: [Countdown]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.headline)
                .padding(.leading, 4)
            ForEach(countdowns) { countdown in
                countdownRow(countdown)
            }
        }
    }

    @ViewBuilder
    private var flatCountdownList: some View {
        ForEach(model.countdowns) { countdown in
            countdownRow(countdown)
        }
    }

    private func countdownRow(_ countdown: Countdown) -> some View {
        CountdownRow(countdown: countdown)
            .onTapGesture {
                Haptics.shared.vibrateIfEnabled()
                model.onTapCountDown(countdown)
            }
            .countdownContextMenu(
                countdown: countdown,
                onEdit: { model.onEditCountdown(countdown) },
                onToggleFavorite: { model.onToggleFavorite(countdown) },
                onToggleArchived: { model.onToggleArchived(countdown) },
                onDelete: { model.onTapDelete(countdown) }
            )
    }
}

// MARK: - Reusable Context Menu Modifier

struct CountdownContextMenu: ViewModifier {
    let countdown: Countdown
    let onEdit: () -> Void
    let onToggleFavorite: () -> Void
    let onToggleArchived: () -> Void
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        content.contextMenu {
            Button(action: {
                Haptics.shared.vibrateIfEnabled()
                onEdit()
            }) {
                Label("Edit", systemImage: "pencil")
            }

            Button(action: {
                Haptics.shared.vibrateIfEnabled()
                onToggleFavorite()
            }) {
                Label(
                    countdown.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: countdown.isFavorite ? "heart.slash" : "heart"
                )
            }

            Button(action: {
                Haptics.shared.vibrateIfEnabled()
                onToggleArchived()
            }) {
                Label(
                    countdown.isArchived ? "Unarchive" : "Archive",
                    systemImage: countdown.isArchived ? "archivebox.fill" : "archivebox"
                )
            }

            Divider()

            Button(role: .destructive, action: {
                Haptics.shared.vibrateIfEnabled()
                onDelete()
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

extension View {
    func countdownContextMenu(
        countdown: Countdown,
        onEdit: @escaping () -> Void,
        onToggleFavorite: @escaping () -> Void,
        onToggleArchived: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        modifier(CountdownContextMenu(
            countdown: countdown,
            onEdit: onEdit,
            onToggleFavorite: onToggleFavorite,
            onToggleArchived: onToggleArchived,
            onDelete: onDelete
        ))
    }
}
