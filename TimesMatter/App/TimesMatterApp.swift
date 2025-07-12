//
// Created by Banghua Zhao on 07/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SharingGRDB
import SwiftUI
import GoogleMobileAds

@main
struct TimesMatterApp: App {
    @Dependency(\.themeManager) var themeManager
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
                .preferredColorScheme(themeManager.darkModeEnabled ? .dark : .light)
                .onChange(of: scenePhase) { _, newPhase in
                    print("scenePhase: \(newPhase)")
                    if newPhase == .active {
                        openAd.tryToPresentAd()
                        openAd.appHasEnterBackgroundBefore = false
                    } else if newPhase == .background {
                        openAd.appHasEnterBackgroundBefore = true
                    }
                }
        }
    }

    @ViewBuilder
    var content: some View {
        ZStack {
            if #available(iOS 18.0, *) {
                tabView18
            } else {
                tabView
            }
        }
        .tint(ThemeManager.shared.current.primaryColor)
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
}
