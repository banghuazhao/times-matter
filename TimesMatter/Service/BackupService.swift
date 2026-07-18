//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData
import UIKit

// MARK: - Backup DTOs

struct AppBackup: Codable {
    var version: Int
    var exportedAt: Date
    var categories: [CategoryBackup]
    var countdowns: [CountdownBackup]

    /// v1: initial JSON backup. v2: optional video payload + music volume defaults.
    static let currentVersion = 2
}

struct CategoryBackup: Codable, Identifiable {
    var id: Int
    var title: String
}

struct CountdownBackup: Codable, Identifiable {
    var id: Int
    var title: String
    var date: Date
    var categoryTitle: String?
    var backgroundColor: Int
    var textColor: Int
    var isFavorite: Bool
    var isArchived: Bool
    var repeatType: RepeatType
    var repeatTime: Int
    var backgroundImageName: String?
    /// Base64-encoded custom photo background (optional).
    var customBackgroundImageBase64: String?
    /// Base64-encoded custom video background (optional; omitted when too large).
    var customBackgroundVideoBase64: String?
    var customBackgroundVideoFileExtension: String?
    var backgroundMusicName: String?
    var backgroundMusicVolume: Double
    var compactTimeUnit: CompactTimeUnit
    var layout: LayoutType
    var reminder: CountdownReminder

    enum CodingKeys: String, CodingKey {
        case id, title, date, categoryTitle, backgroundColor, textColor
        case isFavorite, isArchived, repeatType, repeatTime
        case backgroundImageName, customBackgroundImageBase64
        case customBackgroundVideoBase64, customBackgroundVideoFileExtension
        case backgroundMusicName, backgroundMusicVolume
        case compactTimeUnit, layout, reminder
    }

    init(
        id: Int,
        title: String,
        date: Date,
        categoryTitle: String?,
        backgroundColor: Int,
        textColor: Int,
        isFavorite: Bool,
        isArchived: Bool,
        repeatType: RepeatType,
        repeatTime: Int,
        backgroundImageName: String?,
        customBackgroundImageBase64: String?,
        customBackgroundVideoBase64: String? = nil,
        customBackgroundVideoFileExtension: String? = nil,
        backgroundMusicName: String?,
        backgroundMusicVolume: Double = 0.55,
        compactTimeUnit: CompactTimeUnit,
        layout: LayoutType,
        reminder: CountdownReminder
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.categoryTitle = categoryTitle
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.isFavorite = isFavorite
        self.isArchived = isArchived
        self.repeatType = repeatType
        self.repeatTime = repeatTime
        self.backgroundImageName = backgroundImageName
        self.customBackgroundImageBase64 = customBackgroundImageBase64
        self.customBackgroundVideoBase64 = customBackgroundVideoBase64
        self.customBackgroundVideoFileExtension = customBackgroundVideoFileExtension
        self.backgroundMusicName = backgroundMusicName
        self.backgroundMusicVolume = backgroundMusicVolume
        self.compactTimeUnit = compactTimeUnit
        self.layout = layout
        self.reminder = reminder
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        date = try c.decode(Date.self, forKey: .date)
        categoryTitle = try c.decodeIfPresent(String.self, forKey: .categoryTitle)
        backgroundColor = try c.decode(Int.self, forKey: .backgroundColor)
        textColor = try c.decode(Int.self, forKey: .textColor)
        isFavorite = try c.decode(Bool.self, forKey: .isFavorite)
        isArchived = try c.decode(Bool.self, forKey: .isArchived)
        repeatType = try c.decode(RepeatType.self, forKey: .repeatType)
        repeatTime = try c.decode(Int.self, forKey: .repeatTime)
        backgroundImageName = try c.decodeIfPresent(String.self, forKey: .backgroundImageName)
        customBackgroundImageBase64 = try c.decodeIfPresent(String.self, forKey: .customBackgroundImageBase64)
        customBackgroundVideoBase64 = try c.decodeIfPresent(String.self, forKey: .customBackgroundVideoBase64)
        customBackgroundVideoFileExtension = try c.decodeIfPresent(String.self, forKey: .customBackgroundVideoFileExtension)
        backgroundMusicName = try c.decodeIfPresent(String.self, forKey: .backgroundMusicName)
        // Older backups omit volume — keep a sensible default.
        backgroundMusicVolume = try c.decodeIfPresent(Double.self, forKey: .backgroundMusicVolume) ?? 0.55
        compactTimeUnit = try c.decode(CompactTimeUnit.self, forKey: .compactTimeUnit)
        layout = try c.decode(LayoutType.self, forKey: .layout)
        reminder = try c.decode(CountdownReminder.self, forKey: .reminder)
    }
}

