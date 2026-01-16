import Foundation

enum TimerState: Equatable {
    case idle
    case working(endTime: Date)
    case workComplete
    case onBreak(endTime: Date)

    var isRunning: Bool {
        switch self {
        case .working, .onBreak:
            return true
        case .idle, .workComplete:
            return false
        }
    }

    var isWorking: Bool {
        if case .working = self {
            return true
        }
        return false
    }

    var isOnBreak: Bool {
        if case .onBreak = self {
            return true
        }
        return false
    }

    var statusText: String {
        switch self {
        case .idle:
            return "Ready to Focus"
        case .working:
            return "Focus Time"
        case .workComplete:
            return "Work Complete!"
        case .onBreak:
            return "Break Time"
        }
    }
}
