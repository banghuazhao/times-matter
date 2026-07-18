//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

enum AppDeepLink {
    static let scheme = "timesmatter"

    static func countdownURL(id: Int) -> URL {
        URL(string: "\(scheme)://countdown/\(id)")!
    }

    static var homeURL: URL {
        URL(string: "\(scheme)://home")!
    }
}
