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

    var countdowns: [Countdown] {
        var countdowns = allCountdowns
        
        if let selectedCategory {
            countdowns = countdowns.filter { $0.categoryID == selectedCategory }
        }

        countdowns.sort {
            ($0.nextOccurrence ?? Date()) > ($1.nextOccurrence ?? Date())
        }
        return countdowns
    }

    @CasePathable
    enum Route {
        case countdownForm(CountdownFormModel)
        case countdownDetail(CountdownDetailModel)
        case selectCategory
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
            )
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
}

struct CountdownListView: View {
    @State var model = CountdownListModel()

    @Dependency(\.themeManager) var themeManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(model.countdowns) { countdown in
                        CountdownRow(countdown: countdown)
                            .onTapGesture {
                                model.onTapCountDown(countdown)
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
            .appBackground()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button(action: model.onTapSelectCategory) {
                        if let selected = model.allCategories.first(where: { $0.id == model.selectedCategory }) {
                            HStack {
                                Text(selected.icon)
                                Text(selected.title)
                            }
                        } else {
                            HStack {
                                Text("📅")
                                Text("All")
                            }
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
                    categories: model.allCategories,
                    selectedCategory: model.selectedCategory,
                    onSelect: { category in
                        model.onSelectCategory(category)
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

struct CategorySelectionSheet: View {
    let categories: [Category]
    let selectedCategory: Category.ID?
    let onSelect: (Category?) -> Void
    
    @Dependency(\.themeManager) var themeManager

    var body: some View {
            List {
                // 'All' option
                Button {
                    onSelect(nil)
                } label: {
                    HStack {
                        Text("📅")
                        Text("All")
                        Spacer()
                        if selectedCategory == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(themeManager.current.primaryColor)
                        }
                    }
                }
                .clipped()
                .buttonStyle(.plain)

                // Category options
                ForEach(categories) { category in
                    Button {
                        onSelect(category)
                    } label: {
                        HStack {
                            Text(category.icon)
                            Text(category.title)
                            Spacer()
                            if category.id == selectedCategory {
                                Image(systemName: "checkmark")
                                    .foregroundColor(themeManager.current.primaryColor)
                            }
                        }
                        .clipped()
                    }
                    .buttonStyle(.plain)
                }
            }
    }
}
