import Foundation

// MARK: - Service Protocols
// These protocols enable dependency injection for testability and extensibility

protocol NotificationServiceProtocol {
    static func requestPermission()
    static func scheduleWorkComplete(at date: Date)
    static func scheduleBreakComplete(at date: Date)
    static func cancelAll()
}

protocol ShortcutServiceProtocol {
    static func triggerStartShortcut()
    static func triggerEndShortcut()
}

@available(iOS 16.1, *)
protocol LiveActivityServiceProtocol {
    static func startWorkSession(endTime: Date)
    static func startBreakSession(endTime: Date)
    static func stop()
    static func update(isBreak: Bool, endTime: Date)
}

// MARK: - Session Tracking Protocol (for future analytics)

protocol SessionRepositoryProtocol {
    func saveSession(_ session: PomodoroSession)
    func fetchSessions(from startDate: Date, to endDate: Date) -> [PomodoroSession]
    func fetchAllSessions() -> [PomodoroSession]
    func getTotalFocusTime(for date: Date) -> TimeInterval
    func getSessionCount(for date: Date) -> Int
}

// MARK: - Service Container

protocol ServiceContainerProtocol {
    var notificationService: NotificationServiceProtocol { get }
    var shortcutService: ShortcutServiceProtocol { get }
}
