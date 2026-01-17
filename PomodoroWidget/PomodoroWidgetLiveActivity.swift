//
//  PomodoroWidgetLiveActivity.swift
//  PomodoroWidget
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Theme Colors
// These colors must match PomodoroTheme in the main app
private enum WidgetColors {
    static let workAccent = Color(red: 0.91, green: 0.30, blue: 0.24)
    static let breakAccent = Color.green
    static let trackBackground = Color.white.opacity(0.2)
}

// MARK: - Live Activity Attributes
// ⚠️ IMPORTANT: This struct is duplicated in Pomodoro/PomodoroActivityAttributes.swift
// Both definitions MUST stay identical. Widget extensions cannot share code with the main app
// without a shared framework. Any changes here must be mirrored in the main app.

struct PomodoroWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var isBreak: Bool
        var endTime: Date
    }

    var startTime: Date
}

// MARK: - Live Activity Widget

struct PomodoroWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroWidgetAttributes.self) { context in
            // Lock screen UI
            lockScreenView(context: context)
        } dynamicIsland: { context in
            dynamicIslandView(context: context)
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<PomodoroWidgetAttributes>) -> some View {
        let accentColor = context.state.isBreak ? WidgetColors.breakAccent : WidgetColors.workAccent

        VStack(spacing: 12) {
            // Top row: Label only
            HStack {
                Text(context.state.isBreak ? "Break" : "Focus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accentColor)

                Spacer()
            }

            // Timer - bigger and bolder
            Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true)
                .font(.system(size: 44, weight: .semibold))
                .monospacedDigit()
                .foregroundColor(.white)

            // Progress bar
            ProgressBarView(
                startTime: context.attributes.startTime,
                endTime: context.state.endTime,
                accentColor: accentColor,
                height: 6
            )
        }
        .padding()
        .activityBackgroundTint(accentColor.opacity(0.3))
    }

    // MARK: - Dynamic Island View

    private func dynamicIslandView(context: ActivityViewContext<PomodoroWidgetAttributes>) -> DynamicIsland {
        let accentColor = context.state.isBreak ? WidgetColors.breakAccent : WidgetColors.workAccent

        return DynamicIsland {
            DynamicIslandExpandedRegion(.leading) {
                HStack(spacing: 6) {
                    Text("P")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(accentColor)

                    Text(context.state.isBreak ? "Break" : "Focus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(accentColor)
                }
                .padding(.leading, 4)
            }
            DynamicIslandExpandedRegion(.trailing) {
                Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true)
                    .font(.system(size: 28, weight: .semibold))
                    .monospacedDigit()
            }
            DynamicIslandExpandedRegion(.bottom) {
                ProgressBarView(
                    startTime: context.attributes.startTime,
                    endTime: context.state.endTime,
                    accentColor: accentColor,
                    height: 4
                )
                .padding(.top, 8)
            }
        } compactLeading: {
            Text("P")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(accentColor)
                .padding(.leading, 4)
        } compactTrailing: {
            Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true)
                .font(.system(size: 14, weight: .semibold))
                .monospacedDigit()
                .frame(width: 50)
        } minimal: {
            Text("P")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(accentColor)
                .padding(.leading, 2)
        }
    }
}

// MARK: - Progress Bar View

private struct ProgressBarView: View {
    let startTime: Date
    let endTime: Date
    let accentColor: Color
    let height: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let totalDuration = endTime.timeIntervalSince(startTime)
            let elapsed = Date.now.timeIntervalSince(startTime)
            let progress = min(max(elapsed / totalDuration, 0), 1)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(WidgetColors.trackBackground)
                    .frame(height: height)

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(accentColor)
                    .frame(width: geometry.size.width * progress, height: height)
            }
        }
        .frame(height: height)
    }
}
