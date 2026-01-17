import Foundation
import Combine
import UIKit

// MARK: - Timer Configuration

struct TimerConfiguration {
    var workDuration: TimeInterval
    var breakDuration: TimeInterval

    static let `default` = TimerConfiguration(
        workDuration: 25 * 60,
        breakDuration: 5 * 60
    )
}

// MARK: - Timer View Model

@MainActor
final class TimerViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var state: TimerState = .idle
    @Published private(set) var remainingSeconds: TimeInterval

    // MARK: - Configuration

    let configuration: TimerConfiguration

    // MARK: - Private Properties

    private var timerCancellable: AnyCancellable?
    private var sessionStartTime: Date?
    private var sessionRepository: SessionRepositoryProtocol?

    // MARK: - Computed Properties

    var progress: Double {
        let totalDuration: TimeInterval
        switch state {
        case .working:
            totalDuration = configuration.workDuration
        case .onBreak:
            totalDuration = configuration.breakDuration
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

    // MARK: - Initialization

    init(configuration: TimerConfiguration = .default, sessionRepository: SessionRepositoryProtocol? = nil) {
        self.configuration = configuration
        self.remainingSeconds = configuration.workDuration
        self.sessionRepository = sessionRepository
        NotificationService.requestPermission()
    }

    // MARK: - Public Methods

    func startWork() {
        sessionStartTime = Date()
        let endTime = Date().addingTimeInterval(configuration.workDuration)
        state = .working(endTime: endTime)
        remainingSeconds = configuration.workDuration
        startTimer(endTime: endTime)

        ShortcutService.triggerStartShortcut()
        NotificationService.scheduleWorkComplete(at: endTime)
        startLiveActivity(endTime: endTime, isBreak: false)
    }

    func startBreak() {
        sessionStartTime = Date()
        let endTime = Date().addingTimeInterval(configuration.breakDuration)
        state = .onBreak(endTime: endTime)
        remainingSeconds = configuration.breakDuration
        startTimer(endTime: endTime)

        NotificationService.scheduleBreakComplete(at: endTime)
        startLiveActivity(endTime: endTime, isBreak: true)
    }

    func startNewSession() {
        startWork()
    }

    func reset() {
        stopTimer()
        state = .idle
        remainingSeconds = configuration.workDuration
        sessionStartTime = nil

        NotificationService.cancelAll()
        stopLiveActivity()
    }

    // MARK: - Private Timer Methods

    private func startTimer(endTime: Date) {
        stopTimer()
        // Use 1Hz (1 second) updates - sufficient for timer display, saves battery
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
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

    // MARK: - Completion Handling

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
        saveSession(type: .work)
        state = .workComplete
        ShortcutService.triggerEndShortcut()
        stopLiveActivity()
    }

    private func breakDidComplete() {
        saveSession(type: .breakTime)
        state = .idle
        remainingSeconds = configuration.workDuration
        stopLiveActivity()
    }

    // MARK: - Session Tracking

    private func saveSession(type: SessionType) {
        guard let startTime = sessionStartTime else { return }
        let session = PomodoroSession(
            startTime: startTime,
            endTime: Date(),
            type: type,
            completed: true
        )
        sessionRepository?.saveSession(session)
        sessionStartTime = nil
    }

    // MARK: - Live Activity (iOS 16.1+)

    private func startLiveActivity(endTime: Date, isBreak: Bool) {
        if #available(iOS 16.1, *) {
            if isBreak {
                LiveActivityService.startBreakSession(endTime: endTime)
            } else {
                LiveActivityService.startWorkSession(endTime: endTime)
            }
        }
    }

    private func stopLiveActivity() {
        if #available(iOS 16.1, *) {
            LiveActivityService.stop()
        }
    }

    // MARK: - Haptic Feedback

    private func triggerHapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
