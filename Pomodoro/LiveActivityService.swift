import ActivityKit
import Foundation
import os.log

private let logger = Logger(subsystem: "com.sijan.pomodoro.Pomodoro", category: "LiveActivity")

@available(iOS 16.1, *)
@MainActor
enum LiveActivityService {
    private static var currentActivity: Activity<PomodoroWidgetAttributes>?

    static func startWorkSession(endTime: Date) {
        logger.info("🍅 startWorkSession called")

        // End any existing activity first
        stop()

        // Check if Live Activities are enabled
        let authInfo = ActivityAuthorizationInfo()
        logger.info("🍅 areActivitiesEnabled: \(authInfo.areActivitiesEnabled)")
        logger.info("🍅 frequentPushesEnabled: \(authInfo.frequentPushesEnabled)")

        guard authInfo.areActivitiesEnabled else {
            logger.warning("⚠️ Live Activities not enabled on this device")
            return
        }

        // Check for any existing activities
        let existingActivities = Activity<PomodoroWidgetAttributes>.activities
        logger.info("🍅 Existing activities count: \(existingActivities.count)")
        for activity in existingActivities {
            logger.info("🍅 Existing activity: \(activity.id), state: \(String(describing: activity.activityState))")
        }

        let attributes = PomodoroWidgetAttributes(startTime: Date())
        let state = PomodoroWidgetAttributes.ContentState(isBreak: false, endTime: endTime)
        let content = ActivityContent(state: state, staleDate: endTime)

        do {
            logger.info("🍅 Requesting Live Activity...")
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            logger.info("✅ Live Activity started successfully!")
            logger.info("✅ Activity ID: \(currentActivity?.id ?? "nil")")
            logger.info("✅ Activity state: \(String(describing: currentActivity?.activityState))")
        } catch {
            logger.error("❌ Failed to start Live Activity: \(error.localizedDescription)")
            logger.error("❌ Full error: \(String(describing: error))")
        }
    }

    static func startBreakSession(endTime: Date) {
        logger.info("🍃 startBreakSession called")

        stop()

        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else {
            logger.warning("⚠️ Live Activities not enabled on this device")
            return
        }

        let attributes = PomodoroWidgetAttributes(startTime: Date())
        let state = PomodoroWidgetAttributes.ContentState(isBreak: true, endTime: endTime)
        let content = ActivityContent(state: state, staleDate: endTime)

        do {
            logger.info("🍃 Requesting Break Live Activity...")
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            logger.info("✅ Break Live Activity started: \(currentActivity?.id ?? "nil")")
        } catch {
            logger.error("❌ Failed to start Break Live Activity: \(error.localizedDescription)")
        }
    }

    static func stop() {
        logger.info("🛑 stop() called")
        if let activity = currentActivity {
            logger.info("🛑 Ending activity: \(activity.id)")
            Task {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
        currentActivity = nil
    }

    static func update(isBreak: Bool, endTime: Date) {
        guard let activity = currentActivity else {
            logger.warning("⚠️ No current activity to update")
            return
        }

        let state = PomodoroWidgetAttributes.ContentState(isBreak: isBreak, endTime: endTime)
        Task {
            await activity.update(.init(state: state, staleDate: endTime))
            logger.info("🔄 Activity updated")
        }
    }
}
