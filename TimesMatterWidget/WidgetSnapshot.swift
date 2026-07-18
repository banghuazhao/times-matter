//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import UIKit

enum WidgetAppGroup {
    static let identifier = "group.com.appsbay.TimesMatter1"
    static let widgetSnapshotKey = "widgetCountdownSnapshot"
    static let suite = UserDefaults(suiteName: identifier)

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}

struct WidgetCountdownItem: Codable, Identifiable, Hashable {
    var id: Int
    var title: String
    var targetDate: Date
    var isFavorite: Bool
    var backgroundColor: Int
    var textColor: Int
    /// Relative path under the App Group container (e.g. `widget-bg/12.jpg`).
    var backgroundImageFileName: String?
}

struct WidgetSnapshot: Codable, Hashable {
    var updatedAt: Date
    var items: [WidgetCountdownItem]
    var upcomingCount: Int
    var pastCount: Int
    var favoriteCount: Int

    static let empty = WidgetSnapshot(
        updatedAt: .distantPast,
        items: [],
        upcomingCount: 0,
        pastCount: 0,
        favoriteCount: 0
    )

    static func load() -> WidgetSnapshot {
        guard
            let data = WidgetAppGroup.suite?.data(forKey: WidgetAppGroup.widgetSnapshotKey),
            let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else {
            return .empty
        }
        return snapshot
    }
}

extension WidgetCountdownItem {
    func daysLeft(from date: Date = .now) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.startOfDay(for: targetDate)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    func relativeLabel(from date: Date = .now) -> String {
        let days = daysLeft(from: date)
        if days == 0 { return String(localized: "Today") }
        if days == 1 { return String(localized: "1 day left") }
        if days > 1 { return String(localized: "\(days) days left") }
        if days == -1 { return String(localized: "1 day ago") }
        return String(localized: "\(-days) days ago")
    }

    /// Loads the exported still (image background or video thumbnail) from the App Group.
    func backgroundUIImage() -> UIImage? {
        guard
            let fileName = backgroundImageFileName,
            !fileName.isEmpty,
            let container = WidgetAppGroup.containerURL
        else { return nil }
        let url = container.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: url.path)
    }
}
