//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SharingGRDB
import SwiftUI
import SwiftUINavigation

@Observable
@MainActor
class CountdownListModel {
    @ObservationIgnored
    @FetchAll(Countdown.all, animation: .default) var allCountdowns

    @ObservationIgnored
    @FetchAll(Category.all, animation: .default) var allCategories

    @ObservationIgnored
    @Shared(.appStorage("selectedCategory")) var selectedCategory: Category.ID?

    // MARK: Filter & Order State

    enum OrderType: String, CaseIterable, Identifiable {
        case `default`, futureToPast, pastToFuture
        var id: String { rawValue }
        var label: String {
            switch self {
            case .default: return "Default"
            case .futureToPast: return "Date (Future → Past)"
            case .pastToFuture: return "Date (Past → Future)"
            }
        }
    }

    enum FilterOption: String, CaseIterable, Identifiable {
        case all, favorites, inThePast, inTheFuture
        var id: String { rawValue }
        var label: String {
            switch self {
            case .all: return "All"
            case .favorites: return "Favorites"
            case .inThePast: return "In the Past"
            case .inTheFuture: return "In the Future"
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
            CountdownDetailModel(countdown: countdown)
        )
    }

    func onTapAddCountDown() {
        route = .countdownForm(
            CountdownFormModel(
                countdown: Countdown.Draft()
            ) { [weak self] _ in
                guard let self else { return }
                route = nil
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

    func onDeleteCountdown(_ countdown: Countdown) {
        withErrorReporting {
            try database.write { db in
                try Countdown
                    .delete(countdown)
                    .execute(db)
            }
        }
    }
}

struct CountdownListView: View {
    @State var model = CountdownListModel()
    @Dependency(\.themeManager) var themeManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if model.orderType == .default {
                        let now = model.timerService.currentTime
                        let futureCountdowns = model.countdowns.filter { ($0.nextOccurrence ?? $0.date) >= now }
                        let pastCountdowns = model.countdowns.filter { ($0.nextOccurrence ?? $0.date) < now }
                        if !futureCountdowns.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Upcoming")
                                    .font(AppFont.headline)
                                    .padding(.leading, 4)
                                ForEach(futureCountdowns) { countdown in
                                    CountdownRow(countdown: countdown)
                                        .onTapGesture {
                                            model.onTapCountDown(countdown)
                                        }
                                        .countdownContextMenu(
                                            countdown: countdown,
                                            onEdit: { model.onEditCountdown(countdown) },
                                            onToggleFavorite: { model.onToggleFavorite(countdown) },
                                            onDelete: { model.onDeleteCountdown(countdown) }
                                        )
                                }
                            }
                        }
                        if !pastCountdowns.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Past")
                                    .font(AppFont.headline)
                                    .padding(.leading, 4)
                                ForEach(pastCountdowns) { countdown in
                                    CountdownRow(countdown: countdown)
                                        .onTapGesture {
                                            model.onTapCountDown(countdown)
                                        }
                                        .countdownContextMenu(
                                            countdown: countdown,
                                            onEdit: { model.onEditCountdown(countdown) },
                                            onToggleFavorite: { model.onToggleFavorite(countdown) },
                                            onDelete: { model.onDeleteCountdown(countdown) }
                                        )
                                }
                            }
                        }
                    } else {
                        ForEach(model.countdowns) { countdown in
                            CountdownRow(countdown: countdown)
                                .onTapGesture {
                                    model.onTapCountDown(countdown)
                                }
                                .countdownContextMenu(
                                    countdown: countdown,
                                    onEdit: { model.onEditCountdown(countdown) },
                                    onToggleFavorite: { model.onToggleFavorite(countdown) },
                                    onDelete: { model.onDeleteCountdown(countdown) }
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .appBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        // Filter options
                        Section("Filter By") {
                            ForEach(CountdownListModel.FilterOption.allCases) { option in
                                Button(action: { model.onSelectFilter(option) }) {
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
                        // Order options
                        Section("Sort By") {
                            ForEach(CountdownListModel.OrderType.allCases) { order in
                                Button(action: { model.onSelectOrder(order) }) {
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
                    } label: {
                        Image(
                            systemName: model.filterOption != .all || model.orderType != .default ? "line.3.horizontal.decrease.circle.fill" :
                                "line.3.horizontal.decrease.circle"
                        )
                        .font(AppFont.headline)
                        .frame(width: 38, height: 38)
                        .background(
                            themeManager.current.primaryColor.opacity(0.1)
                        )
                        .foregroundColor(themeManager.current.primaryColor)
                        .clipShape(Circle())
                    }
                }
                ToolbarItem(placement: .principal) {
                    Button(action: model.onTapSelectCategory) {
                        if let selected = model.allCategories.first(where: { $0.id == model.selectedCategory }) {
                            Text(selected.title)
                        } else {
                            Text("📅 All")
                        }
                    }
                    .buttonStyle(.appRect)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: model.onTapAddCountDown) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.appCircular)
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
                        model.onDeleteCountdown(countdown)
                    }
                    Button("Cancel", role: .cancel) {}
                },
                message: { countdown in
                    Text(String(localized: "This will permanently delete the countdown ‘\(countdown.truncatedTitle)’. This action cannot be undone. Are you sure you want to proceed?"))
                }
            )
        }
    }
}


// MARK: - Reusable Context Menu Modifier

struct CountdownContextMenu: ViewModifier {
    let countdown: Countdown
    let onEdit: () -> Void
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        content.contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }

            Button(action: onToggleFavorite) {
                Label(
                    countdown.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: countdown.isFavorite ? "heart.slash" : "heart"
                )
            }

            Divider()

            Button(role: .destructive, action: onDelete) {
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
        onDelete: @escaping () -> Void
    ) -> some View {
        modifier(CountdownContextMenu(
            countdown: countdown,
            onEdit: onEdit,
            onToggleFavorite: onToggleFavorite,
            onDelete: onDelete
        ))
    }
}
