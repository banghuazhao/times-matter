//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

struct CountdownStore {
    static let testSecond = Countdown.Draft(
        title: "🔧 Test second",
        date: Calendar.current.date(byAdding: .second, value: 10, to: Date()) ?? Date(),
        backgroundColor: 0xFF6B9DCC,
        textColor: 0xFFFFFFFF,
        backgroundImageName: "predefined_star",
        layout: .bottom
    )
    
    static let christmas = Countdown.Draft(
        title: "🎄 Christmas",
        date: Calendar.current.nextDate(after: Date(), matching: DateComponents(month: 12, day: 25, hour: 0, minute: 0), matchingPolicy: .nextTimePreservingSmallerComponents) ?? Date(),
        categoryID: 3,
        backgroundColor: 0x9B59B6CC,
        textColor: 0xFFFFFFFF,
        isFavorite: true,
        repeatType: .yearly,
        backgroundImageName: "predefined_holiday",
        reminder: .init(type: .everyYear, time: .oneDayEarly)
    )

    static let newYear = Countdown.Draft(
        title: "🎆 New Year",
        date: Calendar.current.nextDate(after: Date(), matching: DateComponents(month: 1, day: 1, hour: 0, minute: 0), matchingPolicy: .nextTimePreservingSmallerComponents) ?? Date(),
        categoryID: 3,
        backgroundColor: 0x9B59B6CC,
        textColor: 0xFFFFFFFF,
        isFavorite: true,
        repeatType: .yearly,
        backgroundImageName: "predefined_wanaka_tree",
        reminder: .init(type: .everyYear, time: .thirtyMinutesEarly)
    )

    static let longPressToEdit = Countdown.Draft(
        title: "👆 Long press to edit",
        date: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
        backgroundColor: 0xFF6B9DCC,
        textColor: 0xFFFFFFFF,
        isFavorite: false,
        repeatType: .nonRepeating,
        backgroundImageName: "predefined_star",
        reminder: .init(type: .onlyOnce, time: .atEventTime)
    )

    static let firstUse = Countdown.Draft(
        title: "🚀 First use this app",
        date: Date(),
        categoryID: 1,
        backgroundColor: 0x2ECC71CC,
        textColor: 0xFFFFFFFF,
        isFavorite: false,
        repeatType: .yearly,
        backgroundImageName: "predefined_aurora",
        reminder: .init(type: .everyYear, time: .atEventTime, soundName: "Sunny Step.mp3")
    )
    
    static let seedLive: [Countdown.Draft] = [
        firstUse,
        longPressToEdit,
        christmas,
        newYear
    ]

    static let seedDebug: [Countdown.Draft] = [
        testSecond,

        // Birthday countdowns
        .init(
            title: "👩🎂 Mom's Birthday",
            date: Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date(),
            categoryID: 2, // Birthday category
            backgroundColor: 0xFF6B9DCC,
            textColor: 0xFFFFFFFF,
            isFavorite: true,
            repeatType: .yearly
        ),

        .init(
            title: "👨🎂 Dad's Birthday",
            date: Calendar.current.date(byAdding: .day, value: 45, to: Date()) ?? Date(),
            categoryID: 2, // Birthday category
            backgroundColor: 0x4ECDC4CC,
            textColor: 0xFFFFFFFF,
            isFavorite: false,
            repeatType: .yearly
        ),

        // Anniversary countdowns
        .init(
            title: "💍 Wedding Anniversary",
            date: Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date(),
            categoryID: 1, // Anniversary category
            backgroundColor: 0xE74C3CCC,
            textColor: 0xFFFFFFFF,
            isFavorite: true,
            repeatType: .yearly,
            backgroundImageName: "predefined_relationship",
            layout: .top
        ),


        // Reminder countdowns
        .init(
            title: "🦷 Dentist Appointment",
            date: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            categoryID: 4, // Reminders category
            backgroundColor: 0x1ABC9CCC,
            textColor: 0xFFFFFFFF,
            isFavorite: false,
            repeatType: .yearly,
            repeatTime: 2,
            backgroundImageName: "predefined_tekapo"
        ),

        .init(
            title: "🚗 Car Service",
            date: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            categoryID: 4, // Reminders category
            backgroundColor: 0xE67E22CC,
            textColor: 0xFFFFFFFF,
            isFavorite: false,
            repeatType: .monthly
        ),

        // Personal countdowns
        .init(
            title: "🏖️ Vacation",
            date: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
            categoryID: nil, // No category
            backgroundColor: 0x2ECC71CC,
            textColor: 0xFFFFFFFF,
            isFavorite: true,
            repeatType: .nonRepeating,
            backgroundImageName: "predefined_taupo",
            layout: .bottom
        ),
    ]
}
