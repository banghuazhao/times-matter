//
// Created by Banghua Zhao on 13/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import AVFoundation
import Dependencies
import SwiftUI

struct ReminderSheet: View {
    @Binding var reminder: CountdownReminder
    @State private var selectedTab = 0
    @Dependency(\.themeManager) var themeManager
    @Dependency(\.purchaseManager) var purchaseManager
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showPurchaseSheet = false

    private var isPremium: Bool {
        purchaseManager.isPremiumUserPurchased
    }

    // Find all mp3 files in the bundle (regardless of folder)
    private var musicFiles: [String] {
        guard let resourcePath = Bundle.main.resourcePath else { return [] }
        let fm = FileManager.default
        let allFiles = (try? fm.contentsOfDirectory(atPath: resourcePath)) ?? []
        return allFiles.filter { $0.hasSuffix(".mp3") }
    }

    private let systemSounds: [String] = ["Default"]

    private let reminderTypeColumns = [
        GridItem(.adaptive(minimum: 90, maximum: 140)),
    ]

    private let reminderTimeColumns = [
        GridItem(.adaptive(minimum: 90, maximum: 140)),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Custom segmented control
            HStack(spacing: 0) {
                ForEach([0, 1], id: \.self) { tab in
                    Button(action: {
                        Haptics.shared.vibrateIfEnabled()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            stopSound()
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(tab == 0 ? "Reminder" : "Sound")
                                .font(AppFont.subheadlineSemibold)
                                .foregroundStyle(selectedTab == tab ? themeManager.current.primaryColor : themeManager.current.textSecondary)

                            Rectangle()
                                .fill(selectedTab == tab ? themeManager.current.primaryColor : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, AppSpacing.medium)

            Divider()
                .padding(.top, AppSpacing.medium)

            // Content
            if selectedTab == 0 {
                reminderTabView
            } else {
                soundTabView
            }
        }
        .padding(.top, AppSpacing.medium)
        .background(themeManager.current.background)
    }

    private var reminderTabView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                // Reminder Type Section
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Text("Reminder Type")
                        .font(AppFont.headline)
                        .foregroundStyle(themeManager.current.textPrimary)
                        .padding(.horizontal, AppSpacing.medium)

                    LazyVGrid(columns: reminderTypeColumns, spacing: AppSpacing.small) {
                        ForEach(ReminderType.allCases, id: \.self) { type in
                            ReminderTypeCard(
                                type: type,
                                isSelected: reminder.type == type,
                                onTap: {
                                    reminder.type = type
                                }
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
                            .foregroundStyle(themeManager.current.textPrimary)
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
                if !isPremium {
                    Button {
                        showPurchaseSheet = true
                    } label: {
                        Label(
                            String(localized: "Custom sounds are a Premium feature"),
                            systemImage: "crown.fill"
                        )
                        .font(AppFont.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppSpacing.medium)
                        .background(themeManager.current.primaryColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
                    }
                    .buttonStyle(.plain)
                }

                // System default sound at the top
                ForEach(systemSounds, id: \.self) { sound in
                    SoundOptionRow(
                        fileName: sound,
                        isSelected: reminder.soundName == sound,
                        isLocked: false,
                        onTap: {
                            stopSound()
                            reminder.soundName = sound
                        }
                    )
                }
                // Custom mp3s
                ForEach(musicFiles, id: \.self) { file in
                    SoundOptionRow(
                        fileName: file.replacingOccurrences(of: ".mp3", with: ""),
                        isSelected: reminder.soundName == file,
                        isLocked: !isPremium,
                        onTap: {
                            guard isPremium else {
                                showPurchaseSheet = true
                                return
                            }
                            stopSound()
                            reminder.soundName = file
                            playSound(named: file)
                        }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.medium)
        }
        .sheet(isPresented: $showPurchaseSheet) {
            PurchaseSheet()
        }
    }

    private func playSound(named file: String) {
        stopSound()
        guard let url = Bundle.main.url(forResource: file.replacingOccurrences(of: ".mp3", with: ""), withExtension: "mp3") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }

    private func stopSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}

// MARK: - Reminder Type Card

struct ReminderTypeCard: View {
    let type: ReminderType
    let isSelected: Bool
    let onTap: () -> Void
    @Dependency(\.themeManager) var themeManager

    var body: some View {
        Button(action: { 
            Haptics.shared.vibrateIfEnabled()
            onTap() 
        }) {
            Text(type.displayName)
                .font(AppFont.caption)
                .foregroundStyle(isSelected ? .white : themeManager.current.primaryColor)
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
        Button(action: { 
            Haptics.shared.vibrateIfEnabled()
            onTap() 
        }) {
            Text(time.displayName)
                .font(AppFont.caption)
                .foregroundStyle(isSelected ? .white : themeManager.current.primaryColor)
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
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sound Option Row

struct SoundOptionRow: View {
    let fileName: String
    let isSelected: Bool
    var isLocked: Bool = false
    let onTap: () -> Void
    @Dependency(\.themeManager) var themeManager

    var body: some View {
        Button(action: { 
            Haptics.shared.vibrateIfEnabled()
            onTap() 
        }) {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: isLocked ? "lock.fill" : "speaker.wave.2")
                    .font(.title3)
                    .foregroundStyle(isSelected ? themeManager.current.primaryColor : themeManager.current.textSecondary)
                    .frame(width: 24)
                    .accessibilityHidden(true)

                Text(fileName)
                    .font(AppFont.body)
                    .foregroundStyle(themeManager.current.textPrimary)

                Spacer()

                if isLocked {
                    Text(String(localized: "Premium"))
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(themeManager.current.primaryColor)
                        .accessibilityLabel(String(localized: "Selected"))
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
        .accessibilityLabel(isLocked ? String(localized: "\(fileName), Premium") : fileName)
    }
}

#Preview {
    ReminderSheet(
        reminder: .constant(CountdownReminder())
    )
}
