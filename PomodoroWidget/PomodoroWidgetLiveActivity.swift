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
            VStack(spacing: 12) {
                // Top row: Label only
                HStack {
                    Text(context.state.isBreak ? "Break" : "Focus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(context.state.isBreak ? .green : Color(red: 0.91, green: 0.30, blue: 0.24))

                    Spacer()
                }

                // Timer - bigger and bolder
                Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true)
                    .font(.system(size: 44, weight: .semibold))
                    .monospacedDigit()
                    .foregroundColor(.white)

                // Progress bar
                GeometryReader { geometry in
                    let totalDuration = context.state.endTime.timeIntervalSince(context.attributes.startTime)
                    let elapsed = Date.now.timeIntervalSince(context.attributes.startTime)
                    let progress = min(max(elapsed / totalDuration, 0), 1)

                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 6)

                        // Progress fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(context.state.isBreak ? Color.green : Color(red: 0.91, green: 0.30, blue: 0.24))
                            .frame(width: geometry.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
            .padding()
            .activityBackgroundTint(context.state.isBreak ? .green.opacity(0.3) : Color(red: 0.91, green: 0.30, blue: 0.24).opacity(0.3))

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Text("P")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(context.state.isBreak ? .green : Color(red: 0.91, green: 0.30, blue: 0.24))

                        Text(context.state.isBreak ? "Break" : "Focus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(context.state.isBreak ? .green : Color(red: 0.91, green: 0.30, blue: 0.24))
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true)
                        .font(.system(size: 28, weight: .semibold))
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // Progress bar
                    GeometryReader { geometry in
                        let totalDuration = context.state.endTime.timeIntervalSince(context.attributes.startTime)
                        let elapsed = Date.now.timeIntervalSince(context.attributes.startTime)
                        let progress = min(max(elapsed / totalDuration, 0), 1)

                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(context.state.isBreak ? Color.green : Color(red: 0.91, green: 0.30, blue: 0.24))
                                .frame(width: geometry.size.width * progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                    .padding(.top, 8)
                }
            } compactLeading: {
                Text("P")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(context.state.isBreak ? .green : Color(red: 0.91, green: 0.30, blue: 0.24))
                    .padding(.leading, 4)
            } compactTrailing: {
                Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true)
                    .font(.system(size: 14, weight: .semibold))
                    .monospacedDigit()
                    .frame(width: 50)
            } minimal: {
                Text("P")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(context.state.isBreak ? .green : Color(red: 0.91, green: 0.30, blue: 0.24))
                    .padding(.leading, 2)
            }
        }
    }
}
