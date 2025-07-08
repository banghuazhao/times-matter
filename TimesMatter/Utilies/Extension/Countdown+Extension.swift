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
        guard repeatType != .none else { return nil }

        let now = Date()
        if date > now { return date }

        let calendar = Calendar.current
        var nextDate = date

        switch repeatType {
        case .none:
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
            case .none:
                return nil
            }
        }

        return nextDate
    }

    // MARK: Compact Relative Time

    /// Computed property for relative time (number and label)
    var compactRelativeTime: (number: Int, label: String) {
        let now = Date()
        let targetDate: Date
        if repeatType == .none {
            targetDate = date
        } else {
            targetDate = nextOccurrence ?? date
        }

        let interval = targetDate.timeIntervalSince(now)
        let absInterval = Swift.abs(interval)
        let isFuture = interval > 0
        let calendar = Calendar.current

        let (value, unitKey): (Int, String)
        if absInterval < 60 {
            // Less than 1 minute: show seconds
            value = Swift.max(Int(absInterval), 0)
            unitKey = "second"
        } else if absInterval < 3600 {
            // Less than 1 hour: show minutes
            value = Swift.max(Int(absInterval / 60), 0)
            unitKey = "minute"
        } else if absInterval < 86400 {
            // Less than 1 day: show hours
            value = Swift.max(Int(absInterval / 3600), 0)
            unitKey = "hour"
        } else {
            // 1 day or more: use compactTimeUnit
            let component: Calendar.Component
            switch compactTimeUnit {
            case .days:
                component = .day
                unitKey = "day"
            case .weeks:
                component = .weekOfYear
                unitKey = "week"
            case .months:
                component = .month
                unitKey = "month"
            case .years:
                component = .year
                unitKey = "year"
            }
            let startOfNow = calendar.startOfDay(for: now)
            let startOfTarget = calendar.startOfDay(for: targetDate)
            value = Swift.abs(calendar.dateComponents([component], from: startOfNow, to: startOfTarget).value(for: component) ?? 0)
        }

        if value == 0 {
            return (0, String(localized: "Now"))
        }
        let unit = unitKey.localizedUnit(for: value)
        let label = String(localized: isFuture ? "\(unit) left" : "\(unit) ago")
        return (value, label)
    }
}

// MARK: - Unit Localization Extension

extension String {
    func localizedUnit(for value: Int) -> String {
        switch self {
        case "day": return value == 1 ? String(localized: "day") : String(localized: "days")
        case "week": return value == 1 ? String(localized: "week") : String(localized: "weeks")
        case "month": return value == 1 ? String(localized: "month") : String(localized: "months")
        case "year": return value == 1 ? String(localized: "year") : String(localized: "years")
        case "hour": return value == 1 ? String(localized: "hour") : String(localized: "hours")
        case "minute": return value == 1 ? String(localized: "minute") : String(localized: "minutes")
        case "second": return value == 1 ? String(localized: "second") : String(localized: "seconds")
        default: return self
        }
    }
}
