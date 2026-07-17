//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

enum PremiumLimits {
    /// Free users can keep this many active (non-archived) countdowns.
    static let freeCountdownLimit = 5

    static func canCreateCountdown(activeCount: Int, isPremium: Bool) -> Bool {
        isPremium || activeCount < freeCountdownLimit
    }

    static func remainingFreeSlots(activeCount: Int, isPremium: Bool) -> Int? {
        guard !isPremium else { return nil }
        return max(0, freeCountdownLimit - activeCount)
    }
}

enum PremiumFeature: String, CaseIterable, Identifiable {
    case unlimitedCountdowns
    case adFree
    case customSounds
    case customPhotos
    case premiumShareCards
    case exclusiveThemes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unlimitedCountdowns: String(localized: "Unlimited Countdowns")
        case .adFree: String(localized: "Ad-Free Experience")
        case .customSounds: String(localized: "Custom Reminder Sounds")
        case .customPhotos: String(localized: "Photo Backgrounds")
        case .premiumShareCards: String(localized: "Premium Share Cards")
        case .exclusiveThemes: String(localized: "Exclusive Themes")
        }
    }

    var subtitle: String {
        switch self {
        case .unlimitedCountdowns:
            String(localized: "Track every birthday, deadline, and milestone—no caps.")
        case .adFree:
            String(localized: "Focus on your events without banners or interruptions.")
        case .customSounds:
            String(localized: "Pick playful and calming sounds for each reminder.")
        case .customPhotos:
            String(localized: "Use your own photos as countdown backgrounds.")
        case .premiumShareCards:
            String(localized: "Export beautiful Story-ready cards without watermarks.")
        case .exclusiveThemes:
            String(localized: "Unlock Purple, Pink, and Orange accent themes.")
        }
    }

    var systemImage: String {
        switch self {
        case .unlimitedCountdowns: "infinity"
        case .adFree: "nosign"
        case .customSounds: "music.note"
        case .customPhotos: "photo.on.rectangle"
        case .premiumShareCards: "square.and.arrow.up.on.square"
        case .exclusiveThemes: "paintpalette.fill"
        }
    }

    static func isThemeExclusive(_ theme: ThemeColor) -> Bool {
        switch theme {
        case .purple, .pink, .orange: true
        case .default, .blue, .green: false
        }
    }
}
