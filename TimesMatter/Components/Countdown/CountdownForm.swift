//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import SwiftUI
import Dependencies
import SwiftNavigation
import SharingGRDB
import EasyToast

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
                 .presentationDetents([.medium])
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
    
    private let unitTypes: [RepeatType] = [.daily, .weekly, .monthly, .yearly]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Custom Repeat")
                .font(.title2)
                .padding(.top, 24)
            HStack(spacing: 0) {
                Picker("Interval", selection: $repeatTime) {
                    ForEach(1...999, id: \.self) { i in
                        if i == 1 {
                            Text("Every").tag(i)
                        } else {
                            Text("Every \(i)").tag(i)
                        }
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: 100)
                
                Picker("Unit", selection: $repeatType) {
                    ForEach(unitTypes, id: \.self) { type in
                        Text(repeatTime == 1 ? type.singleRepeatTimeName : type.multipleRepeatTimeName).tag(type)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: 120)
            }
            .frame(height: 180)
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
