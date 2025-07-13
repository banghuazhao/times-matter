//
// Created by Banghua Zhao on 07/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SharingGRDB
import SwiftUI
import UserNotifications
import GoogleMobileAds

@main
struct TimesMatterApp: App {
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    @Dependency(\.themeManager) private var themeManager
    @Dependency(\.purchaseManager) private var purchaseManager
    @StateObject private var openAd = OpenAd()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        MobileAds.shared.start(completionHandler: nil)
        prepareDependencies {
            $0.defaultDatabase = try! appDatabase()
        }
    }

    var body: some Scene {
        WindowGroup {
            content
                .preferredColorScheme(darkModeEnabled ? .dark : .light)
                .task {
                    await requestNotificationPermissions()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    print("scenePhase: \(newPhase)")
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
            } label: {
                Label("Countdowns", systemImage: "calendar")
            }

            Tab {
                MeView()
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

            MeView()
                .tabItem {
                    Label("Me", systemImage: "list.bullet")
                }
        }
    }

    private func requestNotificationPermissions() async {
        await ReminderNotificationManager.shared.requestPermission()
        #if DEBUG
            await ReminderNotificationManager.shared.printAllNotifications()
        #endif
    }
}
