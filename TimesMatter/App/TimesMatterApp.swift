//
// Created by Banghua Zhao on 07/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import SwiftUI

@main
struct TimesMatterApp: App {
    var body: some Scene {
        WindowGroup {
            content
        }
    }
    
    @ViewBuilder
    var content: some View {
        ZStack {
            Group {
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
