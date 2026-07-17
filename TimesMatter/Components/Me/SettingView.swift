//
//  SettingView.swift
//  TimesMatter
//
//  Created by Lulin Yang on 2025/7/11.
//

import Dependencies
import SwiftUI

struct SettingView: View {
    @AppStorage("buttonSoundEnabled") private var buttonSoundEnabled: Bool = true
    @AppStorage("vibrateEnabled") private var vibrateEnabled: Bool = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    @Dependency(\.themeManager) var themeManager

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                settingsSection(title: String(localized: "Feedback")) {
                    Toggle(isOn: $vibrateEnabled) {
                        Text(String(localized: "Vibrate"))
                            .font(AppFont.body)
                            .foregroundStyle(themeManager.current.textPrimary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: themeManager.current.primaryColor))
                    .accessibilityHint(String(localized: "Plays haptic feedback on taps"))

                    Toggle(isOn: $buttonSoundEnabled) {
                        Text(String(localized: "Button Sounds"))
                            .font(AppFont.body)
                            .foregroundStyle(themeManager.current.textPrimary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: themeManager.current.primaryColor))
                    .accessibilityHint(String(localized: "Plays a soft tap sound on key actions"))
                }
                settingsSection(title: String(localized: "Appearance")) {
                    Toggle(isOn: $darkModeEnabled) {
                        Text(String(localized: "Dark Mode"))
                            .font(AppFont.body)
                            .foregroundStyle(themeManager.current.textPrimary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: themeManager.current.primaryColor))
                }
            }
            .padding()
        }
        .background(themeManager.current.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
        .onChange(of: darkModeEnabled) { _, newValue in
            themeManager.updateTheme(darkMode: newValue)
        }
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(title)
                .appSectionHeader(theme: themeManager.current)
            VStack(spacing: AppSpacing.small) {
                content()
            }
            .padding()
            .background(themeManager.current.card)
            .clipShape(.rect(cornerRadius: AppCornerRadius.card))
            .shadow(color: AppShadow.card.color, radius: AppShadow.card.radius, x: AppShadow.card.x, y: AppShadow.card.y)
        }
    }
}
