//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

struct GalleryTemplate: Identifiable, Hashable {
    enum Season: String, CaseIterable, Identifiable {
        case anytime, spring, summer, autumn, winter, holidays

        var id: String { rawValue }

        var title: String {
            switch self {
            case .anytime: String(localized: "Anytime")
            case .spring: String(localized: "Spring")
            case .summer: String(localized: "Summer")
            case .autumn: String(localized: "Autumn")
            case .winter: String(localized: "Winter")
            case .holidays: String(localized: "Holidays")
            }
        }
    }

    var id: String
    var emoji: String
    var title: String
    var season: Season
    var categoryID: Category.ID?
    var backgroundColor: Int
    var textColor: Int
    var repeatType: RepeatType
    var repeatTime: Int
    var backgroundImageName: String?
    var reminder: CountdownReminder
    var month: Int?
    var day: Int?
    var daysFromNow: Int?

    var suggestedDate: Date {
        let calendar = Calendar.current
        if let month, let day {
            if let next = calendar.nextDate(
                after: Date(),
                matching: DateComponents(month: month, day: day, hour: 9, minute: 0),
                matchingPolicy: .nextTimePreservingSmallerComponents
            ) {
                return next
            }
        }
        if let daysFromNow {
            return calendar.date(byAdding: .day, value: daysFromNow, to: Date()) ?? Date()
        }
        return calendar.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    }

    func makeDraft(title: String? = nil, date: Date? = nil) -> Countdown.Draft {
        .init(
            title: title ?? self.title,
            date: date ?? suggestedDate,
            categoryID: categoryID,
            backgroundColor: backgroundColor,
            textColor: textColor,
            repeatType: repeatType,
            repeatTime: repeatTime,
            backgroundImageName: backgroundImageName,
            reminder: reminder
        )
    }

    static var onboardingPicks: [GalleryTemplate] {
        [
            all.first { $0.id == "birthday" },
            all.first { $0.id == "anniversary" },
            all.first { $0.id == "vacation" },
            all.first { $0.id == "deadline" },
            all.first { $0.id == "new_year" },
            all.first { $0.id == "custom" },
        ].compactMap { $0 }
    }

    static var currentSeasonHighlights: [GalleryTemplate] {
        let month = Calendar.current.component(.month, from: Date())
        let season: Season
        switch month {
        case 3, 4, 5: season = .spring
        case 6, 7, 8: season = .summer
        case 9, 10, 11: season = .autumn
        default: season = .winter
        }
        let seasonal = all.filter { $0.season == season || $0.season == .holidays }
        return Array(seasonal.prefix(6))
    }

