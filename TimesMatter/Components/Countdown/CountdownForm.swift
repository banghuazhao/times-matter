//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import SwiftUI
import Dependencies
import SwiftNavigation
import SharingGRDB
import EasyToast
import PhotosUI

@Observable
@MainActor
class CountdownFormModel: HashableObject {
    var countdown: Countdown.Draft
    
    @ObservationIgnored
    @FetchAll(Category.all, animation: .default) var allCategories
    
    @ObservationIgnored
    @Dependency(\.appRatingService) var appRatingService
    
    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database
    
    var displayMock: Countdown {
        countdown.mock
    }
    
    let isEdit: Bool
    let onSave: ((Countdown) -> Void)?
    
    @CasePathable
    enum Route {
        case showCompactTimeFormatInfo
        case selectCategory
        case showingCustomRepeatSheet
        case showingBackgroundSheet
    }
    var route: Route?
    
    var showTitleEmptyToast = false
    
    init(countdown: Countdown.Draft, onSave: ((Countdown) -> Void)? = nil) {
        self.countdown = countdown
        self.onSave = onSave
        isEdit = countdown.id != nil
    }
    
    func onTapSave() {
        guard !countdown.title.isEmpty else {
            showTitleEmptyToast = true
            return
        }
        
        withErrorReporting {
            let updatedCountDown = try database.write { [countdown] db in
                try Countdown
                    .upsert { countdown }
                    .returning { $0 }
                    .fetchOne(db)
            }
            
            guard let updatedCountDown else { return }
            appRatingService.incrementPrepareTriggerCount()
            
            onSave?(updatedCountDown)
        }
    }
    
    func onTapEventGallery() {
        
    }
    
    func onTapSelectCategory() {
        route = .selectCategory
    }
    
    func onSelectCategory(_ category: Category?) {
        countdown.categoryID = category?.id
        Task {
            route = nil
        }
    }
    
    func showChangeBackgroundSheet() {
        route = .showingBackgroundSheet
    }
}

struct CountdownFormView: View {
    @State var model: CountdownFormModel
    @State private var showingTimeFormatPopover = false
    @Dependency(\.themeManager) var themeManager
    
    @Environment(\.dismiss) var dismiss
    
    // Computed properties to simplify complex expressions
    private var isCustomRepeatTime: Bool {
        model.countdown.mock.isCustomRepeatTime
    }
    
    private var primaryColor: Color {
        themeManager.current.primaryColor
    }
    
    private var textPrimaryColor: Color {
        themeManager.current.textPrimary
    }
    
