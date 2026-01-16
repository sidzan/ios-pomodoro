import UIKit

enum ShortcutService {
    static func triggerStartShortcut() {
        guard let url = URL(string: "shortcuts://run-shortcut?name=Pomodoro%20Start") else {
            return
        }
        UIApplication.shared.open(url) { _ in }
    }

    static func triggerEndShortcut() {
        guard let url = URL(string: "shortcuts://run-shortcut?name=Pomodoro%20End") else {
            return
        }
        UIApplication.shared.open(url) { _ in }
    }
}
