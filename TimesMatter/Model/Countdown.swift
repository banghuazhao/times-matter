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
        case .nonRepeating: return String(localized: "No Repeat")
        case .daily: return String(localized: "Daily")
        case .weekly: return String(localized: "Weekly")
        case .monthly: return String(localized: "Monthly")
        case .yearly: return String(localized: "Yearly")
        }
    }

    var singleRepeatTimeName: String {
        switch self {
        case .nonRepeating: return String(localized: "No Repeat")
        case .daily: return String(localized: "Day")
        case .weekly: return String(localized: "Week")
        case .monthly: return String(localized: "Month")
        case .yearly: return String(localized: "Year")
        }
    }

    var multipleRepeatTimeName: String {
        switch self {
        case .nonRepeating: return String(localized: "No Repeat")
        case .daily: return String(localized: "Days")
        case .weekly: return String(localized: "Weeks")
        case .monthly: return String(localized: "Months")
        case .yearly: return String(localized: "Years")
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
            return String(localized: "Days")
        case .weeks:
            return String(localized: "Weeks")
        case .months:
            return String(localized: "Months")
        case .years:
            return String(localized: "Years")
        }
    }

    var singularName: String {
        switch self {
        case .days:
            return String(localized: "Day")
        case .weeks:
            return String(localized: "Week")
        case .months:
            return String(localized: "Month")
        case .years:
            return String(localized: "Year")
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
        case .top: return    String(localized: "Top")
        case .middle: return String(localized: "Middle")
        case .bottom: return String(localized: "Bottom")
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
        case .noReminder: return String(localized: "No Reminder")
        case .onlyOnce: return   String(localized: "Only Once")
        case .everyDay: return   String(localized: "Every Day")
        case .everyWeek: return  String(localized: "Every Week")
        case .everyMonth: return String(localized: "Every Month")
        case .everyYear: return  String(localized: "Every Year")
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
