//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

// MARK: - Theme Manager
@Observable
class ThemeManager {
    var current: AppTheme = .light
    
    static let shared = ThemeManager()
    
    private init() {}
}

// MARK: - App Theme
struct AppTheme {
    let primaryColor: Color
    let textPrimary: Color
    let textSecondary: Color
    let card: Color
    let background: Color
    
    static let light = AppTheme(
        primaryColor: Color(hex: 0x007AFF00),
        textPrimary: Color(hex: 0x00000000),
        textSecondary: Color(hex: 0x66666600),
        card: Color(hex: 0xFFFFFF00),
        background: Color(hex: 0xF2F2F700)
    )
    
    static let dark = AppTheme(
        primaryColor: Color(hex: 0x0A84FF00),
        textPrimary: Color(hex: 0xFFFFFF00),
        textSecondary: Color(hex: 0x8E8E9300),
        card: Color(hex: 0x1C1C1E00),
        background: Color(hex: 0x00000000)
    )
}

// MARK: - App Font
struct AppFont {
    static let largeTitle = Font.largeTitle
    static let title = Font.title
    static let title2 = Font.title2
    static let title3 = Font.title3
    static let headline = Font.headline
    static let subheadline = Font.subheadline
    static let body = Font.body
    static let callout = Font.callout
    static let footnote = Font.footnote
    static let caption = Font.caption
    static let caption2 = Font.caption2
}

// MARK: - App Spacing
struct AppSpacing {
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32
}

// MARK: - App Corner Radius
struct AppCornerRadius {
    static let card: CGFloat = 12
    static let button: CGFloat = 8
}

// MARK: - App Shadow
struct AppShadow {
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    static let card = Shadow(
        color: Color.black.opacity(0.1),
        radius: 4,
        x: 0,
        y: 2
    )
}

// MARK: - View Extensions
extension View {
    func appSectionHeader(theme: AppTheme) -> some View {
        self
            .font(AppFont.headline)
            .fontWeight(.semibold)
            .foregroundColor(theme.textPrimary)
    }
} 