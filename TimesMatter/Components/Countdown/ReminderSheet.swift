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
    @State private var audioPlayer: AVAudioPlayer?

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
                        withAnimation(.easeInOut(duration: 0.2)) {
                            stopSound()
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
                        .foregroundColor(themeManager.current.textPrimary)
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
                // System default sound at the top
                ForEach(systemSounds, id: \.self) { sound in
                    SoundOptionRow(
                        fileName: sound,
                        isSelected: reminder.soundName == sound,
                        onTap: {
                            stopSound()
                            reminder.soundName = sound
                            // No preview for system default
                        }
                    )
                }
                // Custom mp3s
                ForEach(musicFiles, id: \.self) { file in
                    SoundOptionRow(
                        fileName: file.replacingOccurrences(of: ".mp3", with: ""),
                        isSelected: reminder.soundName == file,
                        onTap: {
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
        Button(action: onTap) {
            Text(type.displayName)
                .font(AppFont.caption)
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
