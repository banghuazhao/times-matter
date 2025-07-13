//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

struct CountdownStore {
    static let testMinute = Countdown.Draft(
        title: "Test minute",
        date: Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date(),
        backgroundColor: 0xFF6B9DCC,
        textColor: 0xFFFFFFFFFF,
        backgroundImageName: "aurora"
    )

    static let testSecond = Countdown.Draft(
        title: "🔧 Test second",
        date: Calendar.current.date(byAdding: .second, value: 10, to: Date()) ?? Date(),
        backgroundColor: 0xFF6B9DCC,
        textColor: 0xFFFFFFFFFF,
        backgroundImageName: "star"
    )

    static let seed: [Countdown.Draft] = [
        testMinute,
        testSecond,

        // Birthday countdowns
        .init(
            title: "👩🎂 Mom's Birthday",
            date: Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date(),
            categoryID: 2, // Birthday category
            backgroundColor: 0xFF6B9DCC,
            textColor: 0xFFFFFFFFFF,
            isFavorite: true,
            repeatType: .yearly,
            backgroundImageName: "holiday"
        ),

        .init(
            title: "👨🎂 Dad's Birthday",
            date: Calendar.current.date(byAdding: .day, value: 45, to: Date()) ?? Date(),
            categoryID: 2, // Birthday category
            backgroundColor: 0xFF4ECDC4CC,
            textColor: 0xFFFFFFFFFF,
            isFavorite: false,
            repeatType: .yearly,
            backgroundImageName: "mt_cook"
        ),

        // Anniversary countdowns
        .init(
            title: "💍 Wedding Anniversary",
            date: Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date(),
            categoryID: 1, // Anniversary category
            backgroundColor: 0xFFE74C3CCC,
            textColor: 0xFFFFFFFFFF,
            isFavorite: true,
            repeatType: .yearly,
            backgroundImageName: "relationship"
        ),


        // Work countdowns
        .init(
            title: "Project Deadline",
            date: Calendar.current.date(byAdding: .weekOfYear, value: -3, to: Date()) ?? Date(),
            categoryID: 3, // Work category
            backgroundColor: 0xFF34495ECC,
            textColor: 0xFFFFFFFFFF,
            isFavorite: false,
            repeatType: .nonRepeating,
            backgroundImageName: "mercer_bay"
        ),

        .init(
            title: "Team Meeting",
            date: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
            categoryID: 3, // Work category
            backgroundColor: 0xFF95A5A6CC,
            textColor: 0xFFFFFFFFFF,
            isFavorite: false,
            repeatType: .weekly
        ),

        // Reminder countdowns
        .init(
            title: "🦷 Dentist Appointment",
            date: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            categoryID: 4, // Reminders category
            backgroundColor: 0xFF1ABC9CCC,
            textColor: 0xFFFFFFFFFF,
            isFavorite: false,
            repeatType: .yearly,
            repeatTime: 2,
            backgroundImageName: "tekapo"
        ),

        .init(
            title: "🚗 Car Service",
            date: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            categoryID: 4, // Reminders category
            backgroundColor: 0xFFE67E22CC,
            textColor: 0xFFFFFFFFFF,
            isFavorite: false,
            repeatType: .monthly
        ),

        // Personal countdowns
        .init(
            title: "🏖️ Vacation",
            date: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
            categoryID: nil, // No category
            backgroundColor: 0xFF2ECC71CC,
            textColor: 0xFFFFFFFFFF,
            isFavorite: true,
            repeatType: .nonRepeating,
            backgroundImageName: "taupo"
        ),

        .init(
            title: "🎆 New Year",
            date: Calendar.current.date(byAdding: .month, value: 5, to: Date()) ?? Date(),
            categoryID: nil, // No category
            backgroundColor: 0xFF9B59B6CC,
            textColor: 0xFFFFFFFFFF,
            isFavorite: true,
            repeatType: .yearly,
            backgroundImageName: "wanaka_tree"
        ),
    ]
}
