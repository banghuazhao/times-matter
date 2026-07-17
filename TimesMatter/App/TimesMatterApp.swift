//
// Created by Banghua Zhao on 07/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import GoogleMobileAds
import Sharing
import SQLiteData
import SwiftUI
import UserNotifications

@main
struct TimesMatterApp: App {
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @Dependency(\.themeManager) private var themeManager
    @Dependency(\.purchaseManager) private var purchaseManager
    @Dependency(\.appRatingService) private var appRatingService
    @StateObject private var openAd = OpenAd()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        MobileAds.shared.start(completionHandler: nil)
        Self.migrateOnboardingFlagIfNeeded()
        prepareDependencies {
            $0.defaultDatabase = try! appDatabase()
        }
    }

    /// Existing installs already completed first launch — don't force onboarding after update.
    private static func migrateOnboardingFlagIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: "hasCompletedOnboarding") == nil else { return }
        if defaults.object(forKey: "isFirstLaunch") as? Bool == false {
            defaults.set(true, forKey: "hasCompletedOnboarding")
        }
    }

    var body: some Scene {
        WindowGroup {
            content
                .preferredColorScheme(darkModeEnabled ? .dark : .light)
                .task {
                    await purchaseManager.checkPurchaseStatus()
                    await purchaseManager.loadPremiumProduct()
                }
                .fullScreenCover(isPresented: Binding(
                    get: { !hasCompletedOnboarding },
                    set: { if !$0 { hasCompletedOnboarding = true } }
                )) {
                    OnboardingView {
                        hasCompletedOnboarding = true
                        appRatingService.recordMeaningfulAction(.completedOnboarding)
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        if !purchaseManager.isPremiumUserPurchased {
                            openAd.tryToPresentAd()
                        }
                        openAd.appHasEnterBackgroundBefore = false
                    } else if newPhase == .background {
                        openAd.appHasEnterBackgroundBefore = true
                    }
                }
        }
    }

    @ViewBuilder
    var content: some View {
        Group {
            if #available(iOS 18.0, *) {
                tabView18
            } else {
                tabView
            }
        }
        .background(themeManager.current.background)
        .tint(themeManager.current.primaryColor)
    }

    @available(iOS 18.0, *)
    var tabView18: some View {
        TabView {
            Tab {
                CountdownListView()
                    .onAppear {
                        AdManager.requestATTPermission(with: 3)
                    }
            } label: {
                Label("Countdowns", systemImage: "calendar")
            }

            Tab {
                InsightsView()
            } label: {
                Label("Today", systemImage: "sun.max.fill")
            }

            Tab {
                MeView()
                    .onAppear {
                        AdManager.requestATTPermission(with: 1)
                    }
            } label: {
                Label("Me", systemImage: "person.fill")
            }
        }
    }

    var tabView: some View {
        TabView {
            CountdownListView()
                .tabItem {
                    Label("Countdowns", systemImage: "calendar")
                }
                .onAppear {
                    AdManager.requestATTPermission(with: 3)
                }

            InsightsView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }

            MeView()
                .tabItem {
                    Label("Me", systemImage: "person.fill")
                }
                .onAppear {
                    AdManager.requestATTPermission(with: 1)
                }
        }
    }
}
