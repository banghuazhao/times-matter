//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit
import WidgetKit

/// Lightweight snapshot shared with the widget extension via App Group.
struct WidgetCountdownItem: Codable, Identifiable, Hashable, Sendable {
    var id: Int
    var title: String
    var targetDate: Date
    var isFavorite: Bool
    var backgroundColor: Int
    var textColor: Int
    /// Relative path under the App Group container (e.g. `widget-bg/12.jpg`).
    /// Used for image backgrounds and still frames from video backgrounds.
    var backgroundImageFileName: String?
}

struct WidgetSnapshot: Codable, Hashable, Sendable {
    var updatedAt: Date
    var items: [WidgetCountdownItem]
    var upcomingCount: Int
    var pastCount: Int
    var favoriteCount: Int
}

enum WidgetDataExporter {
    private static let backgroundFolderName = "widget-bg"

    private struct ExportInput: Sendable {
        var id: Int
        var title: String
        var targetDate: Date
        var isFavorite: Bool
        var backgroundColor: Int
        var textColor: Int
        var backgroundKindRaw: String
        var backgroundImageName: String?
        var backgroundVideoPath: String?
    }

    static func export(countdowns: [Countdown]) {
        let now = Date()
        let active = countdowns.filter { !$0.isArchived }
        let upcoming = active
            .filter { ($0.nextOccurrence ?? $0.date) >= now }
            .sorted { ($0.nextOccurrence ?? $0.date) < ($1.nextOccurrence ?? $1.date) }
        let past = active.filter { ($0.nextOccurrence ?? $0.date) < now }
        let favorites = active.filter(\.isFavorite)

        let inputs: [ExportInput] = Array(upcoming.prefix(5)).map { countdown in
            ExportInput(
                id: countdown.id,
                title: countdown.title,
                targetDate: countdown.nextOccurrence ?? countdown.date,
                isFavorite: countdown.isFavorite,
                backgroundColor: countdown.backgroundColor,
                textColor: countdown.textColor,
                backgroundKindRaw: {
                    switch countdown.backgroundKind {
                    case .video: "video"
                    case .image: "image"
                    case .color: "color"
                    }
                }(),
                backgroundImageName: countdown.backgroundImageName,
                backgroundVideoPath: countdown.backgroundVideoPath
            )
        }

        let upcomingCount = upcoming.count
        let pastCount = past.count
        let favoriteCount = favorites.count

        Task.detached(priority: .utility) {
            let items = inputs.map { input -> WidgetCountdownItem in
                WidgetCountdownItem(
                    id: input.id,
                    title: input.title,
                    targetDate: input.targetDate,
                    isFavorite: input.isFavorite,
                    backgroundColor: input.backgroundColor,
                    textColor: input.textColor,
                    backgroundImageFileName: exportBackgroundStill(for: input)
                )
            }

            let snapshot = WidgetSnapshot(
                updatedAt: now,
                items: items,
                upcomingCount: upcomingCount,
                pastCount: pastCount,
                favoriteCount: favoriteCount
            )

            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            AppGroup.suite?.set(data, forKey: AppGroup.widgetSnapshotKey)
            await MainActor.run {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    /// Copies/renders a still image into the App Group for widget display.
    private static func exportBackgroundStill(for input: ExportInput) -> String? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppGroup.identifier
        ) else { return nil }

        let folder = container.appendingPathComponent(backgroundFolderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let relativeName = "\(input.id).jpg"
        let destination = folder.appendingPathComponent(relativeName)

        let image: UIImage?
        switch input.backgroundKindRaw {
        case "video":
            guard let path = input.backgroundVideoPath else { return nil }
            image = VideoThumbnailCache.image(for: path)
        case "image":
            guard let name = input.backgroundImageName, !name.isEmpty else { return nil }
            if let fileImage = UIImage(contentsOfFile: name) {
                image = fileImage
            } else {
                image = UIImage(named: name)
            }
        default:
            try? FileManager.default.removeItem(at: destination)
            return nil
        }

        guard let image,
              let data = image.jpegData(compressionQuality: 0.82)
        else { return nil }

        do {
            try data.write(to: destination, options: .atomic)
            return "\(backgroundFolderName)/\(relativeName)"
        } catch {
            return nil
        }
    }
}
