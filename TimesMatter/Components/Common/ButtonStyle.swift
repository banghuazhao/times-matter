//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

// MARK: - ButtonStyles

struct AppCircularButtonStyle: ButtonStyle {
    let theme: AppTheme
    let overrideColor: Color?

    init(theme: AppTheme = ThemeManager.shared.current, overrideColor: Color? = nil) {
        self.theme = theme
        self.overrideColor = overrideColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppSymbol.font)
            .frame(width: AppSpacing.touchTarget, height: AppSpacing.touchTarget)
            .background((overrideColor ?? theme.primaryColor).opacity(0.12))
            .foregroundStyle(overrideColor ?? theme.primaryColor)
            .clipShape(Circle())
            .contentShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(AppAnimation.quick, value: configuration.isPressed)
    }
}

struct AppWhiteCircularButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppSymbol.font)
            .frame(width: AppSpacing.touchTarget, height: AppSpacing.touchTarget)
            .background(Color.black.opacity(0.2))
            .foregroundStyle(.white)
            .clipShape(Circle())
            .contentShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(AppAnimation.quick, value: configuration.isPressed)
    }
}

struct AppRectButtonStyle: ButtonStyle {
    let theme: AppTheme

    init(theme: AppTheme = ThemeManager.shared.current) {
        self.theme = theme
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.headline)
            .frame(minHeight: AppSpacing.touchTarget)
            .padding(.horizontal, AppSpacing.medium)
            .background(theme.primaryColor.opacity(0.12))
            .foregroundStyle(theme.primaryColor)
            .clipShape(.rect(cornerRadius: AppCornerRadius.capsule))
            .contentShape(.rect(cornerRadius: AppCornerRadius.capsule))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(AppAnimation.quick, value: configuration.isPressed)
    }
}

// MARK: - ButtonStyle Convenience Extensions

extension ButtonStyle where Self == AppCircularButtonStyle {
    static var appCircular: AppCircularButtonStyle {
        AppCircularButtonStyle()
    }
}

extension ButtonStyle where Self == AppWhiteCircularButtonStyle {
    static var appWhiteCircular: AppWhiteCircularButtonStyle {
        AppWhiteCircularButtonStyle()
    }
}

extension ButtonStyle where Self == AppRectButtonStyle {
    static var appRect: AppRectButtonStyle {
        AppRectButtonStyle()
    }
}
