//
// Created by Banghua Zhao on 07/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import SwiftUI
import SharingGRDB
import UserNotifications

@main
struct TimesMatterApp: App {
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        prepareDependencies {
            $0.defaultDatabase = try! appDatabase()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            content
        }
    }
    
    @ViewBuilder
    var content: some View {
        ZStack {
            NavigationStack {
                if #available(iOS 18.0, *) {
                    tabView18
                } else {
                    tabView
                }
            }
        }
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
                .tabItem{
                    Label("Countdowns", systemImage: "calendar")
                }
            
            MeView()
                .tabItem{
                    Label("Me", systemImage: "list.bullet")
                }
        }
    }
}