    private var secondaryGrayColor: Color {
        themeManager.current.secondaryGray
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    CountdownRow(countdown: model.displayMock)
                        .onTapGesture {
                            model.showChangeBackgroundSheet()
                        }
                    
                    // Form Section
                    VStack(spacing: AppSpacing.smallMedium) {
                        // Title Field
                        HStack(spacing: AppSpacing.small) {
                           
                            TextField("Enter event title", text: $model.countdown.title)
                                .font(AppFont.subheadlineSemibold)
                                .foregroundColor(textPrimaryColor)
                            
                            Button {
                                model.onTapEventGallery()
                            } label: {
                                Text("Gallery")
                            }
                            .buttonStyle(.appRect)
                        }
                        
                        Divider()
                        
                        HStack(spacing: AppSpacing.small) {
                            DatePicker(
                                "Event Time",
                                selection: $model.countdown.date,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .tint(primaryColor)
                        }
                        .font(AppFont.subheadlineSemibold)
                        
                        Divider()
                        
                        // Repeat Type Selection
                        VStack(alignment: .leading, spacing: AppSpacing.smallMedium) {
                            Text("Repeat")
                                .font(AppFont.subheadlineSemibold)
                                .foregroundColor(textPrimaryColor)
                                
                            LazyVGrid(
                                columns: [
                                    GridItem(.adaptive(minimum: 90, maximum: 140), spacing: AppSpacing.small)
                                ],
                                alignment: .leading,
                                spacing: AppSpacing.small
                            ) {
                                ForEach(RepeatType.allCasesToChoose, id: \.self) { type in
                                    RepeatTypeButton(
                                        type: type,
                                        isSelected: !isCustomRepeatTime && model.countdown.repeatType == type,
                                        primaryColor: primaryColor
                                    ) {
                                        model.countdown.repeatType = type
                                        model.countdown.repeatTime = 1
                                    }
                                }
                                
                                CustomRepeatButton(
                                    isSelected: isCustomRepeatTime,
                                    primaryColor: primaryColor
                                ) {
                                    if model.countdown.repeatType == .nonRepeating {
                                        model.countdown.repeatType = .daily
                                    }
                                    model.route = .showingCustomRepeatSheet
                                }
                            }
                        }
                       
                        Divider()
                        
                        // Category Selection
                        HStack(spacing: AppSpacing.smallMedium) {
                            Text("Category")
                                .font(AppFont.subheadlineSemibold)
                                .foregroundColor(textPrimaryColor)
                            
                            Spacer()
                            
                            Button {
                                model.onTapSelectCategory()
                            } label: {
                                HStack {
                                    if let selectedCategory = model.allCategories.first(where: { $0.id == model.countdown.categoryID }) {
                                        Text(selectedCategory.title)
                                    } else {
                                        Text("📅 All")
                                    }
                                }
                            }
                            .buttonStyle(.appRect)
                        }
                        
                        Divider()
                        
                        // Background & Text Color Row
                        HStack(spacing: AppSpacing.smallMedium) {
                            Text("Background & Text Color")
                                .font(AppFont.subheadlineSemibold)
                                .foregroundColor(textPrimaryColor)
                            Spacer()
                            Button {
                                model.showChangeBackgroundSheet()
                            } label: {
                                Text("Change")
                            }
                            .buttonStyle(.appRect)
                        }
                        .sheet(
                            isPresented: Binding($model.route.showingBackgroundSheet)
                        ) {
                            ChangeBackgroundSheet(
                                model: ChangeBackgroundSheetModel(
                                    countdown: model.countdown
                                ) { newCountdown in
                                    model.countdown = newCountdown
                                }
                            )
                        }

                        Divider()
                        
                        VStack(alignment: .leading, spacing: AppSpacing.smallMedium) {
                             HStack {
                                 Text("Compact Time Format")
                                     .font(AppFont.subheadlineSemibold)
                                     .foregroundColor(textPrimaryColor)
                                 
                                 Button {
                                     model.route = .showCompactTimeFormatInfo
                                 } label: {
                                     Image(systemName: "questionmark.circle")
                                         .foregroundColor(secondaryGrayColor)
                                         .font(AppFont.subheadline)
                                 }
                                 .popover(isPresented: Binding($model.route.showCompactTimeFormatInfo)) {
                                     CompactTimeFormatPopover()
                                 }
                             }
                             
                             Picker("Time Unit", selection: $model.countdown.compactTimeUnit) {
                                 ForEach(CompactTimeUnit.allCases, id: \.self) { unit in
                                     Text(unit.displayName)
                                         .tag(unit)
                                 }
                             }
                             .pickerStyle(.segmented)
                             .tint(primaryColor)
                         }
                     }
                     .appCardStyle()
                 }
                 .padding()
                
                BannerView()
                    .frame(height: 50)
             }
             .appBackground(theme: themeManager.current)
             .toolbar {
                 ToolbarItem(placement: .topBarLeading) {
                     Button {
                         dismiss()
                     } label: {
                         Text("Dismiss")
                     }
                     .buttonStyle(.appRect)
                 }
                 ToolbarItem(placement: .topBarTrailing) {
                     Button {
                         model.onTapSave()
                     } label: {
                         Text(model.isEdit ? String(localized: "Update") : String(localized: "Save"))
                     }.buttonStyle(.appRect)
                 }
             }
             .navigationTitle(
                 model.isEdit
                 ? String(localized: "Edit Countdown")
                 : String(localized: "New Countdown")
             )
             .scrollDismissesKeyboard(.immediately)
             .navigationBarTitleDisplayMode(.inline)
             .sheet(isPresented: Binding($model.route.selectCategory)) {
                 CategoryFormView(
                    model: CategoryFormModel(
                        selectedCategory: model.countdown.categoryID,
                        onSelect: { category in
                            model.onSelectCategory(category)
                        }
                    )
                 )
                 .presentationDetents([.fraction(0.7), .large])
                 .presentationDragIndicator(.visible)
             }
             .sheet(isPresented: Binding($model.route.showingCustomRepeatSheet)) {
                 CustomRepeatSheet(
                     repeatType: $model.countdown.repeatType,
                     repeatTime: $model.countdown.repeatTime
                 )
                 .presentationDetents([.medium, .large])
             }
             .easyToast(isPresented: $model.showTitleEmptyToast, message: String(localized:"Event title is empty"))
        }
    }
}

