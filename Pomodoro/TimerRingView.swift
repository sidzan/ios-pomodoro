import SwiftUI

struct TimerRingView: View {
    let progress: Double
    let isBreak: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    PomodoroTheme.ringTrack(for: colorScheme),
                    lineWidth: PomodoroTheme.ringStrokeWidth
                )

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    PomodoroTheme.ringColor(isBreak: isBreak),
                    style: StrokeStyle(
                        lineWidth: PomodoroTheme.ringStrokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: PomodoroTheme.ringSize, height: PomodoroTheme.ringSize)
    }
}

#Preview("Work Progress") {
    TimerRingView(progress: 0.65, isBreak: false)
        .padding()
}

#Preview("Break Progress") {
    TimerRingView(progress: 0.4, isBreak: true)
        .padding()
}

#Preview("Dark Mode") {
    TimerRingView(progress: 0.5, isBreak: false)
        .padding()
        .preferredColorScheme(.dark)
}