enum BackupService {
    /// Skip embedding videos larger than this to keep backup files practical.
    private static let maxEmbeddedVideoBytes = 12 * 1024 * 1024

    enum BackupError: LocalizedError {
        case encodeFailed
        case decodeFailed
        case invalidBackup

        var errorDescription: String? {
            switch self {
            case .encodeFailed: String(localized: "Could not create backup file.")
            case .decodeFailed: String(localized: "Could not read backup file.")
            case .invalidBackup: String(localized: "This backup file is not valid.")
            }
        }
    }

    static func makeBackup(
        countdowns: [Countdown],
        categories: [Category],
        backgroundImageManager: BackgroundImageManaging,
        videoBackgroundManager: VideoBackgroundManaging
    ) -> AppBackup {
        let categoryByID = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })

        let countdownBackups = countdowns.map { countdown -> CountdownBackup in
            var customImageBase64: String?
            var imageName = countdown.backgroundImageName
            var customVideoBase64: String?
            var videoExtension: String?

            if let path = countdown.backgroundImageName,
               backgroundImageManager.isCustomBackgroundImagePath(path),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                customImageBase64 = data.base64EncodedString()
                imageName = nil
            }

            if let path = countdown.backgroundVideoPath,
               videoBackgroundManager.isCustomBackgroundVideoPath(path),
               let attrs = try? FileManager.default.attributesOfItem(atPath: path),
               let size = attrs[.size] as? NSNumber,
               size.intValue <= maxEmbeddedVideoBytes,
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                customVideoBase64 = data.base64EncodedString()
                videoExtension = URL(fileURLWithPath: path).pathExtension
            }

            return CountdownBackup(
                id: countdown.id,
                title: countdown.title,
                date: countdown.date,
                categoryTitle: countdown.categoryID.flatMap { categoryByID[$0]?.title },
                backgroundColor: countdown.backgroundColor,
                textColor: countdown.textColor,
                isFavorite: countdown.isFavorite,
                isArchived: countdown.isArchived,
                repeatType: countdown.repeatType,
                repeatTime: countdown.repeatTime,
                backgroundImageName: imageName,
                customBackgroundImageBase64: customImageBase64,
                customBackgroundVideoBase64: customVideoBase64,
                customBackgroundVideoFileExtension: videoExtension,
                backgroundMusicName: countdown.backgroundMusicName,
                backgroundMusicVolume: countdown.backgroundMusicVolume,
                compactTimeUnit: countdown.compactTimeUnit,
                layout: countdown.layout,
                reminder: countdown.reminder
            )
        }

        return AppBackup(
            version: AppBackup.currentVersion,
            exportedAt: Date(),
            categories: categories.map { CategoryBackup(id: $0.id, title: $0.title) },
            countdowns: countdownBackups
        )
    }

    static func exportData(_ backup: AppBackup) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            return try encoder.encode(backup)
        } catch {
            throw BackupError.encodeFailed
        }
    }

    static func decodeBackup(from data: Data) throws -> AppBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let backup = try decoder.decode(AppBackup.self, from: data)
            guard backup.version >= 1 else { throw BackupError.invalidBackup }
            return backup
        } catch let error as BackupError {
            throw error
        } catch {
            throw BackupError.decodeFailed
        }
    }

    static func writeTemporaryFile(_ backup: AppBackup) throws -> URL {
        let data = try exportData(backup)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        let name = "TimesMatter-Backup-\(formatter.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }

    @MainActor
    static func importBackup(
        _ backup: AppBackup,
        replaceExisting: Bool,
        database: any DatabaseWriter,
        backgroundImageManager: BackgroundImageManaging,
        videoBackgroundManager: VideoBackgroundManaging,
        isPremium: Bool
    ) throws -> (categories: Int, countdowns: Int, archivedForFreeLimit: Int) {
        try database.write { db in
            if replaceExisting {
                try Countdown.delete().execute(db)
                try Category.delete().execute(db)
                backgroundImageManager.cleanupAllCustomBackgroundImages()
                videoBackgroundManager.cleanupAllCustomBackgroundVideos()
            }

            var titleToID: [String: Category.ID] = [:]
            if !replaceExisting {
                let existing = try Category.fetchAll(db)
                for category in existing {
                    titleToID[category.title] = category.id
                }
            }

            var importedCategories = 0
            for category in backup.categories {
                if titleToID[category.title] != nil { continue }
                let inserted = try Category
                    .insert { Category.Draft(title: category.title) }
                    .returning { $0 }
                    .fetchOne(db)
                if let inserted {
                    titleToID[category.title] = inserted.id
                    importedCategories += 1
                }
            }

            for countdown in backup.countdowns {
                guard let title = countdown.categoryTitle, titleToID[title] == nil else { continue }
                let inserted = try Category
                    .insert { Category.Draft(title: title) }
                    .returning { $0 }
                    .fetchOne(db)
                if let inserted {
                    titleToID[title] = inserted.id
                    importedCategories += 1
                }
            }

            var importedCountdowns = 0
            for item in backup.countdowns {
                var imageName = item.backgroundImageName
                if let base64 = item.customBackgroundImageBase64,
                   let data = Data(base64Encoded: base64),
                   let image = UIImage(data: data),
                   let path = try? backgroundImageManager.saveCustomBackgroundImage(image) {
                    imageName = path
                }

                var videoPath: String?
                if let base64 = item.customBackgroundVideoBase64,
                   let data = Data(base64Encoded: base64) {
                    let ext = item.customBackgroundVideoFileExtension ?? "mp4"
                    videoPath = try? videoBackgroundManager.saveCustomBackgroundVideo(
                        data: data,
                        fileExtension: ext
                    )
                }

                // Image / video / color remain mutually exclusive on restore.
                if videoPath != nil {
                    imageName = nil
                }

                let draft = Countdown.Draft(
                    title: item.title,
                    date: item.date,
                    categoryID: item.categoryTitle.flatMap { titleToID[$0] },
                    backgroundColor: item.backgroundColor,
                    textColor: item.textColor,
                    isFavorite: item.isFavorite,
                    isArchived: item.isArchived,
                    repeatType: item.repeatType,
                    repeatTime: item.repeatTime,
                    backgroundImageName: imageName,
                    backgroundVideoPath: videoPath,
                    backgroundMusicName: item.backgroundMusicName,
                    backgroundMusicVolume: item.backgroundMusicVolume,
                    compactTimeUnit: item.compactTimeUnit,
                    layout: item.layout,
                    reminder: item.reminder
                )

                let saved = try Countdown
                    .insert { draft }
                    .returning { $0 }
                    .fetchOne(db)

                if let saved {
                    ReminderNotificationManager.shared.removeNotification(for: saved)
                    ReminderNotificationManager.shared.scheduleNotification(for: saved)
                    importedCountdowns += 1
                }
            }

            let archivedForFreeLimit = try enforceFreeActiveLimitIfNeeded(db: db, isPremium: isPremium)

            return (importedCategories, importedCountdowns, archivedForFreeLimit)
        }
    }

    /// Free accounts keep at most `PremiumLimits.freeCountdownLimit` active events after import.
    private static func enforceFreeActiveLimitIfNeeded(db: Database, isPremium: Bool) throws -> Int {
        guard !isPremium else { return 0 }
        let active = try Countdown.fetchAll(db)
            .filter { !$0.isArchived }
            .sorted { $0.date > $1.date }
        let limit = PremiumLimits.freeCountdownLimit
        guard active.count > limit else { return 0 }

        var archived = 0
        for countdown in active.dropFirst(limit) {
            var updated = countdown
            updated.isArchived = true
            try Countdown.update(updated).execute(db)
            ReminderNotificationManager.shared.removeNotification(for: updated)
            archived += 1
        }
        return archived
    }
}
