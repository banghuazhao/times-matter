//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

struct CountdownStore {
    static let seed: [Countdown.Draft] = [
        .init(
            title: "Test minute",
            icon: "🔧",
            date: Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date(),
            backgroundColor: 0xFF6B9DCC,
            textColor: 0xFFFFFFFFFF
        ),

        .init(
            title: "Test second",
            icon: "🔧",
            date: Calendar.current.date(byAdding: .second, value: 10, to: Date()) ?? Date(),
            backgroundColor: 0xFF6B9DCC,
            textColor: 0xFFFFFFFFFF
        ),

        // Birthday countdowns
        .init(
            title: "Mom's Birthday",
            icon: "🎂",
            date: Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date(),
            categoryID: 2, // Birthday category
            backgroundColor: 0xFF6B9DCC,
            textColor: 0xFFFFFFFFFF,
            isFavorite: true,
            repeatType: .yearly
        ),

        .init(
            title: "Dad's Birthday",
            icon: "🎉",
            date: Calendar.current.date(byAdding: .day, value: 45, to: Date()) ?? Date(),
            categoryID: 2, // Birthday category
            backgroundColor: 0xFF4ECDC4CC,
            textColor: 0xFFFFFFFFFF,
            isFavorite: false,
            repeatType: .yearly
        ),

        // Anniversary countdowns
        .init(
            title: "Wedding Anniversary",
            icon: "💍",
            date: Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date(),
            categoryID: 1, // Anniversary category
            backgroundColor: 0xFFE74C3CCC,
            textColor: 0xFFFFFFFFFF,
            isFavorite: true,
            repeatType: .yearly
        ),

        .init(
            title: "First Date Anniversary",
            icon: "💕",
            date: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date(),
            categoryID: 1, // Anniversary category
            backgroundColor: 0xFFF39C12CC,
            textColor: 0xFFFFFFFFFF,
            isFavorite: false,
            repeatType: .yearly
        ),

        // Work countdowns
        .init(
            title: "Project Deadline",
            icon: "📋",
            date: Calendar.current.date(byAdding: .weekOfYear, value: -3, to: Date()) ?? Date(),
            categoryID: 3, // Work category
            backgroundColor: 0xFF34495ECC,
            textColor: 0xFFFFFFFFFF,
            isFavorite: false,
            repeatType: .none
        ),

        .init(
            title: "Team Meeting",
            icon: "👥",
            date: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
            categoryID: 3, // Work category
            backgroundColor: 0xFF95A5A6CC,
            textColor: 0xFFFFFFFFFF,
            isFavorite: false,
            repeatType: .weekly
        ),

        // Reminder countdowns
        .init(
            title: "Dentist Appointment",
            icon: "🦷",
            date: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            categoryID: 4, // Reminders category
            backgroundColor: 0xFF1ABC9CCC,
            textColor: 0xFFFFFFFFFF,
            isFavorite: false,
            repeatType: .customMonths,
            customInterval: 6
        ),

        .init(
            title: "Car Service",
            icon: "🚗",
            date: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            categoryID: 4, // Reminders category
            backgroundColor: 0xFFE67E22CC,
            textColor: 0xFFFFFFFFFF,
            isFavorite: false,
            repeatType: .customMonths,
            customInterval: 12
        ),

        // Personal countdowns
        .init(
            title: "Vacation",
            icon: "🏖️",
            date: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
            categoryID: nil, // No category
            backgroundColor: 0xFF2ECC71CC,
            textColor: 0xFFFFFFFFFF,
            isFavorite: true,
            repeatType: .none
        ),

        .init(
            title: "New Year",
            icon: "🎆",
            date: Calendar.current.date(byAdding: .month, value: 5, to: Date()) ?? Date(),
            categoryID: nil, // No category
            backgroundColor: 0xFF9B59B6CC,
            textColor: 0xFFFFFFFFFF,
            isFavorite: true,
            repeatType: .yearly
        ),
    ]
}
