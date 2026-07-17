//
//  ThemeColorView.swift
//  TimesMatter
//
//  Created by Lulin Yang on 2025/7/11.
//

import Dependencies
import SwiftUI

struct ThemeColorView: View {
    @Dependency(\.themeManager) var themeManager
    @Dependency(\.purchaseManager) var purchaseManager
    @State private var showPurchaseSheet = false

    private let themeColors: [ThemeColorOption] = [
        ThemeColorOption(themeColor: .default, color: Color(red: 0.914, green: 0.420, blue: 0.369), icon: "flame.fill"),
        ThemeColorOption(themeColor: .blue, color: Color(red: 0.0, green: 0.48, blue: 1.0), icon: "drop.fill"),
        ThemeColorOption(themeColor: .green, color: Color(red: 0.20, green: 0.78, blue: 0.35), icon: "leaf.fill"),
        ThemeColorOption(themeColor: .purple, color: Color(red: 0.58, green: 0.35, blue: 0.95), icon: "sparkles"),
        ThemeColorOption(themeColor: .pink, color: Color(red: 0.91, green: 0.30, blue: 0.58), icon: "heart.fill"),
        ThemeColorOption(themeColor: .orange, color: Color(red: 1.0, green: 0.58, blue: 0.0), icon: "sun.max.fill"),
    ]

    private var isPremium: Bool {
        purchaseManager.isPremiumUserPurchased
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                Text(String(localized: "Select your preferred primary color for the app"))
                    .font(AppFont.body)
                    .foregroundStyle(themeManager.current.textSecondary)
                    .multilineTextAlignment(.center)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: AppSpacing.large) {
                    ForEach(themeColors, id: \.themeColor.rawValue) { themeOption in
                        let locked = PremiumFeature.isThemeExclusive(themeOption.themeColor) && !isPremium
                        ThemeColorCard(
                            themeOption: themeOption,
                            isSelected: themeManager.currentThemeColor == themeOption.themeColor.rawValue,
                            isLocked: locked,
                            onTap: {
                                if locked {
                                    showPurchaseSheet = true
                                } else {
                                    themeManager.updateThemeColor(themeOption.themeColor.rawValue)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Text(String(localized: "Preview"))
                        .appSectionHeader(theme: themeManager.current)

                    VStack(spacing: AppSpacing.medium) {
                        HStack {
                            Button(action: {
                                Haptics.shared.vibrateIfEnabled()
                            }) {
                                Text(String(localized: "Sample Button"))
                            }
                            .buttonStyle(.appRect)

                            Button(action: {
                                Haptics.shared.vibrateIfEnabled()
                            }) {
                                Image(systemName: "plus")
                            }
                            .buttonStyle(.appCircular)
                            .accessibilityLabel(String(localized: "Sample add button"))
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(themeManager.current.primaryColor)
                                    .accessibilityHidden(true)
                                Text(String(localized: "Sample Card"))
                                    .font(AppFont.headline)
                                    .foregroundStyle(themeManager.current.textPrimary)
                                Spacer()
                            }
                            Text(String(localized: "This is how your selected theme color will look throughout the app."))
                                .font(AppFont.body)
                                .foregroundStyle(themeManager.current.textSecondary)
                        }
                        .appCardStyle(theme: themeManager.current)
                    }
                }
                .padding(.horizontal)

                Text(String(localized: "Purple, Pink, and Orange themes unlock with Premium."))
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .navigationTitle("Theme Color")
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(themeManager.current.background)
        .sheet(isPresented: $showPurchaseSheet) {
            PurchaseSheet()
        }
    }
}

struct ThemeColorOption {
    let themeColor: ThemeColor
    let color: Color
    let icon: String
}

struct ThemeColorCard: View {
    @Dependency(\.themeManager) var themeManager
    let themeOption: ThemeColorOption
    let isSelected: Bool
    var isLocked: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.shared.vibrateIfEnabled()
            onTap()
        }) {
            VStack(spacing: AppSpacing.medium) {
                ZStack {
                    Circle()
                        .fill(themeOption.color)
                        .frame(width: 50, height: 50)
                        .shadow(color: themeOption.color.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: isLocked ? "lock.fill" : themeOption.icon)
                        .font(.title)
                        .foregroundStyle(.white)
                }

                Text(themeOption.themeColor.displayName)
                    .font(AppFont.headline)
                    .foregroundStyle(themeOption.color)

                if isLocked {
                    Text(String(localized: "Premium"))
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.medium)
            .background(themeManager.current.card)
            .clipShape(.rect(cornerRadius: AppCornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .stroke(isSelected ? themeOption.color : Color.clear, lineWidth: 3)
            )
            .shadow(color: AppShadow.card.color, radius: AppShadow.card.radius, x: AppShadow.card.x, y: AppShadow.card.y)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(
            isLocked
                ? String(localized: "\(themeOption.themeColor.displayName) theme, Premium")
                : themeOption.themeColor.displayName
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ThemeColorView()
}
