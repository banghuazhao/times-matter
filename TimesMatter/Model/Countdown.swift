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
    var customInterval: Int = 1
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
    case customDays
    case customWeeks
    case customMonths
    case customYears
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

