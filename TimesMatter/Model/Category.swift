//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import Foundation
import SharingGRDB

@Table
struct Category: Identifiable {
    let id: Int
    var title: String = ""
}
extension Category.Draft: Identifiable {}
