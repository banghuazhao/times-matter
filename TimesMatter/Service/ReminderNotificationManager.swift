import Foundation
import UserNotifications

class ReminderNotificationManager {
    static let shared = ReminderNotificationManager()

    func scheduleNotification(for countdown: Countdown) {
        let reminder = countdown.reminder
        guard reminder.type != .noReminder else { return }

        let content = UNMutableNotificationContent()
        content.title = countdown.notificationTitle
        content.body = countdown.timeSummary
        if reminder.soundName != "Default" {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: reminder.soundName))
        } else {
            content.sound = .default
        }

        let triggerDate = countdown.date.addingTimeInterval(reminder.time.timeInterval)
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
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        case .everyMonth:
            dateComponents.year = nil
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        case .everyYear:
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        default:
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
} 
