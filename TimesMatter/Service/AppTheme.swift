import Dependencies
import Sharing
import SwiftUI

// MARK: - Theme Protocol

protocol AppTheme {
    var primaryColor: Color { get }
    var secondaryGray: Color { get }
    var background: Color { get }
    var card: Color { get }
    var success: Color { get }
    var warning: Color { get }
    var error: Color { get }
    var textPrimary: Color { get }
    var textSecondary: Color { get }
}

// MARK: - Theme Colors

enum ThemeColor: String, CaseIterable {
    case `default` = "Default"
    case blue = "Blue"
    case green = "Green"
    case purple = "Purple"
    case pink = "Pink"
    case orange = "Orange"

    var displayName: String {
        switch self {
        case .`default`:
            String(localized: "Default")
        case .blue:
            String(localized: "Blue")
        case .green:
            String(localized: "Green")
        case .purple:
            String(localized: "Purple")
        case .pink:
            String(localized: "Pink")
        case .orange:
            String(localized: "Orange")
        }
    }

    /// Brand accent — coral default matches existing identity.
    var primaryColor: Color {
        switch self {
        case .default:
            Color(red: 0.914, green: 0.420, blue: 0.369)
        case .blue:
            Color(red: 0.0, green: 0.48, blue: 1.0)
        case .green:
            Color(red: 0.20, green: 0.78, blue: 0.35)
        case .purple:
            Color(red: 0.58, green: 0.35, blue: 0.95)
        case .pink:
            Color(red: 0.91, green: 0.30, blue: 0.58)
        case .orange:
            Color(red: 1.0, green: 0.58, blue: 0.0)
        }
    }

    var backgroundColor: Color {
        switch self {
        case .default:
            Color(red: 0.98, green: 0.95, blue: 0.94)
        case .blue:
            Color(red: 0.95, green: 0.97, blue: 1.0)
        case .green:
            Color(red: 0.94, green: 0.98, blue: 0.95)
        case .purple:
            Color(red: 0.97, green: 0.95, blue: 1.0)
        case .pink:
            Color(red: 0.99, green: 0.95, blue: 0.97)
        case .orange:
            Color(red: 1.0, green: 0.97, blue: 0.94)
        }
    }
}

// MARK: - Base Theme

struct BaseTheme: AppTheme {
    let primaryColor: Color
    let secondaryGray = Color(.secondaryLabel)
    let background: Color
    let card = Color(.secondarySystemGroupedBackground)
    let success = Color(.systemGreen)
    let warning = Color(.systemYellow)
    let error = Color(.systemRed)
    let textPrimary = Color(.label)
    let textSecondary = Color(.secondaryLabel)

    init(themeColor: ThemeColor) {
        primaryColor = themeColor.primaryColor
        background = themeColor.backgroundColor
    }
}

struct DarkBaseTheme: AppTheme {
    let primaryColor: Color
    let secondaryGray = Color(.secondaryLabel)
    let background = Color(.systemGroupedBackground)
    let card = Color(.secondarySystemGroupedBackground)
    let success = Color(.systemGreen)
    let warning = Color(.systemYellow)
    let error = Color(.systemRed)
    let textPrimary = Color(.label)
    let textSecondary = Color(.secondaryLabel)

    init(themeColor: ThemeColor) {
        primaryColor = themeColor.primaryColor
    }
}

// MARK: - Theme Manager

@Observable
class ThemeManager: ObservableObject {
    var current: AppTheme {
        let themeColor = ThemeColor(rawValue: selectedThemeColor) ?? .default
        return darkModeEnabled ?
            DarkBaseTheme(themeColor: themeColor) :
            BaseTheme(themeColor: themeColor)
    }

    @ObservationIgnored
    @Shared(.appStorage("darkModeEnabled")) private var darkModeEnabledStorage: Bool = false

    var darkModeEnabled: Bool { darkModeEnabledStorage }

