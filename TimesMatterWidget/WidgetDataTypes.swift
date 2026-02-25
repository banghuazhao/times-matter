//
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

/// App Group identifier for sharing data between the app and the widget.
/// Must match the App Group capability in both targets.
public enum WidgetAppGroup {
    public static let id = "group.com.appsbay.TimesMatter1"
}

/// Lightweight countdown item for widget display. Encoded by the app, decoded by the widget.
public struct WidgetCountdownItem: Codable, Identifiable {
    public var id: String { "\(title)_\(targetDate)" }
    public let title: String
    /// TimeInterval since 1970 for the target date (next occurrence for repeating events).
    public let targetDate: TimeInterval
    /// Precomputed relative number, e.g. "5" or "✅"
    public let number: String
    /// Precomputed label, e.g. "days left" or "Now"
    public let label: String
    /// Hex with alpha, e.g. 0xFF6B9DCC
    public let backgroundColor: Int
    public let textColor: Int

    public init(title: String, targetDate: TimeInterval, number: String, label: String, backgroundColor: Int, textColor: Int) {
        self.title = title
        self.targetDate = targetDate
        self.number = number
        self.label = label
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }
}

/// Read/write widget data in the shared App Group container.
public enum WidgetDataManager {
    private static let key = "widget_countdown_items"

    public static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: WidgetAppGroup.id)
    }

    public static func save(_ items: [WidgetCountdownItem]) {
        guard let defaults = sharedDefaults else { return }
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: key)
        }
    }

    public static func load() -> [WidgetCountdownItem] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: key),
              let items = try? JSONDecoder().decode([WidgetCountdownItem].self, from: data) else {
            return []
        }
        return items
    }
}