// MARK: - Helper Views

struct RepeatTypeButton: View {
    let type: RepeatType
    let isSelected: Bool
    let primaryColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(type.displayName)
                .font(AppFont.subheadline)
                .padding(.horizontal, AppSpacing.smallMedium)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(isSelected ? primaryColor : .clear)
                .foregroundColor(isSelected ? .white : primaryColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(primaryColor, lineWidth: 1)
                )
                .cornerRadius(8)
        }
    }
}

struct CustomRepeatButton: View {
    let isSelected: Bool
    let primaryColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Custom")
                .font(AppFont.subheadline)
                .padding(.horizontal, AppSpacing.smallMedium)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(isSelected ? primaryColor : .clear)
                .foregroundColor(isSelected ? .white : primaryColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(primaryColor, lineWidth: 1)
                )
                .cornerRadius(8)
        }
    }
}

// Custom Repeat Sheet
struct CustomRepeatSheet: View {
    @Binding var repeatType: RepeatType
    @Binding var repeatTime: Int
    @Environment(\.dismiss) var dismiss
    @Dependency(\.themeManager) var themeManager
    
    private let unitTypes: [RepeatType] = [.daily, .weekly, .monthly, .yearly]
    
    private var primaryColor: Color {
        themeManager.current.primaryColor
    }
    
    private var textPrimaryColor: Color {
        themeManager.current.textPrimary
    }
    
    private var backgroundColor: Color {
        themeManager.current.background
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Custom Repeat")
                        .font(AppFont.title2)
                        .foregroundColor(textPrimaryColor)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Content
                VStack(spacing: 20) {
                    // Picker Container
                    VStack(spacing: 16) {
                        HStack(spacing: 0) {
                            // Interval Picker
                            VStack(spacing: 8) {
                                Text("Interval")
                                    .font(AppFont.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                                
                                Picker("Interval", selection: $repeatTime) {
                                    ForEach(1...99, id: \.self) { i in
                                        Text("\(i)")
                                            .font(AppFont.title3)
                                            .tag(i)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(maxWidth: 100, maxHeight: 180)
                                .clipped()
                            }
                            
                            // Unit Picker
                            VStack(spacing: 8) {
                                Text("Unit")
                                    .font(AppFont.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                                
                                Picker("Unit", selection: $repeatType) {
                                    ForEach(unitTypes, id: \.self) { type in
                                        Text(repeatTime == 1 ? type.singleRepeatTimeName : type.multipleRepeatTimeName)
                                            .font(AppFont.title3)
                                            .tag(type)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(maxWidth: 150, maxHeight: 180)
                                .clipped()
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(backgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    
                    // Preview
                    if repeatType != .nonRepeating {
                        VStack(spacing: 8) {
                            Text("Preview")
                                .font(AppFont.caption)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            
                            
                            Text(repeatSummary)
                                .font(AppFont.subheadline)
                                .foregroundColor(textPrimaryColor)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 20)
            }
            .background(backgroundColor)
            .navigationBarHidden(true)
        }
    }
    
    var repeatSummary: String {
        if repeatTime == 1 {
            "This event will repeat every \(repeatType.singleRepeatTimeName.lowercased())"
        } else {
            "This event will repeat every \(repeatTime) \(repeatType.multipleRepeatTimeName.lowercased())"
        }
    }
}


#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
    }

    CountdownFormView(
        model: CountdownFormModel(
            countdown: CountdownStore.testSecond
        )
    )
}
