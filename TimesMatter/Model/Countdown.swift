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
    var icon: String = "⏰"
    var date: Date = Date()
    var categoryID: Category.ID?
    var backgroundColor: Int = 0x2ECC71CC
    var textColor: Int = 0xFFFFFFFFFF
    var isFavorite: Bool = false
    var isArchived: Bool = false
    var repeatType: RepeatType = .nonRepeating
    var repeatTime: Int = 1
    // Compact format: single time unit selection
    var compactTimeUnit: CompactTimeUnit = .days
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

extension Countdown {
    /// Returns a summary string for display: repeat info if repeating, otherwise the formatted date.
    var timeSummary: String {
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale.current
        timeFormatter.dateFormat = "h:mm a"
        let timeString = timeFormatter.string(from: date)
        switch repeatType {
        case .nonRepeating:
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale.current
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: date)
        case .daily:
            if repeatTime == 1 {
                return "Every day at \(timeString)"
            } else {
                return "Every \(repeatTime) days at \(timeString)"
            }
        case .weekly:
            let weekday = Calendar.current.component(.weekday, from: date)
            let weekdayName = Calendar.current.weekdaySymbols[weekday - 1]
            if repeatTime == 1 {
                return "Every week on \(weekdayName) at \(timeString)"
            } else {
                return "Every \(repeatTime) weeks on \(weekdayName) at \(timeString)"
            }
        case .monthly:
            let day = Calendar.current.component(.day, from: date)
            if repeatTime == 1 {
                return "Every month on day \(day) at \(timeString)"
            } else {
                return "Every \(repeatTime) months on day \(day) at \(timeString)"
            }
        case .yearly:
            let month = Calendar.current.component(.month, from: date)
            let day = Calendar.current.component(.day, from: date)
            let monthName = DateFormatter().monthSymbols[month - 1]
            if repeatTime == 1 {
                return "Every year on \(monthName) \(day) at \(timeString)"
            } else {
                return "Every \(repeatTime) years on \(monthName) \(day) at \(timeString)"
            }
        }
    }
}

