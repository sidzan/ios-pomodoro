//
//  PomodoroWidgetLiveActivity.swift
//  PomodoroWidget
//

import ActivityKit
import WidgetKit
import SwiftUI

struct PomodoroWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var isBreak: Bool
        var endTime: Date
    }

    var startTime: Date
}

struct PomodoroWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroWidgetAttributes.self) { context in
            // Lock screen UI
            HStack(spacing: 16) {
                Image(systemName: context.state.isBreak ? "leaf.fill" : "timer")
                    .font(.system(size: 24))
                    .foregroundColor(context.state.isBreak ? .green : .red)

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.isBreak ? "Break" : "Focus")
                        .font(.headline)
                        .foregroundColor(context.state.isBreak ? .green : .red)

                    Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true)
                        .font(.system(size: 28, weight: .light))
                        .monospacedDigit()
                }

                Spacer()
            }
            .padding()
            .activityBackgroundTint(context.state.isBreak ? .green.opacity(0.2) : .red.opacity(0.2))

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(context.state.isBreak ? "Break" : "Focus")
                            .font(.headline)
                            .foregroundColor(context.state.isBreak ? .green : .red)

                        Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true)
                            .font(.system(size: 32, weight: .light))
                            .monospacedDigit()
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.isBreak ? "leaf.fill" : "timer")
                    .foregroundColor(context.state.isBreak ? .green : .red)
            } compactTrailing: {
                Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true)
                    .monospacedDigit()
                    .frame(width: 50)
            } minimal: {
                Image(systemName: context.state.isBreak ? "leaf.fill" : "timer")
                    .foregroundColor(context.state.isBreak ? .green : .red)
            }
        }
    }
}
