//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  
import Foundation
import SharingGRDB

@Table
struct Countdown: Identifiable {
    let id: Int
    var title: String = ""
    var icon: String = "⏰"
    var categoryID: Category.ID?
    var backgroundColor: Int = 0x2ECC71CC
    var textColor: Int = 0xFFFFFFFFFF
    var isFavorite: Bool = false
    var isArchived: Bool = false
}
extension Countdown.Draft: Identifiable {}
