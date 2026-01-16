import UIKit

enum ShortcutService {
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
            return
        }
        UIApplication.shared.open(url) { _ in }
    }
}
