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

    static let currentVersion = 1
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
    var backgroundMusicName: String?
    var compactTimeUnit: CompactTimeUnit
    var layout: LayoutType
    var reminder: CountdownReminder
}

enum BackupService {
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
        backgroundImageManager: BackgroundImageManaging
    ) -> AppBackup {
        let categoryByID = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })

        let countdownBackups = countdowns.map { countdown -> CountdownBackup in
            var customBase64: String?
            var imageName = countdown.backgroundImageName

            if let path = countdown.backgroundImageName,
               backgroundImageManager.isCustomBackgroundImagePath(path),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                customBase64 = data.base64EncodedString()
                imageName = nil
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
                customBackgroundImageBase64: customBase64,
                backgroundMusicName: countdown.backgroundMusicName,
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
        backgroundImageManager: BackgroundImageManaging
    ) throws -> (categories: Int, countdowns: Int) {
        try database.write { db in
            if replaceExisting {
                try Countdown.delete().execute(db)
                try Category.delete().execute(db)
                backgroundImageManager.cleanupAllCustomBackgroundImages()
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
                    backgroundMusicName: item.backgroundMusicName,
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

            return (importedCategories, importedCountdowns)
        }
    }
}
