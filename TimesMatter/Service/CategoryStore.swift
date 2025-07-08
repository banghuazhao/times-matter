//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import Foundation

struct CategoryStore {
    static let seed: [Category.Draft] = [
        .init(title: String(localized: "Anniversary")),
        .init(title: String(localized: "Birthday")),
        .init(title: String(localized: "Work")),
        .init(title: String(localized: "Reminders"))
    ]
}
