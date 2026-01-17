import Foundation
import SwiftData

// MARK: - Session Type

enum SessionType: String, Codable {
    case work
    case breakTime
}

// MARK: - Pomodoro Session Model

@Model
final class PomodoroSession {
    var id: UUID
    var startTime: Date
    var endTime: Date
    var type: SessionType
    var completed: Bool
    var duration: TimeInterval

    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        type: SessionType,
        completed: Bool = true
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.type = type
        self.completed = completed
        self.duration = endTime.timeIntervalSince(startTime)
    }
}

// MARK: - Session Statistics

struct SessionStatistics {
    let totalSessions: Int
    let completedSessions: Int
    let totalFocusTime: TimeInterval
    let totalBreakTime: TimeInterval
    let averageSessionDuration: TimeInterval

    var formattedFocusTime: String {
        let hours = Int(totalFocusTime) / 3600
        let minutes = (Int(totalFocusTime) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
