//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SharingGRDB

// MARK: - Countdown Model

@Table
struct Countdown: Identifiable {
    // MARK: Properties

    let id: Int
    var title: String = ""
    var date: Date = Date()
    var categoryID: Category.ID?
    var backgroundColor: Int = 0x2C3E50CC
    var textColor: Int = 0xFFFFFFFF
    var isFavorite: Bool = false
    var isArchived: Bool = false
    var repeatType: RepeatType = .nonRepeating
    var repeatTime: Int = 1
    var backgroundImageName: String? = nil
    var compactTimeUnit: CompactTimeUnit = .days
    var layout: LayoutType = .middle
    @Column(as: CountdownReminder.JSONRepresentation.self)
    var reminder: CountdownReminder = .init()
}

// MARK: - Draft Extension

extension Countdown.Draft: Identifiable {}

// MARK: - Repeat Type Enum

enum RepeatType: String, Codable, CaseIterable, QueryBindable {
    case nonRepeating
    case daily
    case weekly
    case monthly
    case yearly

    var displayName: String {
        switch self {
        case .nonRepeating: return "No Repeat"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }

    var singleRepeatTimeName: String {
        switch self {
        case .nonRepeating: return "No Repeat"
        case .daily: return "Day"
        case .weekly: return "Week"
        case .monthly: return "Month"
        case .yearly: return "Year"
        }
    }

    var multipleRepeatTimeName: String {
        switch self {
        case .nonRepeating: return "No Repeat"
        case .daily: return "Days"
        case .weekly: return "Weeks"
        case .monthly: return "Months"
        case .yearly: return "Years"
        }
    }

    static var allCasesToChoose: [RepeatType] {
        [.nonRepeating, .daily, .weekly, .monthly, .yearly]
    }
}

// MARK: - Compact Time Unit Enum

enum CompactTimeUnit: String, Codable, CaseIterable, QueryBindable {
    case days
    case weeks
    case months
    case years

    var displayName: String {
        switch self {
        case .days:
            return "Days"
        case .weeks:
            return "Weeks"
        case .months:
            return "Months"
        case .years:
            return "Years"
        }
    }

    var singularName: String {
        switch self {
        case .days:
            return "Day"
        case .weeks:
            return "Week"
        case .months:
            return "Month"
        case .years:
            return "Year"
        }
    }
}

// MARK: - Layout Type Enum

enum LayoutType: String, Codable, CaseIterable, QueryBindable {
    case top
    case middle
    case bottom

    var displayName: String {
        switch self {
        case .top: return "Top"
        case .middle: return "Middle"
        case .bottom: return "Bottom"
        }
    }

    var iconName: String {
        switch self {
        case .top: return "arrow.up.circle"
        case .middle: return "minus.circle"
        case .bottom: return "arrow.down.circle"
        }
    }
}

// MARK: - Reminder Types

enum ReminderType: String, Codable, CaseIterable {
    case noReminder, onlyOnce, everyDay, everyWeek, everyMonth, everyYear

    var displayName: String {
        switch self {
        case .noReminder: return "No Reminder"
        case .onlyOnce: return "Only Once"
        case .everyDay: return "Every Day"
        case .everyWeek: return "Every Week"
        case .everyMonth: return "Every Month"
        case .everyYear: return "Every Year"
        }
    }

    var repeats: Bool {
        switch self {
        case .onlyOnce, .noReminder: return false
        default: return true
        }
    }
}

enum ReminderTime: String, Codable, CaseIterable {
    case atEventTime, fiveMinutesEarly, thirtyMinutesEarly, oneDayEarly, threeDaysEarly

    var displayName: String {
        switch self {
        case .atEventTime: return String(localized: "At Event Time")
        case .fiveMinutesEarly: return String(localized: "5 Minutes Early")
        case .thirtyMinutesEarly: return String(localized: "30 Minutes Early")
        case .oneDayEarly: return String(localized: "1 Day Early")
        case .threeDaysEarly: return String(localized: "3 Days Early")
        }
    }

    var timeInterval: TimeInterval {
        switch self {
        case .atEventTime: return 0
        case .fiveMinutesEarly: return -5 * 60
        case .thirtyMinutesEarly: return -30 * 60
        case .oneDayEarly: return -24 * 60 * 60
        case .threeDaysEarly: return -3 * 24 * 60 * 60
        }
    }
}

struct CountdownReminder: Codable, Equatable {
    var type: ReminderType = .onlyOnce
    var time: ReminderTime = .atEventTime
    var soundName: String = "Default"
    
    init(type: ReminderType = .onlyOnce, time: ReminderTime = .atEventTime, soundName: String = "Default") {
        self.type = type
        self.time = time
        self.soundName = soundName
    }
}
