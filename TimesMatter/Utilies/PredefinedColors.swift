import SwiftUI

struct PredefinedColors {
    /// Stored as 0xRRGGBBAA so selection can compare against `Countdown.backgroundColor` exactly.
    static let backgroundColorHexes: [Int] = [
        0x2C3E50CC, // Default slate (matches Countdown default)
        0xC0392BCC, // Dark Red
        0x8E44ADCC, // Dark Purple
        0x27AE60CC, // Dark Green
        0x34495ECC, // Dark Blue
        0x8B4513CC, // Brown
        0x95A5A6CC, // Gray
        0xE74C3CCC, // Red
        0xE67E22CC, // Orange
        0xF1C40FCC, // Yellow
        0xE91E63CC, // Pink
        0x9B59B6CC, // Purple
        0x4ECDC4CC, // Teal
        0x2ECC71CC, // Green
        0x3498DBCC, // Blue
    ]

    static let backgroundColors: [Color] = backgroundColorHexes.map { Color(hex: $0) }

    static let textColorHexes: [Int] = [
        0xFFFFFFFF, // White (matches Countdown default)
        0x000000FF, // Black
        0xD3D3D3FF, // Light Gray
        0x007AFFFF, // Blue
        0x34C759FF, // Green
        0xAF5CF7FF, // Purple
        0xFF9500FF, // Orange
        0xFF3B30FF, // Red
        0xFF2D92FF, // Pink
        0x5AC8FAFF, // Teal
        0xFFCC00FF, // Yellow
        0x8B4513FF, // Brown
        0xFFD700FF, // Gold
        0xC0C0C0FF, // Silver
        0x00FFFFFF, // Cyan
        0xFF00FFFF, // Magenta
        0x32CD32FF, // Lime
        0x000080FF, // Navy
        0x800000FF, // Maroon
    ]

    static let textColors: [Color] = textColorHexes.map { Color(hex: $0) }
}
