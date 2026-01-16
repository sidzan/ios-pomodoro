# Pomodoro App Design

## Overview

A minimal, beautiful Pomodoro timer app for iOS with Focus Mode integration via Shortcuts and lock screen display via Live Activities.

## Core Requirements

- 25-minute work timer with circular progress ring
- 5-minute break timer after work session
- Trigger user-defined Shortcuts ("Pomodoro Start" / "Pomodoro End")
- Display timer on lock screen and Dynamic Island via Live Activities
- Local notifications when timer completes
- Warm tomato-inspired color palette
- No auth, no sync, no settings screen

## User Flow

```
1. User opens app → sees "25:00" with Start button
2. User taps Start →
   - Triggers "Pomodoro Start" shortcut (if exists)
   - Starts Live Activity (lock screen + Dynamic Island)
   - Timer counts down with animated ring
3. Timer hits 0:00 →
   - Triggers "Pomodoro End" shortcut (if exists)
   - Shows notification + haptic + sound
   - Shows two buttons: "Start Break" / "Start New Session"
4. User taps "Start Break" →
   - 5-minute countdown (no Focus Mode)
   - Live Activity updates to show break
5. Break ends →
   - Notification + haptic
   - Returns to idle state (ready for new session)
```

## State Machine

```
States:
- idle: Showing "25:00", Start button visible
- working: Counting down from 25:00, ring animating
- workComplete: Completion message, break/new session buttons
- onBreak: Counting down from 5:00

Transitions:
- idle → working: User taps Start
- working → workComplete: Timer reaches 0:00
- workComplete → onBreak: User taps "Start Break"
- workComplete → working: User taps "Start New Session"
- onBreak → idle: Break timer reaches 0:00
```

## Visual Design

### Layout

Single-screen app with centered timer display:
- Large circular progress ring (center)
- Timer text inside ring (ultra-light, ~72pt)
- Status label below timer ("working" / "break")
- Action button(s) at bottom

### Color Palette

**Light Mode:**
- Background: Soft warm cream (#FFF8F0)
- Timer ring (work): Tomato red (#E54D2E)
- Timer ring (break): Soft sage green (#46A758)
- Ring track: Muted warm gray (#E7E5E4)
- Text: Near-black (#1C1917)

**Dark Mode:**
- Background: Dark charcoal (#1C1917)
- Timer ring (work): Tomato red (#E54D2E)
- Timer ring (break): Soft sage green (#46A758)
- Ring track: Dark warm gray (#292524)
- Text: Off-white (#FAFAF9)

### Typography

- Timer numbers: SF Pro, ultra-light weight, ~72pt
- Status label: SF Pro, small caps, muted color
- Buttons: SF Pro, medium weight, standard size

### Ring Animation

- Thick stroke (~12pt)
- Depletes clockwise from 12 o'clock
- Smooth animation (not per-second jumps)

## Technical Architecture

### File Structure

```
Pomodoro/
├── PomodoroApp.swift              # App entry point
├── ContentView.swift              # Main screen
├── TimerViewModel.swift           # Timer logic & state machine
├── TimerRingView.swift            # Circular progress ring
├── ShortcutService.swift          # URL scheme for Shortcuts
├── NotificationService.swift      # Local notifications
└── PomodoroWidgetExtension/       # Widget extension
    ├── PomodoroWidgetBundle.swift
    ├── PomodoroLiveActivity.swift
    └── PomodoroActivityAttributes.swift
```

### Timer Implementation

**Battery efficiency:**
- Store `endTime` as Date, calculate remaining on display
- Use `Timer.publish(every: 0.1)` only when app is foreground
- Live Activity uses `Text(.timerInterval:)` - system handles countdown

**Background handling:**
- Schedule local notification immediately when timer starts
- Live Activity continues on lock screen even if app killed
- On foreground return, recalculate remaining time from stored endTime

### Shortcuts Integration

Hardcoded shortcut names with silent fallback:
- "Pomodoro Start" - triggered when work session begins
- "Pomodoro End" - triggered when work session ends

```swift
func triggerShortcut(named: String) {
    let encoded = named.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    if let url = URL(string: "shortcuts://run-shortcut?name=\(encoded)") {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
```

If shortcuts don't exist, the call fails silently - no error shown to user.

### Live Activities (iOS 16+)

**ActivityAttributes:**
```swift
struct PomodoroActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timerState: String  // "working" or "break"
        var endTime: Date
    }
    var sessionType: String  // "work" or "break"
}
```

**Lock Screen UI:**
- Shows timer countdown using `Text(.timerInterval:)`
- Tomato icon for work, leaf icon for break
- Minimal design matching app aesthetic

**Dynamic Island:**
- Compact: Just the countdown
- Expanded: Countdown + session type label

### Notifications

Request permission on first launch:
```swift
UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
```

Schedule notification when timer starts:
- Title: "Pomodoro Complete" / "Break Over"
- Sound: Default system sound
- Fires at exact endTime

### Haptics

Use `UINotificationFeedbackGenerator` for:
- Timer completion (success style)
- Break completion (success style)

## Decisions & Trade-offs

1. **No settings screen** - Timer durations fixed at 25/5 min. Keeps UI minimal. Can add settings in v2 if needed.

2. **No persistence** - Timer state in memory only. If app killed, timer resets. Live Activity handles lock screen visibility anyway.

3. **Shortcuts over Focus API** - Apple doesn't expose Focus Mode API. Shortcuts approach is more flexible (can trigger Spotify, etc).

4. **Silent shortcut failures** - If user hasn't created shortcuts, app works fine without them. No error dialogs.

5. **iOS 16+ only** - Live Activities require iOS 16. Given it's 2026, this is acceptable.

## Out of Scope (v1)

- Customizable timer durations
- Session history/logging
- Statistics/analytics
- Sound customization
- macOS support (easy to add later with SwiftUI)
- Apple Watch support
- Long break after X sessions

## User Setup

User needs to create two Shortcuts (optional):

**"Pomodoro Start":**
- Enable "Work" Focus Mode
- Start Spotify playlist (optional)
- Any other desired automations

**"Pomodoro End":**
- Disable "Work" Focus Mode
- Any cleanup automations
