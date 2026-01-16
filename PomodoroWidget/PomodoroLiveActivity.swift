//
//  PomodoroLiveActivity.swift
//  PomodoroWidget
//

import ActivityKit
import WidgetKit
import SwiftUI

struct PomodoroLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroActivityAttributes.self) { context in
            // Simplest possible lock screen view
            HStack {
                Text("🍅")
                Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true)
                    .font(.title)
                    .monospacedDigit()
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text("Focus Time")
                }
            } compactLeading: {
                Text("🍅")
            } compactTrailing: {
                Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true)
                    .monospacedDigit()
            } minimal: {
                Text("🍅")
            }
        }
    }
}
