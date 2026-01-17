import Foundation
import SwiftData
import os.log

private let logger = Logger(subsystem: "com.sijan.pomodoro.Pomodoro", category: "SessionRepository")

// MARK: - Session Repository Implementation

@MainActor
final class SessionRepository: SessionRepositoryProtocol {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    init() {
        do {
            let schema = Schema([PomodoroSession.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: config)
            modelContext = modelContainer.mainContext
            logger.info("SessionRepository initialized successfully")
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    func saveSession(_ session: PomodoroSession) {
        modelContext.insert(session)
        do {
            try modelContext.save()
            logger.info("Session saved: \(session.type.rawValue), duration: \(session.duration)s")
        } catch {
            logger.error("Failed to save session: \(error.localizedDescription)")
        }
    }

    func fetchSessions(from startDate: Date, to endDate: Date) -> [PomodoroSession] {
        let predicate = #Predicate<PomodoroSession> { session in
            session.startTime >= startDate && session.startTime <= endDate
        }
        let descriptor = FetchDescriptor<PomodoroSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            logger.error("Failed to fetch sessions: \(error.localizedDescription)")
            return []
        }
    }

    func fetchAllSessions() -> [PomodoroSession] {
        let descriptor = FetchDescriptor<PomodoroSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            logger.error("Failed to fetch all sessions: \(error.localizedDescription)")
            return []
        }
    }

    func getTotalFocusTime(for date: Date) -> TimeInterval {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let sessions = fetchSessions(from: startOfDay, to: endOfDay)
        return sessions
            .filter { $0.type == .work && $0.completed }
            .reduce(0) { $0 + $1.duration }
    }

    func getSessionCount(for date: Date) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let sessions = fetchSessions(from: startOfDay, to: endOfDay)
        return sessions.filter { $0.type == .work && $0.completed }.count
    }

    func getStatistics(for dateRange: DateInterval) -> SessionStatistics {
        let sessions = fetchSessions(from: dateRange.start, to: dateRange.end)
        let completedSessions = sessions.filter { $0.completed }
        let workSessions = completedSessions.filter { $0.type == .work }
        let breakSessions = completedSessions.filter { $0.type == .breakTime }

        let totalFocusTime = workSessions.reduce(0) { $0 + $1.duration }
        let totalBreakTime = breakSessions.reduce(0) { $0 + $1.duration }
        let avgDuration = workSessions.isEmpty ? 0 : totalFocusTime / Double(workSessions.count)

        return SessionStatistics(
            totalSessions: sessions.count,
            completedSessions: completedSessions.count,
            totalFocusTime: totalFocusTime,
            totalBreakTime: totalBreakTime,
            averageSessionDuration: avgDuration
        )
    }
}
