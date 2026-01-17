//
//  ContentView.swift
//  Pomodoro
//
//  Created by sijan shrestha on 16/1/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TimerViewModel()
    @Environment(\.colorScheme) private var colorScheme

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<21:
            return "Good evening"
        default:
            return "Good night"
        }
    }

    private var subtitle: String {
        switch viewModel.state {
        case .idle:
            return "Ready to focus?"
        case .working:
            return "Stay focused! You got this."
        case .onBreak:
            return "Enjoy your break."
        case .workComplete:
            return "Great work! Take a break?"
        }
    }

    var body: some View {
        ZStack {
            PomodoroTheme.background(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Greeting header
                VStack(spacing: 4) {
                    Text("\(greeting), Sijan")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(PomodoroTheme.text(for: colorScheme))

                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(PomodoroTheme.text(for: colorScheme).opacity(0.5))
                }
                .multilineTextAlignment(.center)
                .padding(.top, 60)

                Spacer()
                timerDisplay
                Spacer()
                actionButtons
            }
            .padding(.bottom, 60)
        }
    }

    private var timerDisplay: some View {
        ZStack {
            TimerRingView(
                progress: viewModel.progress,
                isBreak: viewModel.state.isOnBreak
            )

            VStack(spacing: 8) {
                Text(viewModel.formattedTime)
                    .font(.system(size: PomodoroTheme.timerFontSize, weight: .ultraLight, design: .default))
                    .monospacedDigit()
                    .foregroundColor(PomodoroTheme.text(for: colorScheme))

                Text(viewModel.state.statusText.uppercased())
                    .font(.system(size: 14, weight: .medium))
                    .tracking(2)
                    .foregroundColor(PomodoroTheme.text(for: colorScheme).opacity(0.6))
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch viewModel.state {
        case .idle:
            ActionButton(
                title: "Start",
                color: PomodoroTheme.workRing,
                action: viewModel.startWork
            )
        case .working, .onBreak:
            ActionButton(
                title: "Stop",
                color: PomodoroTheme.ringTrack(for: colorScheme),
                action: viewModel.reset
            )
        case .workComplete:
            HStack(spacing: 16) {
                ActionButton(
                    title: "Break",
                    color: PomodoroTheme.breakRing,
                    action: viewModel.startBreak
                )
                ActionButton(
                    title: "Again",
                    color: PomodoroTheme.workRing,
                    action: viewModel.startNewSession
                )
            }
        }
    }
}

private struct ActionButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(buttonTextColor)
                .frame(width: 160, height: 54)
                .background(color)
                .cornerRadius(27)
        }
    }

    private var buttonTextColor: Color {
        if color == PomodoroTheme.ringTrackLight || color == PomodoroTheme.ringTrackDark {
            return PomodoroTheme.text(for: colorScheme)
        }
        return .white
    }
}

#Preview {
    ContentView()
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}
