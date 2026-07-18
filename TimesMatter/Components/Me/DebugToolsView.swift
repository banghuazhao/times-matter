//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

#if DEBUG
import Dependencies
import Sharing
import SQLiteData
import SwiftUI
import UIKit
import UserNotifications
import WidgetKit

@Observable
@MainActor
final class DebugToolsModel {
    @ObservationIgnored
    @FetchAll(Countdown.all) var allCountdowns

    @ObservationIgnored
    @FetchAll(Category.all) var allCategories

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    @ObservationIgnored
    @Dependency(\.purchaseManager) var purchaseManager

    @ObservationIgnored
    @Dependency(\.appRatingService) var appRatingService

    @ObservationIgnored
    @Dependency(\.themeManager) var themeManager

    @ObservationIgnored
    @Shared(.appStorage("hasCompletedOnboarding")) var hasCompletedOnboarding = false

    @ObservationIgnored
    @Shared(.appStorage("isFirstLaunch")) var isFirstLaunch = true

    var statusMessage: String?
    var pendingNotificationCount: Int = 0

    var debugSeedCount: Int {
        allCountdowns.filter { CountdownStore.debugSeedTitles.contains($0.title) }.count
    }

    var databasePath: String {
        URL.documentsDirectory.appending(component: "db.sqlite").path()
    }

    func refreshNotificationCount() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        pendingNotificationCount = requests.count
    }

    func removeDebugSeeds() {
        withErrorReporting {
            let toDelete = allCountdowns.filter { CountdownStore.debugSeedTitles.contains($0.title) }
            try database.write { db in
                for countdown in toDelete {
                    try Countdown.delete(countdown).execute(db)
                }
            }
            for countdown in toDelete {
                ReminderNotificationManager.shared.removeNotification(for: countdown)
            }
            syncWidgets()
            statusMessage = "Removed \(toDelete.count) debug seed countdown(s)."
        }
    }

    func reapplyDebugSeeds() {
        removeDebugSeeds()
        withErrorReporting {
            try database.write { db in
                for draft in CountdownStore.seedDebug {
                    let saved = try Countdown
                        .insert { draft }
                        .returning { $0 }
                        .fetchOne(db)
                    if let saved {
                        ReminderNotificationManager.shared.scheduleNotification(for: saved)
                    }
                }
            }
            syncWidgets()
            statusMessage = "Reapplied \(CountdownStore.seedDebug.count) debug seed countdown(s)."
        }
    }

    func clearAllCountdowns() {
        withErrorReporting {
            let all = allCountdowns
            try database.write { db in
                try Countdown.delete().execute(db)
            }
            for countdown in all {
                ReminderNotificationManager.shared.removeNotification(for: countdown)
            }
            syncWidgets()
            statusMessage = "Deleted all \(all.count) countdown(s)."
        }
    }

    func resetOnboarding() {
        $hasCompletedOnboarding.withLock { $0 = false }
        statusMessage = "Onboarding flag cleared. Relaunch or kill the app to see onboarding."
    }

    func resetFirstLaunchReminders() {
        $isFirstLaunch.withLock { $0 = true }
        statusMessage = "isFirstLaunch = true. Open Countdowns tab to reschedule reminders."
    }

    func togglePremium() {
        let next = !purchaseManager.isPremiumUserPurchased
        purchaseManager.$isPremiumUserPurchased.withLock { $0 = next }
        statusMessage = next ? "Premium ON (debug override)." : "Premium OFF (debug override)."
    }

    func reloadWidgets() {
        syncWidgets()
        WidgetCenter.shared.reloadAllTimelines()
        statusMessage = "Widget timelines reloaded."
    }

    func rescheduleAllNotifications() {
        ReminderNotificationManager.shared.rescheduleAll(for: allCountdowns)
        Task {
            await refreshNotificationCount()
            statusMessage = "Rescheduled notifications for \(allCountdowns.count) countdown(s). Pending: \(pendingNotificationCount)."
        }
    }

    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        Task {
            await refreshNotificationCount()
            statusMessage = "Cleared all pending/delivered notifications."
        }
    }

    func dumpNotifications() async {
        await ReminderNotificationManager.shared.printAllNotifications()
        await refreshNotificationCount()
        statusMessage = "Printed \(pendingNotificationCount) pending notification(s) to console."
    }

    func resetRatingState() {
        appRatingService.resetRatingState()
        statusMessage = "Rating prompt state reset."
    }

    func copyDatabasePath() {
        UIPasteboard.general.string = databasePath
        statusMessage = "Database path copied to pasteboard."
    }

    func syncWidgets() {
        WidgetDataExporter.export(countdowns: allCountdowns)
    }
}

struct DebugToolsView: View {
    @State private var model = DebugToolsModel()
    @State private var confirmClearAll = false

    var body: some View {
        List {
            Section {
                LabeledContent("Countdowns", value: "\(model.allCountdowns.count)")
                LabeledContent("Debug seeds", value: "\(model.debugSeedCount)")
                LabeledContent("Categories", value: "\(model.allCategories.count)")
                LabeledContent("Premium", value: model.purchaseManager.isPremiumUserPurchased ? "Yes" : "No")
                LabeledContent("Onboarding done", value: model.hasCompletedOnboarding ? "Yes" : "No")
                LabeledContent("Pending notifications", value: "\(model.pendingNotificationCount)")
            } header: {
                Text("Status")
            }

            Section {
                Button("Remove Debug Seeds") {
                    model.removeDebugSeeds()
                }
                Button("Reapply Debug Seeds") {
                    model.reapplyDebugSeeds()
                }
                Button("Clear All Countdowns", role: .destructive) {
                    confirmClearAll = true
                }
            } header: {
                Text("Seeds & Data")
            } footer: {
                Text("Debug seeds are matched by title from CountdownStore.seedDebug.")
            }

            Section("App Flags") {
                Button("Reset Onboarding") {
                    model.resetOnboarding()
                }
                Button("Reset First-Launch Reminders Flag") {
                    model.resetFirstLaunchReminders()
                }
                Button("Toggle Premium Override") {
                    model.togglePremium()
                }
                Button("Reset Rating Prompts") {
                    model.resetRatingState()
                }
            }

            Section("Notifications & Widgets") {
                Button("Reschedule All Notifications") {
                    model.rescheduleAllNotifications()
                }
                Button("Clear All Notifications", role: .destructive) {
                    model.clearAllNotifications()
                }
                Button("Dump Notifications to Console") {
                    Task { await model.dumpNotifications() }
                }
                Button("Reload Widgets") {
                    model.reloadWidgets()
                }
            }

            Section("Database") {
                Text(model.databasePath)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Button("Copy Database Path") {
                    model.copyDatabasePath()
                }
            }

            if let statusMessage = model.statusMessage {
                Section("Last Action") {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Debug Tools")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await model.refreshNotificationCount()
        }
        .confirmationDialog(
            "Delete every countdown?",
            isPresented: $confirmClearAll,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                model.clearAllCountdowns()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    NavigationStack {
        DebugToolsView()
    }
}
#endif
