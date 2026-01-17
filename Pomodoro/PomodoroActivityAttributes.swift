import ActivityKit
import Foundation

// MARK: - Live Activity Attributes
// ⚠️ IMPORTANT: This struct is duplicated in PomodoroWidget/PomodoroWidgetLiveActivity.swift
// Both definitions MUST stay identical. Widget extensions cannot share code with the main app
// without a shared framework. Any changes here must be mirrored in the widget extension.

struct PomodoroWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var isBreak: Bool
        var endTime: Date
    }

    var startTime: Date
}
