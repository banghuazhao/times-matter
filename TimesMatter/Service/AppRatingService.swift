//
// Created by Banghua Zhao on 31/05/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation
import Sharing
import StoreKit
import SwiftUI

enum RatingTrigger: String {
    case savedCountdown
    case sharedCard
    case completedOnboarding
    case enabledReminder
}

@Observable
class AppRatingService {
    @ObservationIgnored
    @Shared(.appStorage("ratePrepareTriggerCount")) private var ratePrepareTriggerCount: Int = 0
    @ObservationIgnored
    @Shared(.appStorage("lastRatingPromptDate")) private var lastRatingPromptDate: Date?
    @ObservationIgnored
    @Shared(.appStorage("hasRatedApp")) private var hasRatedApp: Bool = false
    @ObservationIgnored
    @Shared(.appStorage("referralShareCount")) private var referralShareCount: Int = 0

    private let minimumDaysBetweenPrompts: TimeInterval = 30 * 24 * 60 * 60

    /// Call after meaningful positive moments (save, share, onboarding).
    func recordMeaningfulAction(_ trigger: RatingTrigger) {
        $ratePrepareTriggerCount.withLock { $0 += 1 }

        if trigger == .sharedCard {
            $referralShareCount.withLock { $0 += 1 }
        }

        // Onboarding: wait a beat so the success UI settles.
        let delay: TimeInterval = trigger == .completedOnboarding ? 1.2 : 0.35
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.checkAndShowRatingPrompt(forceSoft: trigger == .sharedCard || trigger == .completedOnboarding)
        }
    }

    /// Legacy entry point used by save flows.
    func incrementPrepareTriggerCount() {
        recordMeaningfulAction(.savedCountdown)
    }

    private func checkAndShowRatingPrompt(forceSoft: Bool = false) {
        guard !hasRatedApp else { return }

        if let lastPrompt = lastRatingPromptDate {
            let daysSinceLastPrompt = Date().timeIntervalSince(lastPrompt)
            if daysSinceLastPrompt < minimumDaysBetweenPrompts {
                return
            }
        }

        // Soft moments can prompt earlier; otherwise every 3 meaningful actions.
        if forceSoft {
            if ratePrepareTriggerCount < 1 { return }
        } else {
            guard ratePrepareTriggerCount.isMultiple(of: 3) else { return }
        }

        showRatingPrompt()
    }

    private func showRatingPrompt() {
        $lastRatingPromptDate.withLock { $0 = Date() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.requestRating()
        }
    }

    @MainActor
    func requestRating() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        if #available(iOS 18, *) {
            AppStore.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    func openAppStoreReview() {
        let appID = Constants.AppID.thisAppID
        let reviewURL = "https://itunes.apple.com/app/id\(appID)?action=write-review"
        if let url = URL(string: reviewURL) {
            UIApplication.shared.open(url)
        }
    }

    func openAppStorePage() {
        let appID = Constants.AppID.thisAppID
        let appURL = "https://apps.apple.com/app/id\(appID)"
        if let url = URL(string: appURL) {
            UIApplication.shared.open(url)
        }
    }

    var shareReferralURL: URL? {
        URL(string: "https://apps.apple.com/app/id\(Constants.AppID.thisAppID)")
    }

    var shareReferralMessage: String {
        String(localized: "I’ve been using Times Matter to track countdowns and reminders. Try it free:")
    }

    func resetRatingState() {
        $ratePrepareTriggerCount.withLock { $0 = 0 }
        $lastRatingPromptDate.withLock { $0 = nil }
        $hasRatedApp.withLock { $0 = false }
    }

    var userHasRated: Bool {
        hasRatedApp
    }
}

extension DependencyValues {
    var appRatingService: AppRatingService {
        get { self[AppRatingServiceKey.self] }
        set { self[AppRatingServiceKey.self] = newValue }
    }
}

private enum AppRatingServiceKey: DependencyKey {
    static let liveValue = AppRatingService()
}
