import ActivityKit
import Foundation

@MainActor
enum LiveActivityService {
    private static var currentActivity: Activity<PomodoroActivityAttributes>?

    static func startWorkSession(endTime: Date) {
        stop()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ Live Activities not enabled")
            return
        }

        let attributes = PomodoroActivityAttributes(startTime: Date())
        let state = PomodoroActivityAttributes.ContentState(isBreak: false, endTime: endTime)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: endTime)
            )
            print("✅ Live Activity started: \(currentActivity?.id ?? "unknown")")
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
        }
    }

    static func startBreakSession(endTime: Date) {
        stop()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ Live Activities not enabled")
            return
        }

        let attributes = PomodoroActivityAttributes(startTime: Date())
        let state = PomodoroActivityAttributes.ContentState(isBreak: true, endTime: endTime)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: endTime)
            )
            print("✅ Break Live Activity started: \(currentActivity?.id ?? "unknown")")
        } catch {
            print("❌ Failed to start Break Live Activity: \(error)")
        }
    }

    static func stop() {
        Task {
            await currentActivity?.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }

    static func update(isBreak: Bool, endTime: Date) {
        let state = PomodoroActivityAttributes.ContentState(isBreak: isBreak, endTime: endTime)
        Task {
            await currentActivity?.update(.init(state: state, staleDate: endTime))
        }
    }
}
