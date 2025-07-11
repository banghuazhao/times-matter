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
    @State private var showingCustomRepeatSheet = false
    @Dependency(\.themeManager) var themeManager
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    CountdownRow(
                        countdown: model.displayMock)
                    
                    // Form Section
                    VStack(spacing: AppSpacing.smallMedium) {
                        // Title Field
                        HStack(spacing: AppSpacing.small) {
                           
                            TextField("Enter event title", text: $model.countdown.title)
                                .font(AppFont.subheadlineSemibold)
                                .foregroundColor(themeManager.current.textPrimary)
                            
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
                            .tint(themeManager.current.primaryColor)
                        }
                        .font(AppFont.subheadlineSemibold)
                        
                        Divider()
                        
                        // Repeat Type Selection
                        VStack(alignment: .leading, spacing: AppSpacing.smallMedium) {
                            Text("Repeat")
                                .font(AppFont.subheadlineSemibold)
                                .foregroundColor(themeManager.current.textPrimary)
                                
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90, maximum: 140), spacing: AppSpacing.small)], alignment: .leading, spacing: AppSpacing.small) {
                                ForEach(RepeatType.allCasesToChoose, id: \ .self) { type in
                                    Button(action: {
                                        if type.isCustom {
                                            showingCustomRepeatSheet = true
                                        }
                                        model.countdown.repeatType = type
                                    }) {
                                        Text(type.displayName)
                                            .font(AppFont.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .frame(maxWidth: .infinity)
                                            .background(model.countdown.repeatType == type ? themeManager.current.primaryColor : .clear)
                                            .foregroundColor(model.countdown.repeatType == type ? .white : themeManager.current.primaryColor)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(themeManager.current.primaryColor, lineWidth: 1)
                                            )
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                       
                        Divider()
                        
                        // Category Selection
                        HStack(spacing: AppSpacing.smallMedium) {
                            Text("Category")
                                .font(AppFont.subheadlineSemibold)
                                .foregroundColor(themeManager.current.textPrimary)
                            
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
                                     .foregroundColor(themeManager.current.textPrimary)
                                 
                                 Button {
                                     model.route = .showCompactTimeFormatInfo
                                 } label: {
                                     Image(systemName: "questionmark.circle")
                                         .foregroundColor(themeManager.current.secondaryGray)
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
                             .tint(themeManager.current.primaryColor)
                         }
                     }
                     .appCardStyle()
                 }
                 .padding()
             }
             .appBackground(theme: themeManager.current)
            BannerView()
                .frame(height: 50)
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
             .sheet(isPresented: $showingCustomRepeatSheet) {
                 CustomRepeatSheet(
                     repeatType: $model.countdown.repeatType,
                     customInterval: $model.countdown.customInterval
                 )
             }
             .easyToast(isPresented: $model.showTitleEmptyToast, message: String(localized:"Event title is empty"))
        }
    }
}

// Custom Repeat Sheet
struct CustomRepeatSheet: View {
    @Binding var repeatType: RepeatType
    @Binding var customInterval: Int
    @Environment(\.dismiss) var dismiss
    @State private var selectedUnit: RepeatType = .customDays
    @State private var selectedInterval: Int = 1
    
    private let unitTypes: [RepeatType] = [.customDays, .customWeeks, .customMonths, .customYears]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Custom Repeat")
                .font(.title2)
                .padding(.top, 24)
            HStack(spacing: 0) {
                Picker("Interval", selection: $selectedInterval) {
                    ForEach(1...999, id: \.self) { i in
                        Text("\(i)").tag(i)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: 100)
                
                Picker("Unit", selection: $selectedUnit) {
                    ForEach(unitTypes, id: \.self) { type in
                        Text(type.unitSingular).tag(type)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: 120)
            }
            .frame(height: 180)
            
            Button("Done") {
                customInterval = selectedInterval
                repeatType = selectedUnit
                dismiss()
            }
            .buttonStyle(.appRect)
            .padding(.bottom, 24)
        }
        .onAppear {
            selectedInterval = customInterval
            selectedUnit = unitTypes.contains(repeatType) ? repeatType : .customDays
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
