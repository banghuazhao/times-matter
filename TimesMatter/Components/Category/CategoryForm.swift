//
// Created by Banghua Zhao on 11/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import SwiftUI
import SharingGRDB
import Dependencies
import SwiftUINavigation
import EasyToast

@Observable
@MainActor
class CategoryFormModel: HashableObject {
    @ObservationIgnored
    @FetchAll(Category.all, animation: .default) var allCategories
    
    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database
    @ObservationIgnored
    @Dependency(\.themeManager) var themeManager
    
    let selectedCategory: Category.ID?
    let onSelect: (Category?) -> Void
    
    // Inline editing state
    var editingCategory: Category.ID?
    
    var newCategory = Category.Draft()
    var newCategoryTitle = ""
    var newCategoryIcon = "📁"
    var isAddingNew = false
    
    var showDeleteSuccessToast = false
    var showTitleEmptyToast = false
    var showInvalidEmojiToast = false
    
    init(selectedCategory: Category.ID?, onSelect: @escaping (Category?) -> Void) {
        self.selectedCategory = selectedCategory
        self.onSelect = onSelect
    }
    
    func onTapAddCategory() {
        isAddingNew = true
        newCategoryTitle = ""
        newCategoryIcon = "📁"
    }
    
    func onTapEditCategory(_ category: Category) {
        editingCategory = category.id
        newCategoryTitle = category.title
        newCategoryIcon = category.icon
    }
    
    func onTapDeleteCategory(_ category: Category) {
        withErrorReporting {
            try database.write { db in
                try Category
                    .delete(category)
                    .execute(db)
            }
            showDeleteSuccessToast = true
        }
    }
    
    func onSaveCategory() {
        guard !newCategoryTitle.isEmpty else {
            showTitleEmptyToast = true
            return
        }
        
        // Validate emoji
        guard newCategoryIcon.isSingleEmoji else {
            showInvalidEmojiToast = true
            return
        }
        
        withErrorReporting {
            if isAddingNew {
                // Create new category
                let newCategory = Category.Draft(
                    title: newCategoryTitle,
                    icon: newCategoryIcon
                )
                
                try database.write { db in
                    try Category
                        .upsert { newCategory }
                        .execute(db)
                }
            } else if let editingId = editingCategory {
                // Update existing category
                let updatedCategory = Category.Draft(
                    id: editingId,
                    title: newCategoryTitle,
                    icon: newCategoryIcon
                )
                
                try database.write { db in
                    try Category
                        .upsert { updatedCategory }
                        .execute(db)
                }
            }
            
            // Reset editing state
            cancelEditing()
        }
    }
    
    func cancelEditing() {
        editingCategory = nil
        isAddingNew = false
        newCategoryTitle = ""
        newCategoryIcon = "📁"
    }
}

struct CategoryFormView: View {
    @State var model: CategoryFormModel
    @Dependency(\.themeManager) var themeManager
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // 'All' option
                Button {
                    model.onSelect(nil)
                    dismiss()
                } label: {
                    HStack {
                        Text("📅")
                        Text("All")
                        Spacer()
                        if model.selectedCategory == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(themeManager.current.primaryColor)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Category options
                ForEach(model.allCategories) { category in
                    if model.editingCategory == category.id {
                        // Editing mode
                        CategoryEditRow(
                            title: $model.newCategoryTitle,
                            icon: $model.newCategoryIcon,
                            onSave: { model.onSaveCategory() },
                            onCancel: { model.cancelEditing() }
                        )
                    } else {
                        // Normal display mode
                        Button {
                            model.onSelect(category)
                            dismiss()
                        } label: {
                            HStack {
                                Text(category.icon)
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
                        .contextMenu {
                            Button {
                                model.onTapEditCategory(category)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                model.onTapDeleteCategory(category)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                
                // Add new category row
                if model.isAddingNew {
                    CategoryEditRow(
                        title: $model.newCategoryTitle,
                        icon: $model.newCategoryIcon,
                        onSave: { model.onSaveCategory() },
                        onCancel: { model.cancelEditing() }
                    )
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.appRect)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if !model.isAddingNew && model.editingCategory == nil {
                        Button {
                            model.onTapAddCategory()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.appCircular)
                    }
                }
            }
            .easyToast(isPresented: $model.showDeleteSuccessToast, message: "Category deleted successfully")
            .easyToast(isPresented: $model.showTitleEmptyToast, message: "Category name is empty")
            .easyToast(isPresented: $model.showInvalidEmojiToast, message: "Please enter a valid emoji")
            .safeAreaInset(edge: .bottom) {
                if model.allCategories.count > 0 {
                    VStack(spacing: 8) {
                        Divider()
                        Text("Note: When a category is deleted, all countdowns in that category will be moved to 'All' category.")
                            .font(AppFont.caption)
                            .foregroundColor(themeManager.current.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }
                    .background(themeManager.current.background)
                }
            }
        }
    }
}

// MARK: - Category Edit Row
struct CategoryEditRow: View {
    @Binding var title: String
    @Binding var icon: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @Dependency(\.themeManager) var themeManager
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isIconFocused: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon and Title inputs
            HStack(spacing: 12) {
                // Icon input
                TextField("Icon", text: $icon)
                    .font(.system(size: 24))
                    .frame(width: 60, height: 44)
                    .background(themeManager.current.primaryColor.opacity(0.1))
                    .clipShape(Circle())
                    .multilineTextAlignment(.center)
                    .focused($isIconFocused)
                    .onChange(of: icon) { _, newValue in
                        // Only allow single emoji
                        if newValue.count > 1 {
                            icon = String(newValue.prefix(1))
                        }
                        if !newValue.isSingleEmoji {
                            icon = "📁"
                        }
                    }
                    .onTapGesture {
                        isIconFocused = true
                    }
                
                // Title input
                TextField("Category name", text: $title)
                    .font(AppFont.subheadlineSemibold)
                    .foregroundColor(themeManager.current.textPrimary)
                    .focused($isTitleFocused)
                
                Spacer()
            }
            
            // Action buttons
            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.appRect)
                
                Spacer()
                
                Button("Save", action: onSave)
                    .buttonStyle(.appRect)
                    .disabled(title.isEmpty)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            isTitleFocused = true
        }
    }
}

// MARK: - String Extension for Emoji Validation
extension String {
    var isSingleEmoji: Bool {
        count == 1 && containsEmoji
    }
    
    var containsEmoji: Bool {
        contains { $0.isEmoji }
    }
}

extension Character {
    var isEmoji: Bool {
        if let firstScalar = unicodeScalars.first, firstScalar.properties.isEmoji {
            return (firstScalar.value >= 0x238C || unicodeScalars.count > 1)
        }
        return false
    }
}

// MARK: - Legacy Support
struct CategorySelectionSheet_Legacy: View {
    @ObservationIgnored
    @FetchAll(Category.all, animation: .default) var allCategories
    
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
                .contentShape(Rectangle()) // Make the whole row tappable
            }
            .buttonStyle(.plain)

            // Category options
            ForEach(allCategories) { category in
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
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
