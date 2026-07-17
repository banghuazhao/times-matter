//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

// MARK: - Content Button Styles (in-form controls)

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
            .foregroundStyle(overrideColor ?? theme.primaryColor)
            .background {
                if #available(iOS 26.0, *) {
                    Circle().fill(.clear)
                } else {
                    Circle().fill((overrideColor ?? theme.primaryColor).opacity(0.12))
                }
            }
            .clipShape(Circle())
            .contentShape(Circle())
            .modifier(AppGlassCircleModifier())
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
            .foregroundStyle(.white)
            .background {
                if #available(iOS 26.0, *) {
                    Circle().fill(.clear)
                } else {
                    Circle().fill(Color.black.opacity(0.25))
                }
            }
            .clipShape(Circle())
            .contentShape(Circle())
            .modifier(AppGlassCircleModifier(tint: .white.opacity(0.35)))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(AppAnimation.quick, value: configuration.isPressed)
    }
}

struct AppRectButtonStyle: ButtonStyle {
    let theme: AppTheme
    let filled: Bool

    init(theme: AppTheme = ThemeManager.shared.current, filled: Bool = false) {
        self.theme = theme
        self.filled = filled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.headline)
            .frame(minHeight: AppSpacing.touchTarget)
            .padding(.horizontal, AppSpacing.medium)
            .foregroundStyle(filled ? Color.white : theme.primaryColor)
            .background {
                if #available(iOS 26.0, *) {
                    Capsule().fill(.clear)
                } else if filled {
                    Capsule().fill(theme.primaryColor)
                } else {
                    Capsule().fill(theme.primaryColor.opacity(0.12))
                }
            }
            .clipShape(Capsule())
            .contentShape(Capsule())
            .modifier(AppGlassCapsuleModifier(prominent: filled, tint: theme.primaryColor))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(AppAnimation.quick, value: configuration.isPressed)
    }
}

// MARK: - Toolbar styles (avoid double chrome / white padding on iOS 26)

/// Applies the correct toolbar chrome: system glass on iOS 26, tinted capsule on iOS 18–25.
///
/// - Important: For **icon-only** toolbar buttons, pass `iconOnly: true`. Applying `.glass`
///   on top of the toolbar’s shared Liquid Glass background creates an oversized capsule
///   with excess padding around the symbol.
struct AppToolbarButtonModifier: ViewModifier {
    var prominent: Bool = false
    var iconOnly: Bool = false
    var theme: AppTheme = ThemeManager.shared.current

    @ViewBuilder
    func body(content: Content) -> some View {
        if iconOnly {
            // Circle + small keeps Liquid Glass chrome tight around the symbol
            // (default glass is a large capsule with excess padding).
            if #available(iOS 26.0, *) {
                if prominent {
                    content
                        .buttonStyle(.glassProminent)
                        .buttonBorderShape(.circle)
                        .controlSize(.small)
                        .tint(theme.primaryColor)
                } else {
                    content
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .controlSize(.small)
                        .tint(theme.primaryColor)
                }
            } else if prominent {
                content
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .controlSize(.small)
                    .tint(theme.primaryColor)
            } else {
                content
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .controlSize(.small)
                    .tint(theme.primaryColor)
            }
        } else if #available(iOS 26.0, *) {
            if prominent {
                content
                    .buttonStyle(.glassProminent)
                    .controlSize(.regular)
                    .tint(theme.primaryColor)
            } else {
                content
                    .buttonStyle(.glass)
                    .controlSize(.regular)
                    .tint(theme.primaryColor)
            }
        } else if prominent {
            content
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .tint(theme.primaryColor)
        } else {
            content
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .tint(theme.primaryColor)
        }
    }
}

extension View {
    /// Use on toolbar `Button`s instead of `.buttonStyle(.appRect/.appCircular)`.
    /// Set `iconOnly: true` for symbol-only actions (Close, Add, Filter) to avoid oversized glass padding.
    func appToolbarStyle(
        prominent: Bool = false,
        iconOnly: Bool = false,
        theme: AppTheme = ThemeManager.shared.current
    ) -> some View {
        modifier(AppToolbarButtonModifier(prominent: prominent, iconOnly: iconOnly, theme: theme))
    }
}

// MARK: - Glass helpers for content buttons

private struct AppGlassCircleModifier: ViewModifier {
    var tint: Color? = nil

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                content.glassEffect(.regular.tint(tint).interactive(), in: .circle)
            } else {
                content.glassEffect(.regular.interactive(), in: .circle)
            }
        } else {
            content
        }
    }
}

private struct AppGlassCapsuleModifier: ViewModifier {
    var prominent: Bool
    var tint: Color

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if prominent {
                content.glassEffect(.regular.tint(tint).interactive(), in: .capsule)
            } else {
                content.glassEffect(.regular.tint(tint.opacity(0.35)).interactive(), in: .capsule)
            }
        } else {
            content
        }
    }
}

// MARK: - Convenience

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
        AppRectButtonStyle(filled: false)
    }

    static var appRectFilled: AppRectButtonStyle {
        AppRectButtonStyle(filled: true)
    }
}
