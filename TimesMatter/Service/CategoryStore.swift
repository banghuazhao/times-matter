//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import Foundation

struct CategoryStore {
    static let seed: [Category.Draft] = [
        .init(id: 1, title: String(localized: "Anniversary"), icon: "📅"),
        .init(id: 2, title: String(localized: "Birthday"), icon: "🎂"),
        .init(id: 3, title: String(localized: "Work"), icon: "💼"),
        .init(id: 4, title: String(localized: "Reminders"), icon: "⏰")
    ]
}