    static let all: [GalleryTemplate] = [
        .init(
            id: "birthday",
            emoji: "🎂",
            title: String(localized: "Birthday"),
            season: .anytime,
            categoryID: 2,
            backgroundColor: 0xFF6B9DCC,
            textColor: 0xFFFFFFFF,
            repeatType: .yearly,
            repeatTime: 1,
            backgroundImageName: "predefined_birthday",
            reminder: .init(type: .everyYear, time: .oneDayEarly, soundName: "Happy Birthday.mp3"),
            daysFromNow: 60
        ),
        .init(
            id: "anniversary",
            emoji: "💍",
            title: String(localized: "Anniversary"),
            season: .anytime,
            categoryID: 1,
            backgroundColor: 0xE74C3CCC,
            textColor: 0xFFFFFFFF,
            repeatType: .yearly,
            repeatTime: 1,
            backgroundImageName: "predefined_relationship",
            reminder: .init(type: .everyYear, time: .oneDayEarly, soundName: "Mindful Chimes.mp3"),
            daysFromNow: 180
        ),
        .init(
            id: "vacation",
            emoji: "🏖️",
            title: String(localized: "Vacation"),
            season: .summer,
            categoryID: nil,
            backgroundColor: 0x2ECC71CC,
            textColor: 0xFFFFFFFF,
            repeatType: .nonRepeating,
            repeatTime: 1,
            backgroundImageName: "predefined_taupo",
            reminder: .init(type: .onlyOnce, time: .oneDayEarly),
            daysFromNow: 90
        ),
        .init(
            id: "deadline",
            emoji: "📅",
            title: String(localized: "Project Deadline"),
            season: .anytime,
            categoryID: 3,
            backgroundColor: 0x34495ECC,
            textColor: 0xFFFFFFFF,
            repeatType: .nonRepeating,
            repeatTime: 1,
            backgroundImageName: "predefined_mercer_bay",
            reminder: .init(type: .onlyOnce, time: .oneDayEarly),
            daysFromNow: 14
        ),
        .init(
            id: "dentist",
            emoji: "🦷",
            title: String(localized: "Dentist Appointment"),
            season: .anytime,
            categoryID: 4,
            backgroundColor: 0x1ABC9CCC,
            textColor: 0xFFFFFFFF,
            repeatType: .nonRepeating,
            repeatTime: 1,
            backgroundImageName: "predefined_shakespeare",
            reminder: .init(type: .onlyOnce, time: .oneDayEarly, soundName: "Focus Breeze.mp3"),
            daysFromNow: 7
        ),
        .init(
            id: "car_service",
            emoji: "🚗",
            title: String(localized: "Car Service"),
            season: .anytime,
            categoryID: 4,
            backgroundColor: 0xE67E22CC,
            textColor: 0xFFFFFFFF,
            repeatType: .yearly,
            repeatTime: 1,
            backgroundImageName: "predefined_tree_sister",
            reminder: .init(type: .everyYear, time: .oneDayEarly, soundName: "Retro Ringer.mp3"),
            daysFromNow: 30
        ),
        .init(
            id: "custom",
            emoji: "🌟",
            title: String(localized: "Special Event"),
            season: .anytime,
            categoryID: nil,
            backgroundColor: 0x9B59B6CC,
            textColor: 0xFFFFFFFF,
            repeatType: .nonRepeating,
            repeatTime: 1,
            backgroundImageName: "predefined_star",
            reminder: .init(type: .onlyOnce, time: .atEventTime),
            daysFromNow: 30
        ),
        .init(
            id: "christmas",
            emoji: "🎄",
            title: String(localized: "Christmas"),
            season: .holidays,
            categoryID: 3,
            backgroundColor: 0xC0392BCC,
            textColor: 0xFFFFFFFF,
            repeatType: .yearly,
            repeatTime: 1,
            backgroundImageName: "predefined_holiday",
            reminder: .init(type: .everyYear, time: .oneDayEarly, soundName: "Merry Christmas.mp3"),
            month: 12,
            day: 25
        ),
        .init(
            id: "new_year",
            emoji: "🎆",
            title: String(localized: "New Year"),
            season: .holidays,
            categoryID: 3,
            backgroundColor: 0x9B59B6CC,
            textColor: 0xFFFFFFFF,
            repeatType: .yearly,
            repeatTime: 1,
            backgroundImageName: "predefined_wanaka_tree",
            reminder: .init(type: .everyYear, time: .thirtyMinutesEarly),
            month: 1,
            day: 1
        ),
        .init(
            id: "valentines",
            emoji: "💝",
            title: String(localized: "Valentine’s Day"),
            season: .holidays,
            categoryID: 1,
            backgroundColor: 0xE91E63CC,
            textColor: 0xFFFFFFFF,
            repeatType: .yearly,
            repeatTime: 1,
            backgroundImageName: "predefined_relationship",
            reminder: .init(type: .everyYear, time: .oneDayEarly),
            month: 2,
            day: 14
        ),
        .init(
            id: "cny",
            emoji: "🧧",
            title: String(localized: "Lunar New Year"),
            season: .holidays,
            categoryID: 3,
            backgroundColor: 0xE74C3CCC,
            textColor: 0xFFFFFFFF,
            repeatType: .yearly,
            repeatTime: 1,
            backgroundImageName: "predefined_aurora",
            reminder: .init(type: .everyYear, time: .oneDayEarly),
            month: 2,
            day: 17
        ),
        .init(
            id: "mid_autumn",
            emoji: "🌕",
            title: String(localized: "Mid-Autumn Festival"),
            season: .autumn,
            categoryID: 3,
            backgroundColor: 0xF39C12CC,
            textColor: 0xFFFFFFFF,
            repeatType: .yearly,
            repeatTime: 1,
            backgroundImageName: "predefined_mt_eden",
            reminder: .init(type: .everyYear, time: .oneDayEarly),
            month: 9,
            day: 25
        ),
        .init(
            id: "halloween",
            emoji: "🎃",
            title: String(localized: "Halloween"),
            season: .autumn,
            categoryID: 3,
            backgroundColor: 0x8E44ADCC,
            textColor: 0xFFFFFFFF,
            repeatType: .yearly,
            repeatTime: 1,
            backgroundImageName: "predefined_star",
            reminder: .init(type: .everyYear, time: .oneDayEarly),
            month: 10,
            day: 31
        ),
        .init(
            id: "thanksgiving",
            emoji: "🦃",
            title: String(localized: "Thanksgiving"),
            season: .autumn,
            categoryID: 3,
            backgroundColor: 0xD35400CC,
            textColor: 0xFFFFFFFF,
            repeatType: .yearly,
            repeatTime: 1,
            backgroundImageName: "predefined_history",
            reminder: .init(type: .everyYear, time: .oneDayEarly),
            month: 11,
            day: 26
        ),
        .init(
            id: "spring_break",
            emoji: "🌸",
            title: String(localized: "Spring Break"),
            season: .spring,
            categoryID: nil,
            backgroundColor: 0xFF6B9DCC,
            textColor: 0xFFFFFFFF,
            repeatType: .nonRepeating,
            repeatTime: 1,
            backgroundImageName: "predefined_tekapo",
            reminder: .init(type: .onlyOnce, time: .threeDaysEarly),
            month: 4,
            day: 1
        ),
        .init(
            id: "summer_trip",
            emoji: "☀️",
            title: String(localized: "Summer Trip"),
            season: .summer,
            categoryID: nil,
            backgroundColor: 0x3498DBCC,
            textColor: 0xFFFFFFFF,
            repeatType: .nonRepeating,
            repeatTime: 1,
            backgroundImageName: "predefined_mt_cook",
            reminder: .init(type: .onlyOnce, time: .oneDayEarly),
            month: 7,
            day: 1
        ),
        .init(
            id: "back_to_school",
            emoji: "🎒",
            title: String(localized: "Back to School"),
            season: .autumn,
            categoryID: 3,
            backgroundColor: 0x2980B9CC,
            textColor: 0xFFFFFFFF,
            repeatType: .yearly,
            repeatTime: 1,
            backgroundImageName: "predefined_shakespeare",
            reminder: .init(type: .everyYear, time: .threeDaysEarly),
            month: 9,
            day: 1
        ),
        .init(
            id: "winter_holiday",
            emoji: "❄️",
            title: String(localized: "Winter Holiday"),
            season: .winter,
            categoryID: nil,
            backgroundColor: 0x5DADE2CC,
            textColor: 0xFFFFFFFF,
            repeatType: .nonRepeating,
            repeatTime: 1,
            backgroundImageName: "predefined_wanaka_tree",
            reminder: .init(type: .onlyOnce, time: .oneDayEarly),
            month: 12,
            day: 20
        ),
        .init(
            id: "sunrise",
            emoji: "🌅",
            title: String(localized: "Sunrise"),
            season: .anytime,
            categoryID: nil,
            backgroundColor: 0xFF6B9DCC,
            textColor: 0xFFFFFFFF,
            repeatType: .daily,
            repeatTime: 1,
            backgroundImageName: "predefined_mt_eden",
            reminder: .init(type: .everyDay, time: .fiveMinutesEarly),
            daysFromNow: 0
        ),
    ]
}
