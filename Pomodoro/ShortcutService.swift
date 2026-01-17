import UIKit
import os.log

private let logger = Logger(subsystem: "com.sijan.pomodoro.Pomodoro", category: "Shortcuts")

// MARK: - Shortcut Service

enum ShortcutService: ShortcutServiceProtocol {
    private static let callbackURL = "pomodoro://"

    static func triggerStartShortcut() {
        triggerShortcut(named: "Pomodoro Start")
    }

    static func triggerEndShortcut() {
        triggerShortcut(named: "Pomodoro End")
    }

    private static func triggerShortcut(named name: String) {
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedCallback = callbackURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "shortcuts://x-callback-url/run-shortcut?name=\(encodedName)&x-success=\(encodedCallback)") else {
            logger.error("Failed to create shortcut URL for: \(name)")
            return
        }

        logger.info("Triggering shortcut: \(name)")
        UIApplication.shared.open(url) { success in
            if success {
                logger.info("Shortcut triggered successfully: \(name)")
            } else {
                logger.warning("Shortcut may not exist or failed to open: \(name)")
            }
        }
    }
}
