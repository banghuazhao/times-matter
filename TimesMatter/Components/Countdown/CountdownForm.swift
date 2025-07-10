//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import SwiftUI
import Dependencies
import SwiftNavigation

@Observable
@MainActor
class CountdownFormModel: HashableObject {
    var countdown: Countdown.Draft
    
    var displayMock: Countdown {
        countdown.mock
    }
    
    let isEdit: Bool
    
    @CasePathable
    enum Route {
        case showCompactTimeFormatInfo
    }
    var route: Route?
    
    
    init(countdown: Countdown.Draft) {
        self.countdown = countdown
        isEdit = countdown.id != nil
    }
    
    func onTapSave() async {
        
    }
    
    func onTapEventGallery() {
        
    }
}

struct CountdownFormView: View {
    @State var model: CountdownFormModel
    @State private var showingTimeFormatPopover = false
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
                        
                                                 // Compact Time Unit Field
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
                        Task {
                            await model.onTapSave()
                        }
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
