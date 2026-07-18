//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation
import Observation

@Observable
final class DeepLinkRouter: @unchecked Sendable {
    /// Selected main tab: 0 Countdowns, 1 Today, 2 Me
    var selectedTab: Int = 0
    /// Countdown ID requested via widget / URL; consumed by CountdownListView.
    var pendingCountdownID: Int?

    @MainActor
    func handle(_ url: URL) {
        guard let link = AppDeepLink.parse(url) else { return }
        switch link {
        case .home:
            selectedTab = 0
            pendingCountdownID = nil
        case .countdown(let id):
            selectedTab = 0
            pendingCountdownID = id
        }
    }

    @MainActor
    func consumePendingCountdownID() -> Int? {
        let id = pendingCountdownID
        pendingCountdownID = nil
        return id
    }
}

extension DependencyValues {
    var deepLinkRouter: DeepLinkRouter {
        get { self[DeepLinkRouterKey.self] }
        set { self[DeepLinkRouterKey.self] = newValue }
    }
}

private enum DeepLinkRouterKey: DependencyKey {
    static let liveValue = DeepLinkRouter()
}
