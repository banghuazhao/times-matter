//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit
import WidgetKit

/// Lightweight snapshot shared with the widget extension via App Group.
struct WidgetCountdownItem: Codable, Identifiable, Hashable {
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

struct WidgetSnapshot: Codable, Hashable {
    var updatedAt: Date
    var items: [WidgetCountdownItem]
    var upcomingCount: Int
    var pastCount: Int
    var favoriteCount: Int
}

enum WidgetDataExporter {
    private static let backgroundFolderName = "widget-bg"

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
                textColor: countdown.textColor,
                backgroundImageFileName: exportBackgroundStill(for: countdown)
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

    /// Copies/renders a still image into the App Group for widget display.
    /// Video → thumbnail; custom/predefined image → JPEG; color-only → nil.
    private static func exportBackgroundStill(for countdown: Countdown) -> String? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppGroup.identifier
        ) else { return nil }

        let folder = container.appendingPathComponent(backgroundFolderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let relativeName = "\(countdown.id).jpg"
        let destination = folder.appendingPathComponent(relativeName)

        let image: UIImage?
        switch countdown.backgroundKind {
        case .video:
            guard let path = countdown.backgroundVideoPath else { return nil }
            image = videoThumbnail(at: path)
        case .image:
            guard let name = countdown.backgroundImageName, !name.isEmpty else { return nil }
            if let fileImage = UIImage(contentsOfFile: name) {
                image = fileImage
            } else {
                image = UIImage(named: name)
            }
        case .color:
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

    private static func videoThumbnail(at path: String) -> UIImage? {
        let url = URL(fileURLWithPath: path)
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 800, height: 800)
        let time = CMTime(seconds: 0.3, preferredTimescale: 600)
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
