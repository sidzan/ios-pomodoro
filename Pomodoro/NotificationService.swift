import UserNotifications
import os.log

private let logger = Logger(subsystem: "com.sijan.pomodoro.Pomodoro", category: "Notifications")

// MARK: - Notification Service

enum NotificationService: NotificationServiceProtocol {
    private static let workCompleteIdentifier = "pomodoro.work.complete"
    private static let breakCompleteIdentifier = "pomodoro.break.complete"

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                logger.error("Failed to request notification permission: \(error.localizedDescription)")
            } else {
                logger.info("Notification permission granted: \(granted)")
            }
        }
    }

    static func scheduleWorkComplete(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Work Session Complete!"
        content.body = "Great job! Time for a break."
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, date.timeIntervalSinceNow),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: workCompleteIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                logger.error("Failed to schedule work notification: \(error.localizedDescription)")
            } else {
                logger.info("Work complete notification scheduled for \(date)")
            }
        }
    }

    static func scheduleBreakComplete(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Break Over!"
        content.body = "Ready to focus again?"
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, date.timeIntervalSinceNow),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: breakCompleteIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                logger.error("Failed to schedule break notification: \(error.localizedDescription)")
            } else {
                logger.info("Break complete notification scheduled for \(date)")
            }
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        logger.info("All pending notifications cancelled")
    }
}
