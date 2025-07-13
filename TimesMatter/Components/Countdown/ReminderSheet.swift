//
// Created by Banghua Zhao on 13/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import Dependencies

struct ReminderSheet: View {
    @Binding var reminder: CountdownReminder
    @State private var selectedTab = 0
    @Dependency(\.themeManager) var themeManager
    
    private var musicFiles: [String] {
        let fm = FileManager.default
        if let musicURL = Bundle.main.resourceURL?.appendingPathComponent("Music"),
           let files = try? fm.contentsOfDirectory(atPath: musicURL.path) {
            return files.filter { $0.hasSuffix(".mp3") }
        }
        return []
    }
    
    private let reminderTypeColumns = [
        GridItem(.adaptive(minimum: 90, maximum: 140))
    ]
    
    private let reminderTimeColumns = [
        GridItem(.adaptive(minimum: 90, maximum: 140))
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom segmented control
                HStack(spacing: 0) {
                    ForEach([0, 1], id: \.self) { tab in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                        }) {
                            VStack(spacing: 4) {
                                Text(tab == 0 ? "Reminder" : "Sound")
                                    .font(AppFont.subheadlineSemibold)
                                    .foregroundColor(selectedTab == tab ? themeManager.current.primaryColor : themeManager.current.textSecondary)
                                
                                Rectangle()
                                    .fill(selectedTab == tab ? themeManager.current.primaryColor : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, AppSpacing.medium)
                .padding(.top, AppSpacing.medium)
                
                Divider()
                    .padding(.top, AppSpacing.medium)
                
                // Content
                if selectedTab == 0 {
                    reminderTabView
                } else {
                    soundTabView
                }
            }
            .navigationTitle("Reminder Settings")
            .navigationBarTitleDisplayMode(.inline)
            .background(themeManager.current.background)
        }
    }
    
    private var reminderTabView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                // Reminder Type Section
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Text("Reminder Type")
                        .font(AppFont.headline)
                        .foregroundColor(themeManager.current.textPrimary)
                        .padding(.horizontal, AppSpacing.medium)
                    
                    LazyVGrid(columns: reminderTypeColumns, spacing: AppSpacing.small) {
                        ForEach(ReminderType.allCases, id: \.self) { type in
                            ReminderTypeCard(
                                type: type,
                                isSelected: reminder.type == type,
                                onTap: { reminder.type = type }
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.medium)
                }
                
                // Reminder Time Section (only show if reminder is enabled)
                if reminder.type != .noReminder {
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        Text("Reminder Time")
                            .font(AppFont.headline)
                            .foregroundColor(themeManager.current.textPrimary)
                            .padding(.horizontal, AppSpacing.medium)
                        
                        LazyVGrid(columns: reminderTimeColumns, spacing: AppSpacing.small) {
                            ForEach(ReminderTime.allCases, id: \.self) { time in
                                ReminderTimeCard(
                                    time: time,
                                    isSelected: reminder.time == time,
                                    onTap: { reminder.time = time }
                                )
                            }
                        }
                        .padding(.horizontal, AppSpacing.medium)
                    }
                }
            }
            .padding(.vertical, AppSpacing.medium)
        }
    }
    
    private var soundTabView: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.small) {
                ForEach(musicFiles, id: \.self) { file in
                    SoundOptionRow(
                        fileName: file.replacingOccurrences(of: ".mp3", with: ""),
                        isSelected: reminder.soundName == file,
                        onTap: { reminder.soundName = file }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.medium)
        }
    }
}

// MARK: - Reminder Type Card
struct ReminderTypeCard: View {
    let type: ReminderType
    let isSelected: Bool
    let onTap: () -> Void
    @Dependency(\.themeManager) var themeManager
    
    var body: some View {
        Button(action: onTap) {
            Text(type.displayName)
                .font(AppFont.caption)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? .white : themeManager.current.primaryColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.button)
                        .fill(isSelected ? themeManager.current.primaryColor : themeManager.current.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppCornerRadius.button)
                                .stroke(themeManager.current.primaryColor)
                        )
                )
                .shadow(color: isSelected ? themeManager.current.primaryColor.opacity(0.3) : Color.clear, radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Reminder Time Card
struct ReminderTimeCard: View {
    let time: ReminderTime
    let isSelected: Bool
    let onTap: () -> Void
    @Dependency(\.themeManager) var themeManager
    
    var body: some View {
        Button(action: onTap) {
            Text(time.displayName)
                .font(AppFont.caption)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? .white : themeManager.current.primaryColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.button)
                        .fill(isSelected ? themeManager.current.primaryColor : themeManager.current.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppCornerRadius.button)
                                .stroke(themeManager.current.primaryColor)
                        )
                )
                .shadow(color: isSelected ? themeManager.current.primaryColor.opacity(0.3) : Color.clear, radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sound Option Row
struct SoundOptionRow: View {
    let fileName: String
    let isSelected: Bool
    let onTap: () -> Void
    @Dependency(\.themeManager) var themeManager
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: "speaker.wave.2")
                    .font(.title3)
                    .foregroundColor(isSelected ? themeManager.current.primaryColor : themeManager.current.textSecondary)
                    .frame(width: 24)
                
                Text(fileName)
                    .font(AppFont.body)
                    .foregroundColor(themeManager.current.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(themeManager.current.primaryColor)
                }
            }
            .padding(AppSpacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .fill(themeManager.current.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.card)
                            .stroke(isSelected ? themeManager.current.primaryColor : themeManager.current.secondaryGray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


#Preview {
    ReminderSheet(
        reminder: .constant(CountdownReminder())
    )
}
