import Foundation
import UserNotifications

class ReminderNotificationManager {
    static let shared = ReminderNotificationManager()

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    func scheduleNotification(for countdown: Countdown) {
        let reminder = countdown.reminder
        guard reminder.type != .noReminder else { return }

        // Use next occurrence for repeating events so reminders aren't scheduled in the past.
        let eventDate = countdown.nextOccurrence ?? countdown.date
        let triggerDate = eventDate.addingTimeInterval(reminder.time.timeInterval)

        // Skip one-shot reminders that are already in the past.
        if reminder.type == .onlyOnce, triggerDate <= Date() {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = countdown.notificationTitle
        content.body = countdown.timeSummary
        if reminder.soundName != "Default" {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: reminder.soundName))
        } else {
            content.sound = .default
        }

        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)

        let trigger: UNNotificationTrigger
        switch reminder.type {
        case .onlyOnce:
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        case .everyDay:
            dateComponents.year = nil
            dateComponents.month = nil
            dateComponents.day = nil
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        case .everyWeek:
            dateComponents.year = nil
            dateComponents.month = nil
            // Keep weekday for weekly repeats.
            dateComponents.weekday = calendar.component(.weekday, from: triggerDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        case .everyMonth:
            dateComponents.year = nil
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        case .everyYear:
            dateComponents.year = nil
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        case .noReminder:
            return
        }

        let request = UNNotificationRequest(
            identifier: "countdown_\(countdown.id)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func removeNotification(for countdown: Countdown) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["countdown_\(countdown.id)"])
    }

    func rescheduleAll(for countdowns: [Countdown]) {
        for countdown in countdowns {
            removeNotification(for: countdown)
            scheduleNotification(for: countdown)
        }
    }

    func printAllNotifications() async {
        let notifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
        for notification in notifications {
            print("Notification ID: \(notification.identifier)")
            print("Title: \(notification.content.title)")
            print("Body: \(notification.content.body)")
            print("Trigger: \(String(describing: notification.trigger))")
        }
    }
}
