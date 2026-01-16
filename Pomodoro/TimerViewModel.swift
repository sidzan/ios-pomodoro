import Foundation
import Combine
import UIKit

@MainActor
final class TimerViewModel: ObservableObject {
    static let workDuration: TimeInterval = 25 * 60
    static let breakDuration: TimeInterval = 5 * 60

    @Published private(set) var state: TimerState = .idle
    @Published private(set) var remainingSeconds: TimeInterval = workDuration

    private var timerCancellable: AnyCancellable?

    var progress: Double {
        let totalDuration: TimeInterval
        switch state {
        case .working:
            totalDuration = Self.workDuration
        case .onBreak:
            totalDuration = Self.breakDuration
        case .idle, .workComplete:
            return 0
        }
        guard totalDuration > 0 else { return 0 }
        return max(0, min(1, 1 - (remainingSeconds / totalDuration)))
    }

    var formattedTime: String {
        let minutes = Int(remainingSeconds) / 60
        let seconds = Int(remainingSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    init() {}

    func startWork() {
        let endTime = Date().addingTimeInterval(Self.workDuration)
        state = .working(endTime: endTime)
        remainingSeconds = Self.workDuration
        startTimer(endTime: endTime)
    }

    func startBreak() {
        let endTime = Date().addingTimeInterval(Self.breakDuration)
        state = .onBreak(endTime: endTime)
        remainingSeconds = Self.breakDuration
        startTimer(endTime: endTime)
    }

    func startNewSession() {
        startWork()
    }

    func reset() {
        stopTimer()
        state = .idle
        remainingSeconds = Self.workDuration
    }

    private func startTimer(endTime: Date) {
        stopTimer()
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateTimer(endTime: endTime)
                }
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func updateTimer(endTime: Date) {
        let remaining = endTime.timeIntervalSinceNow
        if remaining <= 0 {
            remainingSeconds = 0
            stopTimer()
            handleTimerCompletion()
        } else {
            remainingSeconds = remaining
        }
    }

    private func handleTimerCompletion() {
        triggerHapticFeedback()
        switch state {
        case .working:
            workDidComplete()
        case .onBreak:
            breakDidComplete()
        default:
            break
        }
    }

    private func workDidComplete() {
        state = .workComplete
    }

    private func breakDidComplete() {
        state = .idle
        remainingSeconds = Self.workDuration
    }

    private func triggerHapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
