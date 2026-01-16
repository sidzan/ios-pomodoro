import ActivityKit
import Foundation

@MainActor
enum LiveActivityService {
    private static var currentActivity: Activity<PomodoroActivityAttributes>?

    static func startWorkSession(endTime: Date) {
        stop()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = PomodoroActivityAttributes(startTime: Date())
        let state = PomodoroActivityAttributes.ContentState(isBreak: false, endTime: endTime)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: endTime)
            )
        } catch {
            // Fail silently
        }
    }

    static func startBreakSession(endTime: Date) {
        stop()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = PomodoroActivityAttributes(startTime: Date())
        let state = PomodoroActivityAttributes.ContentState(isBreak: true, endTime: endTime)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: endTime)
            )
        } catch {
            // Fail silently
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
