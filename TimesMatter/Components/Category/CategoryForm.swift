//
// Created by Banghua Zhao on 11/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import EasyToast
import SharingGRDB
import SwiftUI
import SwiftUINavigation

@Observable
@MainActor
class CategoryFormModel: HashableObject {
    @ObservationIgnored
    @FetchAll(Category.all, animation: .default) var allCategories

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database
    @ObservationIgnored
    @Dependency(\.themeManager) var themeManager

    var selectedCategory: Category.ID?
    let onSelect: (Category?) -> Void

    var isEditing = false

    var newCategory = Category.Draft()

    init(selectedCategory: Category.ID?, onSelect: @escaping (Category?) -> Void) {
        self.selectedCategory = selectedCategory
        self.onSelect = onSelect
    }

    func onTapAddCategory() {
        guard !newCategory.title.isEmpty else { return }
        withErrorReporting {
            try database.write { db in
                try Category
                    .insert { newCategory }
                    .execute(db)
            }
            newCategory = Category.Draft()
        }
    }

    func onTapDeleteCategory(_ category: Category) {
        withErrorReporting {
            try database.write { db in
                try Category
                    .delete(category)
                    .execute(db)
            }
            if category.id == selectedCategory {
                selectedCategory = nil
            }
        }
    }

    // Add update method for category title
    func onUpdateCategory(_ category: Category, newTitle: String) {
        guard !newTitle.isEmpty, newTitle != category.title else { return }
        withErrorReporting {
            try database.write { db in
                var updated = category
                updated.title = newTitle
                try Category.update(updated).execute(db)
            }
        }
    }
}

struct CategoryFormView: View {
    @State var model: CategoryFormModel
    @Dependency(\.themeManager) var themeManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if !model.isEditing {
                        Button {
                            model.onSelect(nil)
                            dismiss()
                        } label: {
                            HStack {
                                Text("📅 All")
                                Spacer()
                                if model.selectedCategory == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(themeManager.current.primaryColor)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    ForEach(model.allCategories) { category in
                        if model.isEditing {
                            HStack {
                                TextField(
                                    "⏱️ Enter New Category",
                                    text: Binding(
                                        get: { category.title },
                                        set: { model.onUpdateCategory(category, newTitle: $0) }
                                    )
                                )
                                Spacer()
                                Button(role: .destructive) {
                                    model.onTapDeleteCategory(category)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        } else {
                            Button {
                                model.onSelect(category)
                            } label: {
                                HStack {
                                    Text(category.title)
                                    Spacer()
                                    if category.id == model.selectedCategory {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(themeManager.current.primaryColor)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    model.onTapDeleteCategory(category)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    HStack {
                        // Title input
                        TextField("⏱️ Enter New Category", text: $model.newCategory.title)
                        Spacer()
                        Button {
                            model.onTapAddCategory()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.appRect)
                    }
                } footer: {
                    if model.allCategories.count > 0 {
                        Text("Note: When a category is deleted, all countdowns in that category will be moved to '📅 All' category.")
                            .font(AppFont.footnote)
                            .foregroundColor(themeManager.current.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.appRect)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(model.isEditing ? "Done" : "Edit") {
                        withAnimation {
                            model.isEditing.toggle()
                        }
                    }
                    .buttonStyle(.appRect)
                }
            }
        }
    }
}

#Preview {
    CategoryFormView(
        model: CategoryFormModel(selectedCategory: nil, onSelect: { _ in })
    )
}
