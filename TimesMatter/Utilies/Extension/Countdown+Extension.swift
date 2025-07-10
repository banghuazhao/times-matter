//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

// MARK: - Countdown Computed Properties & Logic

extension Countdown {
    // MARK: Next Occurrence

    /// Computed property for next occurrence date (for repeating countdowns)
    var nextOccurrence: Date? {
        guard repeatType != .nonRepeating else { return date }

        let now = Date()
        if date > now { return date }

        let calendar = Calendar.current
        var nextDate = date

        switch repeatType {
        case .nonRepeating:
            return nil
        case .daily:
            nextDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .monthly:
            nextDate = calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .yearly:
            nextDate = calendar.date(byAdding: .year, value: 1, to: date) ?? date
        case .customDays:
            nextDate = calendar.date(byAdding: .day, value: customInterval, to: date) ?? date
        case .customWeeks:
            nextDate = calendar.date(byAdding: .weekOfYear, value: customInterval, to: date) ?? date
        case .customMonths:
            nextDate = calendar.date(byAdding: .month, value: customInterval, to: date) ?? date
        case .customYears:
            nextDate = calendar.date(byAdding: .year, value: customInterval, to: date) ?? date
        }

        // Keep adding intervals until we get a future date
        while nextDate <= now {
            switch repeatType {
            case .daily:
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
            case .weekly:
                nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: nextDate) ?? nextDate
            case .monthly:
                nextDate = calendar.date(byAdding: .month, value: 1, to: nextDate) ?? nextDate
            case .yearly:
                nextDate = calendar.date(byAdding: .year, value: 1, to: nextDate) ?? nextDate
            case .customDays:
                nextDate = calendar.date(byAdding: .day, value: customInterval, to: nextDate) ?? nextDate
            case .customWeeks:
                nextDate = calendar.date(byAdding: .weekOfYear, value: customInterval, to: nextDate) ?? nextDate
            case .customMonths:
                nextDate = calendar.date(byAdding: .month, value: customInterval, to: nextDate) ?? nextDate
            case .customYears:
                nextDate = calendar.date(byAdding: .year, value: customInterval, to: nextDate) ?? nextDate
            case .nonRepeating:
                return nil
            }
        }

        return nextDate
    }

    // MARK: Compact Relative Time

    /// Computed property for relative time (number and label)
    func calculateRelativeTime(currentTime: Date) -> (number: String, label: String) {
        let now = currentTime
        let targetDate: Date
        if repeatType == .nonRepeating {
            targetDate = date
        } else {
            targetDate = nextOccurrence ?? date
        }

        let interval = targetDate.timeIntervalSince(now)
        let absInterval = Swift.abs(interval)
        let isFuture = interval > 0
        let calendar = Calendar.current
        let value: Int
        let component: Calendar.Component
        
        if absInterval < 60 {
            // Less than 1 minute: show seconds
            value = Swift.max(Int(absInterval), 0)
            component = .second
        } else if absInterval < 3600 {
            // Less than 1 hour: show minutes
            value = Swift.max(Int(absInterval / 60), 0)
            component = .minute
        } else if absInterval < 86400 {
            // Less than 1 day: show hours
            value = Swift.max(Int(absInterval / 3600), 0)
            component = .hour
        } else {
            switch compactTimeUnit {
            case .days:
                component = .day
            case .weeks:
                component = .weekOfYear
            case .months:
                component = .month
            case .years:
                component = .year
            }
            let startOfNow = calendar.startOfDay(for: now)
            let startOfTarget = calendar.startOfDay(for: targetDate)
            value = Swift.abs(calendar.dateComponents([component], from: startOfNow, to: startOfTarget).value(for: component) ?? 0)
        }

        let unit = component.localizedUnit(for: value)
        let label = String(localized: isFuture ? "\(unit) left" : "\(unit) ago")
        if value == 0 {
            if component == .second {
                return ("✅", String(localized: "Now"))
            } else {
                return ("1-", label)
            }
        } else {
            return ("\(value)", label)
        }
    }
}

// MARK: - Unit Localization Extension

extension Calendar.Component {
    func localizedUnit(for value: Int) -> String {
        switch self {
        case .day:
            return value == 1 ? String(localized: "day") : String(localized: "days")
        case .weekOfYear:
            return value == 1 ? String(localized: "week") : String(localized: "weeks")
        case .month: return value == 1 ? String(localized: "month") : String(localized: "months")
        case .year: return value == 1 ? String(localized: "year") : String(localized: "years")
        case .hour: return value == 1 ? String(localized: "hour") : String(localized: "hours")
        case .minute: return value == 1 ? String(localized: "minute") : String(localized: "minutes")
        case .second: return value == 1 ? String(localized: "second") : String(localized: "seconds")
        default: return ""
        }
    }
}

extension Countdown.Draft {
    var mock: Countdown {
        Countdown(
            id: 0,
            title: title,
            icon: icon,
            date: date,
            categoryID: categoryID,
            backgroundColor: backgroundColor,
            textColor: textColor,
            isFavorite: isFavorite,
            isArchived: isArchived,
            repeatType: repeatType,
            customInterval: customInterval,
            compactTimeUnit: compactTimeUnit
        )
    }
}
