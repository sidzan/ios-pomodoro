# Pomodoro App Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a minimal iOS Pomodoro timer with Live Activities and Shortcuts integration.

**Architecture:** Single-screen SwiftUI app with MVVM pattern. TimerViewModel manages state machine, ContentView renders UI, services handle notifications and shortcuts. Widget Extension provides Live Activities for lock screen/Dynamic Island.

**Tech Stack:** SwiftUI, Combine, ActivityKit, UserNotifications, URL schemes

**iOS Concepts for Web Developers:**
- SwiftUI = declarative UI (like React)
- `@Published` = observable state (like useState + context)
- `@StateObject` = owned state, `@ObservedObject` = passed state
- Combine = reactive streams (like RxJS)
- Widget Extension = separate build target for lock screen widgets

---

## Task 1: Add Widget Extension for Live Activities

**Why:** Live Activities require a Widget Extension target. This is an Xcode-specific step that must be done in the IDE.

**Manual Steps (in Xcode):**

1. Open `Pomodoro.xcodeproj` in Xcode
2. File → New → Target
3. Select "Widget Extension"
4. Name it: `PomodoroWidget`
5. **Uncheck** "Include Configuration App Intent" (we don't need it)
6. **Uncheck** "Include Live Activity" (we'll write our own)
7. Click Finish
8. When prompted "Activate scheme?", click Activate

**Verify:** You should see a new folder `PomodoroWidget/` in your project with `PomodoroWidgetBundle.swift` and `PomodoroWidget.swift`

**Step 2: Delete the auto-generated widget files**

We'll write our own. Delete these files (in Xcode, right-click → Delete → Move to Trash):
- `PomodoroWidget.swift`
- `AppIntent.swift` (if it exists)

Keep only `PomodoroWidgetBundle.swift`

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add PomodoroWidget extension target"
```

---

## Task 2: Create Theme/Colors System

**Files:**
- Create: `Pomodoro/Theme.swift`

**Step 1: Create the theme file**

```swift
// Pomodoro/Theme.swift

import SwiftUI

enum PomodoroTheme {
    // MARK: - Colors

    static let backgroundLight = Color(hex: "FFF8F0")
    static let backgroundDark = Color(hex: "1C1917")

    static let workRing = Color(hex: "E54D2E")
    static let breakRing = Color(hex: "46A758")

    static let ringTrackLight = Color(hex: "E7E5E4")
    static let ringTrackDark = Color(hex: "292524")

    static let textLight = Color(hex: "1C1917")
    static let textDark = Color(hex: "FAFAF9")

    // MARK: - Adaptive Colors

    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? backgroundDark : backgroundLight
    }

    static func ringTrack(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? ringTrackDark : ringTrackLight
    }

    static func text(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? textDark : textLight
    }

    static func mutedText(for colorScheme: ColorScheme) -> Color {
        text(for: colorScheme).opacity(0.6)
    }

    // MARK: - Dimensions

    static let ringStrokeWidth: CGFloat = 12
    static let timerFontSize: CGFloat = 72
    static let ringSize: CGFloat = 280
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

**Step 2: Verify it compiles**

Build the project in Xcode (Cmd+B) - should succeed with no errors.

**Step 3: Commit**

```bash
git add Pomodoro/Theme.swift && git commit -m "feat: add theme system with warm color palette"
```

---

## Task 3: Create Timer State Enum

**Files:**
- Create: `Pomodoro/TimerState.swift`

**Step 1: Create the state enum**

```swift
// Pomodoro/TimerState.swift

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
        if case .working = self { return true }
        return false
    }

    var isOnBreak: Bool {
        if case .onBreak = self { return true }
        return false
    }

    var statusText: String {
        switch self {
        case .idle:
            return "ready"
        case .working:
            return "working"
        case .workComplete:
            return "complete"
        case .onBreak:
            return "break"
        }
    }
}
```

**Step 2: Verify it compiles**

Build (Cmd+B) - should succeed.

**Step 3: Commit**

```bash
git add Pomodoro/TimerState.swift && git commit -m "feat: add TimerState enum with state machine cases"
```

---

## Task 4: Create TimerViewModel

**Files:**
- Create: `Pomodoro/TimerViewModel.swift`

**Step 1: Create the view model**

```swift
// Pomodoro/TimerViewModel.swift

import Foundation
import Combine
import UIKit

@MainActor
class TimerViewModel: ObservableObject {
    // MARK: - Constants

    static let workDuration: TimeInterval = 25 * 60  // 25 minutes
    static let breakDuration: TimeInterval = 5 * 60  // 5 minutes

    // MARK: - Published State

    @Published private(set) var state: TimerState = .idle
    @Published private(set) var remainingSeconds: TimeInterval = workDuration

    // MARK: - Private

    private var timerCancellable: AnyCancellable?

    // MARK: - Computed Properties

    var progress: Double {
        switch state {
        case .idle:
            return 1.0
        case .working(let endTime):
            let total = Self.workDuration
            let remaining = max(0, endTime.timeIntervalSinceNow)
            return remaining / total
        case .workComplete:
            return 0.0
        case .onBreak(let endTime):
            let total = Self.breakDuration
            let remaining = max(0, endTime.timeIntervalSinceNow)
            return remaining / total
        }
    }

    var formattedTime: String {
        let minutes = Int(remainingSeconds) / 60
        let seconds = Int(remainingSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Actions

    func startWork() {
        let endTime = Date().addingTimeInterval(Self.workDuration)
        state = .working(endTime: endTime)
        remainingSeconds = Self.workDuration
        startTimer(endTime: endTime, onComplete: workDidComplete)
    }

    func startBreak() {
        let endTime = Date().addingTimeInterval(Self.breakDuration)
        state = .onBreak(endTime: endTime)
        remainingSeconds = Self.breakDuration
        startTimer(endTime: endTime, onComplete: breakDidComplete)
    }

    func startNewSession() {
        startWork()
    }

    func reset() {
        stopTimer()
        state = .idle
        remainingSeconds = Self.workDuration
    }

    // MARK: - Private Methods

    private func startTimer(endTime: Date, onComplete: @escaping () -> Void) {
        stopTimer()

        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                let remaining = endTime.timeIntervalSinceNow

                if remaining <= 0 {
                    self.remainingSeconds = 0
                    self.stopTimer()
                    onComplete()
                } else {
                    self.remainingSeconds = remaining
                }
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func workDidComplete() {
        state = .workComplete
        triggerHaptic()
    }

    private func breakDidComplete() {
        state = .idle
        remainingSeconds = Self.workDuration
        triggerHaptic()
    }

    private func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
```

**Step 2: Verify it compiles**

Build (Cmd+B) - should succeed.

**Step 3: Commit**

```bash
git add Pomodoro/TimerViewModel.swift && git commit -m "feat: add TimerViewModel with state machine and timer logic"
```

---

## Task 5: Create TimerRingView

**Files:**
- Create: `Pomodoro/TimerRingView.swift`

**Step 1: Create the ring view**

```swift
// Pomodoro/TimerRingView.swift

import SwiftUI

struct TimerRingView: View {
    let progress: Double  // 1.0 = full, 0.0 = empty
    let isBreak: Bool

    @Environment(\.colorScheme) private var colorScheme

    private var ringColor: Color {
        isBreak ? PomodoroTheme.breakRing : PomodoroTheme.workRing
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    PomodoroTheme.ringTrack(for: colorScheme),
                    lineWidth: PomodoroTheme.ringStrokeWidth
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(
                        lineWidth: PomodoroTheme.ringStrokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))  // Start from top
                .animation(.linear(duration: 0.1), value: progress)
        }
        .frame(width: PomodoroTheme.ringSize, height: PomodoroTheme.ringSize)
    }
}

#Preview("Work - Full") {
    TimerRingView(progress: 1.0, isBreak: false)
        .padding()
}

#Preview("Work - Half") {
    TimerRingView(progress: 0.5, isBreak: false)
        .padding()
}

#Preview("Break - Half") {
    TimerRingView(progress: 0.5, isBreak: true)
        .padding()
}
```

**Step 2: Verify it compiles and preview works**

Build (Cmd+B), then open the Canvas preview (Editor → Canvas or Option+Cmd+Return).

**Step 3: Commit**

```bash
git add Pomodoro/TimerRingView.swift && git commit -m "feat: add TimerRingView with animated circular progress"
```

---

## Task 6: Create ShortcutService

**Files:**
- Create: `Pomodoro/ShortcutService.swift`

**Step 1: Create the service**

```swift
// Pomodoro/ShortcutService.swift

import UIKit

enum ShortcutService {
    static let startShortcutName = "Pomodoro Start"
    static let endShortcutName = "Pomodoro End"

    static func triggerStartShortcut() {
        triggerShortcut(named: startShortcutName)
    }

    static func triggerEndShortcut() {
        triggerShortcut(named: endShortcutName)
    }

    private static func triggerShortcut(named name: String) {
        guard let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "shortcuts://run-shortcut?name=\(encoded)") else {
            return
        }

        // Opens Shortcuts app briefly, then runs the shortcut
        // Fails silently if shortcut doesn't exist
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
```

**Step 2: Verify it compiles**

Build (Cmd+B) - should succeed.

**Step 3: Commit**

```bash
git add Pomodoro/ShortcutService.swift && git commit -m "feat: add ShortcutService for triggering user shortcuts"
```

---

## Task 7: Create NotificationService

**Files:**
- Create: `Pomodoro/NotificationService.swift`

**Step 1: Create the service**

```swift
// Pomodoro/NotificationService.swift

import UserNotifications

enum NotificationService {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func scheduleWorkComplete(at date: Date) {
        scheduleNotification(
            id: "work-complete",
            title: "Pomodoro Complete!",
            body: "Great work! Time for a break.",
            at: date
        )
    }

    static func scheduleBreakComplete(at date: Date) {
        scheduleNotification(
            id: "break-complete",
            title: "Break Over",
            body: "Ready for another session?",
            at: date
        )
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private static func scheduleNotification(id: String, title: String, body: String, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, date.timeIntervalSinceNow),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
```

**Step 2: Verify it compiles**

Build (Cmd+B) - should succeed.

**Step 3: Commit**

```bash
git add Pomodoro/NotificationService.swift && git commit -m "feat: add NotificationService for local notifications"
```

---

## Task 8: Create Activity Attributes for Live Activities

**Files:**
- Create: `Pomodoro/PomodoroActivityAttributes.swift`

**Note:** This file needs to be shared between the main app and the widget extension. We'll add it to both targets.

**Step 1: Create the attributes file**

```swift
// Pomodoro/PomodoroActivityAttributes.swift

import ActivityKit
import Foundation

struct PomodoroActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var isBreak: Bool
        var endTime: Date
    }

    // Static properties (don't change during activity)
    var startTime: Date
}
```

**Step 2: Add file to widget target**

In Xcode:
1. Select `PomodoroActivityAttributes.swift` in the file navigator
2. Open File Inspector (right panel, first tab)
3. Under "Target Membership", check both `Pomodoro` and `PomodoroWidget`

**Step 3: Verify it compiles**

Build (Cmd+B) - should succeed.

**Step 4: Commit**

```bash
git add Pomodoro/PomodoroActivityAttributes.swift && git commit -m "feat: add PomodoroActivityAttributes for Live Activities"
```

---

## Task 9: Create LiveActivityService

**Files:**
- Create: `Pomodoro/LiveActivityService.swift`

**Step 1: Create the service**

```swift
// Pomodoro/LiveActivityService.swift

import ActivityKit
import Foundation

@MainActor
enum LiveActivityService {
    private static var currentActivity: Activity<PomodoroActivityAttributes>?

    static func startWorkSession(endTime: Date) {
        start(endTime: endTime, isBreak: false)
    }

    static func startBreakSession(endTime: Date) {
        start(endTime: endTime, isBreak: true)
    }

    static func stop() {
        Task {
            await currentActivity?.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }

    private static func start(endTime: Date, isBreak: Bool) {
        // End any existing activity
        stop()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let attributes = PomodoroActivityAttributes(startTime: Date())
        let state = PomodoroActivityAttributes.ContentState(
            isBreak: isBreak,
            endTime: endTime
        )
        let content = ActivityContent(state: state, staleDate: endTime)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            // Silently fail - Live Activities are nice-to-have
        }
    }

    static func update(isBreak: Bool, endTime: Date) {
        guard let activity = currentActivity else { return }

        let state = PomodoroActivityAttributes.ContentState(
            isBreak: isBreak,
            endTime: endTime
        )
        let content = ActivityContent(state: state, staleDate: endTime)

        Task {
            await activity.update(content)
        }
    }
}
```

**Step 2: Verify it compiles**

Build (Cmd+B) - should succeed.

**Step 3: Commit**

```bash
git add Pomodoro/LiveActivityService.swift && git commit -m "feat: add LiveActivityService for managing Live Activities"
```

---

## Task 10: Wire Services into TimerViewModel

**Files:**
- Modify: `Pomodoro/TimerViewModel.swift`

**Step 1: Update the view model to use services**

Replace the entire `TimerViewModel.swift` with:

```swift
// Pomodoro/TimerViewModel.swift

import Foundation
import Combine
import UIKit

@MainActor
class TimerViewModel: ObservableObject {
    // MARK: - Constants

    static let workDuration: TimeInterval = 25 * 60  // 25 minutes
    static let breakDuration: TimeInterval = 5 * 60  // 5 minutes

    // MARK: - Published State

    @Published private(set) var state: TimerState = .idle
    @Published private(set) var remainingSeconds: TimeInterval = workDuration

    // MARK: - Private

    private var timerCancellable: AnyCancellable?

    // MARK: - Computed Properties

    var progress: Double {
        switch state {
        case .idle:
            return 1.0
        case .working(let endTime):
            let total = Self.workDuration
            let remaining = max(0, endTime.timeIntervalSinceNow)
            return remaining / total
        case .workComplete:
            return 0.0
        case .onBreak(let endTime):
            let total = Self.breakDuration
            let remaining = max(0, endTime.timeIntervalSinceNow)
            return remaining / total
        }
    }

    var formattedTime: String {
        let minutes = Int(remainingSeconds) / 60
        let seconds = Int(remainingSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Init

    init() {
        NotificationService.requestPermission()
    }

    // MARK: - Actions

    func startWork() {
        let endTime = Date().addingTimeInterval(Self.workDuration)
        state = .working(endTime: endTime)
        remainingSeconds = Self.workDuration

        // Trigger services
        ShortcutService.triggerStartShortcut()
        NotificationService.scheduleWorkComplete(at: endTime)
        LiveActivityService.startWorkSession(endTime: endTime)

        startTimer(endTime: endTime, onComplete: workDidComplete)
    }

    func startBreak() {
        let endTime = Date().addingTimeInterval(Self.breakDuration)
        state = .onBreak(endTime: endTime)
        remainingSeconds = Self.breakDuration

        // Trigger services (no shortcut for break)
        NotificationService.scheduleBreakComplete(at: endTime)
        LiveActivityService.startBreakSession(endTime: endTime)

        startTimer(endTime: endTime, onComplete: breakDidComplete)
    }

    func startNewSession() {
        startWork()
    }

    func reset() {
        stopTimer()
        NotificationService.cancelAll()
        LiveActivityService.stop()
        state = .idle
        remainingSeconds = Self.workDuration
    }

    // MARK: - Private Methods

    private func startTimer(endTime: Date, onComplete: @escaping () -> Void) {
        stopTimer()

        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                let remaining = endTime.timeIntervalSinceNow

                if remaining <= 0 {
                    self.remainingSeconds = 0
                    self.stopTimer()
                    onComplete()
                } else {
                    self.remainingSeconds = remaining
                }
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func workDidComplete() {
        state = .workComplete
        ShortcutService.triggerEndShortcut()
        LiveActivityService.stop()
        triggerHaptic()
    }

    private func breakDidComplete() {
        state = .idle
        remainingSeconds = Self.workDuration
        LiveActivityService.stop()
        triggerHaptic()
    }

    private func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
```

**Step 2: Verify it compiles**

Build (Cmd+B) - should succeed.

**Step 3: Commit**

```bash
git add Pomodoro/TimerViewModel.swift && git commit -m "feat: integrate services into TimerViewModel"
```

---

## Task 11: Create Main ContentView

**Files:**
- Modify: `Pomodoro/ContentView.swift`

**Step 1: Replace ContentView with the full implementation**

```swift
// Pomodoro/ContentView.swift

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TimerViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background
            PomodoroTheme.background(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Timer display
                timerDisplay

                Spacer()

                // Action buttons
                actionButtons
                    .padding(.bottom, 60)
            }
        }
    }

    // MARK: - Timer Display

    private var timerDisplay: View {
        ZStack {
            TimerRingView(
                progress: viewModel.progress,
                isBreak: viewModel.state.isOnBreak
            )

            VStack(spacing: 8) {
                Text(viewModel.formattedTime)
                    .font(.system(size: PomodoroTheme.timerFontSize, weight: .ultraLight, design: .default))
                    .monospacedDigit()
                    .foregroundColor(PomodoroTheme.text(for: colorScheme))

                Text(viewModel.state.statusText.uppercased())
                    .font(.system(size: 14, weight: .medium))
                    .tracking(2)
                    .foregroundColor(PomodoroTheme.mutedText(for: colorScheme))
            }
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        switch viewModel.state {
        case .idle:
            startButton

        case .working, .onBreak:
            stopButton

        case .workComplete:
            HStack(spacing: 20) {
                breakButton
                newSessionButton
            }
        }
    }

    private var startButton: some View {
        Button(action: viewModel.startWork) {
            Text("Start")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 160, height: 54)
                .background(PomodoroTheme.workRing)
                .cornerRadius(27)
        }
    }

    private var stopButton: some View {
        Button(action: viewModel.reset) {
            Text("Stop")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(PomodoroTheme.text(for: colorScheme))
                .frame(width: 160, height: 54)
                .background(PomodoroTheme.ringTrack(for: colorScheme))
                .cornerRadius(27)
        }
    }

    private var breakButton: some View {
        Button(action: viewModel.startBreak) {
            Text("Break")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 120, height: 54)
                .background(PomodoroTheme.breakRing)
                .cornerRadius(27)
        }
    }

    private var newSessionButton: some View {
        Button(action: viewModel.startNewSession) {
            Text("Again")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 120, height: 54)
                .background(PomodoroTheme.workRing)
                .cornerRadius(27)
        }
    }
}

#Preview {
    ContentView()
}
```

**Step 2: Fix the return type issue**

There's an issue with the `timerDisplay` computed property. Replace:

```swift
    private var timerDisplay: View {
```

With:

```swift
    private var timerDisplay: some View {
```

**Step 3: Verify it compiles and preview works**

Build (Cmd+B) and check the Canvas preview.

**Step 4: Commit**

```bash
git add Pomodoro/ContentView.swift && git commit -m "feat: implement main ContentView with timer UI"
```

---

## Task 12: Enable Live Activities in Info.plist

**Files:**
- Modify: `Pomodoro/Info.plist` (or via Xcode target settings)

**Step 1: Add Live Activities capability**

In Xcode:
1. Select the `Pomodoro` project in navigator
2. Select the `Pomodoro` target
3. Go to "Info" tab
4. Click "+" to add a new key
5. Add: `NSSupportsLiveActivities` = `YES` (Boolean)

**Alternative (if Info.plist exists as file):**

Add this inside the `<dict>` section:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

**Step 2: Verify it compiles**

Build (Cmd+B) - should succeed.

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: enable Live Activities in Info.plist"
```

---

## Task 13: Implement Live Activity Widget UI

**Files:**
- Modify: `PomodoroWidget/PomodoroWidgetBundle.swift`
- Create: `PomodoroWidget/PomodoroLiveActivity.swift`

**Step 1: Update the widget bundle**

```swift
// PomodoroWidget/PomodoroWidgetBundle.swift

import WidgetKit
import SwiftUI

@main
struct PomodoroWidgetBundle: WidgetBundle {
    var body: some Widget {
        PomodoroLiveActivity()
    }
}
```

**Step 2: Create the Live Activity view**

```swift
// PomodoroWidget/PomodoroLiveActivity.swift

import ActivityKit
import WidgetKit
import SwiftUI

struct PomodoroLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroActivityAttributes.self) { context in
            // Lock Screen UI
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.center) {
                    expandedView(context: context)
                }
            } compactLeading: {
                // Compact leading
                Image(systemName: context.state.isBreak ? "leaf.fill" : "timer")
                    .foregroundColor(context.state.isBreak ? .green : .red)
            } compactTrailing: {
                // Compact trailing - countdown
                Text(timerInterval: context.state.endTime...context.state.endTime, countsDown: false)
                    .monospacedDigit()
                    .frame(width: 50)
            } minimal: {
                // Minimal view
                Image(systemName: context.state.isBreak ? "leaf.fill" : "timer")
                    .foregroundColor(context.state.isBreak ? .green : .red)
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<PomodoroActivityAttributes>) -> some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: context.state.isBreak ? "leaf.fill" : "timer")
                .font(.system(size: 24))
                .foregroundColor(context.state.isBreak ? .green : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.isBreak ? "Break" : "Focus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                // Countdown timer - system handles the animation
                Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                    .font(.system(size: 32, weight: .light, design: .rounded))
                    .monospacedDigit()
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(UIColor.secondarySystemBackground))
    }

    // MARK: - Expanded Dynamic Island View

    @ViewBuilder
    private func expandedView(context: ActivityViewContext<PomodoroActivityAttributes>) -> some View {
        VStack(spacing: 4) {
            Text(context.state.isBreak ? "Break Time" : "Focus Time")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                .font(.system(size: 36, weight: .light, design: .rounded))
                .monospacedDigit()
        }
    }
}
```

**Step 3: Verify it compiles**

Build (Cmd+B) - should succeed. You may need to select the main Pomodoro scheme.

**Step 4: Commit**

```bash
git add PomodoroWidget/ && git commit -m "feat: implement Live Activity UI for lock screen and Dynamic Island"
```

---

## Task 14: Test on Simulator/Device

**Manual Testing Steps:**

1. Run the app on simulator (Cmd+R)
2. Tap "Start" - verify:
   - Ring starts animating
   - Timer counts down
   - Status shows "WORKING"
3. Wait or set `workDuration = 10` temporarily for testing
4. When complete, verify:
   - "Break" and "Again" buttons appear
   - Haptic feedback (device only)
5. Tap "Break" - verify break timer works
6. Test on physical device to verify:
   - Live Activity appears on lock screen
   - Dynamic Island shows countdown (iPhone 14 Pro+)
   - Notifications arrive when timer completes

**Step 1: Create a debug configuration for faster testing**

Temporarily modify `TimerViewModel.swift` for testing:

```swift
#if DEBUG
    static let workDuration: TimeInterval = 10  // 10 seconds for testing
    static let breakDuration: TimeInterval = 5  // 5 seconds for testing
#else
    static let workDuration: TimeInterval = 25 * 60
    static let breakDuration: TimeInterval = 5 * 60
#endif
```

**Step 2: Run and test**

Run on simulator and device. Verify all flows work.

**Step 3: Revert debug timing (keep production values)**

Either remove the `#if DEBUG` block or keep it for development convenience.

**Step 4: Commit**

```bash
git add -A && git commit -m "feat: add debug timing configuration"
```

---

## Task 15: Final Polish and Commit

**Step 1: Clean up any warnings**

Build with Cmd+B and fix any warnings.

**Step 2: Final commit**

```bash
git add -A && git commit -m "chore: final polish and cleanup"
```

**Step 3: Tag the release**

```bash
git tag v1.0.0
```

---

## Summary

You now have a complete Pomodoro app with:
- Clean warm-toned UI with circular progress ring
- 25-minute work / 5-minute break timers
- Live Activities on lock screen and Dynamic Island
- Shortcuts integration ("Pomodoro Start" / "Pomodoro End")
- Local notifications when timer completes
- Haptic feedback

**To enable Focus Mode**, create a Shortcut named "Pomodoro Start" that enables your Work Focus Mode.
