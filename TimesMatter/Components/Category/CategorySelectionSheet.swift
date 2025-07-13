//
// Created by Banghua Zhao on 11/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import SwiftUI
import SharingGRDB
import Dependencies

struct CategorySelectionSheet: View {
    @FetchAll(Category.all) var categories
    @State var selectedCategory: Category.ID?
    let onSelect: (Category?) -> Void
    
    @Dependency(\.themeManager) var themeManager
    
    var body: some View {
        List {
            // 'All' option
            Button {
                Haptics.shared.vibrateIfEnabled()
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
            // MARK: - Reusable Context Menu Modifier
            
            // Category options
            ForEach(categories) { category in
                Button {
                    Haptics.shared.vibrateIfEnabled()
                    selectedCategory = category.id
                    onSelect(category)
                } label: {
                    HStack {
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
