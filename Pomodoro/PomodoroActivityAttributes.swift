import ActivityKit
import Foundation

// NOTE: This file must be added to both the main app target and the widget target
// to share the ActivityAttributes between them.

struct PomodoroActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let isBreak: Bool
        let endTime: Date
    }

    let startTime: Date
}
