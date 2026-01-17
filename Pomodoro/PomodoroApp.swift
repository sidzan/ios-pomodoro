//
//  PomodoroApp.swift
//  Pomodoro
//
//  Created by sijan shrestha on 16/1/26.
//

import SwiftUI
import SwiftData

@main
struct PomodoroApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([PomodoroSession.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