    @ObservationIgnored
    @Shared(.appStorage("selectedThemeColor")) private var selectedThemeColor: String = ThemeColor.default.rawValue

    static let shared = ThemeManager()

    var currentThemeColor: String {
        selectedThemeColor
    }

    func updateThemeColor(_ themeColorName: String) {
        $selectedThemeColor.withLock {
            $0 = themeColorName
        }
    }

    func updateTheme(darkMode: Bool) {
        $darkModeEnabledStorage.withLock {
            $0 = darkMode
        }
    }
}

// MARK: - DependencyKey for ThemeManager

private enum ThemeManagerKey: DependencyKey {
    static let liveValue = ThemeManager.shared
}

extension DependencyValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - Typography (Dynamic Type roles)

enum AppFont {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title.weight(.semibold)
    static let title2 = Font.title2.weight(.semibold)
    static let title3 = Font.title3.weight(.semibold)
    static let headline = Font.headline
    static let body = Font.body
    static let subheadline = Font.subheadline
    static let subheadlineSemibold = Font.subheadline.weight(.semibold)
    static let caption = Font.caption
    static let footnote = Font.footnote
}

// MARK: - Spacing & Layout (4/8pt grid)

enum AppSpacing {
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let smallMedium: CGFloat = 12
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let xLarge: CGFloat = 32
    static let touchTarget: CGFloat = 44
}

enum AppCornerRadius {
    static let info: CGFloat = 12
    static let card: CGFloat = 16
    static let button: CGFloat = 12
    static let capsule: CGFloat = 18
    static let avatar: CGFloat = 25
}

// MARK: - Animation

enum AppAnimation {
    static let quick: Animation = .smooth(duration: 0.2)
    static let standard: Animation = .smooth(duration: 0.28)
    static let snappy: Animation = .snappy(duration: 0.25)
}

// MARK: - Shadows

enum AppShadow {
    static let card = ShadowStyle(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Symbol config

enum AppSymbol {
    static let font = Font.body.weight(.semibold)
    static let renderingMode = SymbolRenderingMode.hierarchical
}

// MARK: - Reusable Modifiers

extension View {
    func appCardStyle(theme: AppTheme = ThemeManager.shared.current) -> some View {
        padding(AppSpacing.medium)
            .background(theme.card)
            .clipShape(.rect(cornerRadius: AppCornerRadius.card))
            .shadow(color: AppShadow.card.color, radius: AppShadow.card.radius, x: AppShadow.card.x, y: AppShadow.card.y)
    }

    func appSectionHeader(theme: AppTheme = ThemeManager.shared.current) -> some View {
        font(AppFont.headline)
            .foregroundStyle(theme.textPrimary)
            .padding(.vertical, AppSpacing.small)
    }

    func appBackground(theme: AppTheme = ThemeManager.shared.current) -> some View {
        background(theme.background)
    }

    func appInfoSection(theme: AppTheme = ThemeManager.shared.current) -> some View {
        padding(.vertical, AppSpacing.small)
            .padding(.horizontal, AppSpacing.medium)
            .background(theme.secondaryGray.opacity(0.1))
            .clipShape(.rect(cornerRadius: AppCornerRadius.info))
    }

    func appButtonStyle(theme: AppTheme = ThemeManager.shared.current, filled: Bool = true) -> some View {
        font(AppFont.headline)
            .padding(.vertical, AppSpacing.smallMedium)
            .padding(.horizontal, AppSpacing.large)
            .frame(minHeight: AppSpacing.touchTarget)
            .background(filled ? theme.primaryColor : Color.clear)
            .foregroundStyle(filled ? Color.white : theme.primaryColor)
            .clipShape(.rect(cornerRadius: AppCornerRadius.button))
            .contentShape(.rect(cornerRadius: AppCornerRadius.button))
    }

    @ViewBuilder
    func appGlassIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect()
        } else {
            self
        }
    }
}
