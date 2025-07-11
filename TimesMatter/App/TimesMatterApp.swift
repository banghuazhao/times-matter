//
// Created by Banghua Zhao on 07/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SharingGRDB
import SwiftUI

@main
struct TimesMatterApp: App {
    @Dependency(\.themeManager) var themeManager
    @StateObject private var openAd = OpenAd()

    init() {
        prepareDependencies {
            $0.defaultDatabase = try! appDatabase()
        }
        openAd.requestAppOpenAd()
    }

    var body: some Scene {
        WindowGroup {
            content
                .preferredColorScheme(themeManager.darkModeEnabled ? .dark : .light)
                .onAppear {
                              // Load the first ad on initial launch
                              openAd.requestAppOpenAd()
                          }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                               openAd.appHasEnterBackgroundBefore = true
                           }
                           .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                               openAd.tryToPresentAd()
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
