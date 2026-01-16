import ActivityKit
import Foundation

// Must match PomodoroWidgetAttributes in widget extension exactly
struct PomodoroWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var isBreak: Bool
        var endTime: Date
    }

    var startTime: Date
}
