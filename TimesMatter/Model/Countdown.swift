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

