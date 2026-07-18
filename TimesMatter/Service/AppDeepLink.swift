//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

enum AppDeepLink {
    static let scheme = "timesmatter"

    case countdown(id: Int)
    case home

    var url: URL {
        switch self {
        case .countdown(let id):
            URL(string: "\(Self.scheme)://countdown/\(id)")!
        case .home:
            URL(string: "\(Self.scheme)://home")!
        }
    }

    static func parse(_ url: URL) -> AppDeepLink? {
        guard url.scheme?.lowercased() == scheme else { return nil }
        let host = url.host?.lowercased() ?? ""
        let parts = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "countdown":
            if let idString = parts.first, let id = Int(idString) {
                return .countdown(id: id)
            }
            return .home
        case "home", "":
            return .home
        default:
            // Support timesmatter://countdown/123 style where "countdown" is host
            if host == "countdown", let idString = parts.first, let id = Int(idString) {
                return .countdown(id: id)
            }
            return nil
        }
    }
}
