import UserNotifications

enum NotificationService {
    private static let workCompleteIdentifier = "pomodoro.work.complete"
    private static let breakCompleteIdentifier = "pomodoro.break.complete"

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func scheduleWorkComplete(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Work Session Complete!"
        content.body = "Great job! Time for a break."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, date.timeIntervalSinceNow),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: workCompleteIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { _ in }
    }

    static func scheduleBreakComplete(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Break Over!"
        content.body = "Ready to focus again?"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, date.timeIntervalSinceNow),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: breakCompleteIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { _ in }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
