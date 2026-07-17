//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import WidgetKit

/// Lightweight snapshot shared with the widget extension via App Group.
struct WidgetCountdownItem: Codable, Identifiable, Hashable {
    var id: Int
    var title: String
    var targetDate: Date
    var isFavorite: Bool
    var backgroundColor: Int
    var textColor: Int
}

struct WidgetSnapshot: Codable, Hashable {
    var updatedAt: Date
    var items: [WidgetCountdownItem]
    var upcomingCount: Int
    var pastCount: Int
    var favoriteCount: Int
}

enum WidgetDataExporter {
    static func export(countdowns: [Countdown]) {
        let now = Date()
        let active = countdowns.filter { !$0.isArchived }
        let upcoming = active
            .filter { ($0.nextOccurrence ?? $0.date) >= now }
            .sorted { ($0.nextOccurrence ?? $0.date) < ($1.nextOccurrence ?? $1.date) }
        let past = active.filter { ($0.nextOccurrence ?? $0.date) < now }
        let favorites = active.filter(\.isFavorite)

        let items = Array(upcoming.prefix(5)).map { countdown in
            WidgetCountdownItem(
                id: countdown.id,
                title: countdown.title,
                targetDate: countdown.nextOccurrence ?? countdown.date,
                isFavorite: countdown.isFavorite,
                backgroundColor: countdown.backgroundColor,
                textColor: countdown.textColor
            )
        }

        let snapshot = WidgetSnapshot(
            updatedAt: now,
            items: items,
            upcomingCount: upcoming.count,
            pastCount: past.count,
            favoriteCount: favorites.count
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        AppGroup.suite?.set(data, forKey: AppGroup.widgetSnapshotKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
