# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build via Xcode command line
xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Open in Xcode (preferred for development)
open Pomodoro.xcodeproj
```

Build and run directly in Xcode with Cmd+R. Use Cmd+B for build-only.

## Architecture

**MVVM single-screen app** with two build targets:
- `Pomodoro` - Main iOS app
- `PomodoroWidgetExtension` - Widget extension for Live Activities

### Core Components

**TimerViewModel.swift** - Central state machine with 4 states:
- `idle` → `working` → `workComplete` → `onBreak` → `idle`
- Uses Combine `Timer.publish(every: 0.1)` for smooth ring animation
- Coordinates all services (Shortcuts, Notifications, Live Activities)

**Services (stateless enums):**
- `ShortcutService` - Triggers iOS Shortcuts via x-callback-url, returns to app via `pomodoro://` scheme
- `NotificationService` - Schedules local notifications at timer end
- `LiveActivityService` - Manages ActivityKit Live Activities for lock screen/Dynamic Island

**Shared between targets:**
- `PomodoroActivityAttributes.swift` must have Target Membership for both Pomodoro and PomodoroWidgetExtension

### Key Implementation Details

- Timer stores `endTime: Date`, calculates remaining on each tick (battery efficient)
- Live Activities use `Text(timerInterval:countsDown:)` - system renders countdown without app running
- Shortcuts integration: hardcoded names "Pomodoro Start" / "Pomodoro End", fails silently if not created
- URL scheme `pomodoro://` registered in Info.plist for callback after shortcut runs

### Color System

`Theme.swift` defines warm tomato palette with light/dark mode support. All colors centralized in `PomodoroTheme` enum.

## Shortcuts Setup

For Focus Mode integration, user creates these in iOS Shortcuts app:
- "Pomodoro Start" - Enable Work focus, start music, etc.
- "Pomodoro End" - Disable Work focus
