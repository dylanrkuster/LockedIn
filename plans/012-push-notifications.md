# Plan: Ticket 012 - Push Notifications

## Overview

Add local push notifications for:
1. **5 min warning** (default ON): "5 min left. The block is coming."
2. **15 min warning** (default OFF): "15 min remaining."
3. **Workout synced** (default ON): "+{earned} min. Bank: {balance}/{max}."
4. **Workout synced (capped)**: "+{earned} of {workout} min. Bank full."

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    NOTIFICATION FLOW                            │
└─────────────────────────────────────────────────────────────────┘

BALANCE WARNINGS (from Extension):
  DeviceActivityMonitorExtension.eventDidReachThreshold()
  → Balance decremented
  → Check: did balance cross 15 or 5 threshold?
  → Check: SharedState.notify15MinWarning / notify5MinWarning enabled?
  → Check: SharedState.notified15MinToday / notified5MinToday not already set?
  → NotificationManager.postLowBalanceWarning()
  → Mark notifiedXMinToday = true

WORKOUT SYNC (from Main App):
  LockedInApp.processNewWorkouts()
  → BankState.earn() called
  → Check: SharedState.notifyWorkoutSync enabled?
  → NotificationManager.postWorkoutSynced() or postWorkoutSyncedCapped()

SETTINGS RESET:
  - notified5MinToday / notified15MinToday reset when:
    - Day changes (automatic via usedMinutesToday date check pattern)
    - Balance goes back above threshold (after workout)
```

## Files to Create

### 1. `Shared/NotificationManager.swift`

Centralized notification handler. Must be in Shared/ for extension access.

```swift
import UserNotifications

enum NotificationManager {
    // Notification identifiers
    enum Identifier {
        static let lowBalance5Min = "lockedin.lowbalance.5min"
        static let lowBalance15Min = "lockedin.lowbalance.15min"
        static let workoutSynced = "lockedin.workout.synced"
    }

    // Post 5 min warning
    static func postLowBalance5MinWarning()

    // Post 15 min warning
    static func postLowBalance15MinWarning()

    // Post workout synced notification
    static func postWorkoutSynced(earnedMinutes: Int, newBalance: Int, maxBalance: Int)

    // Post workout synced but capped
    static func postWorkoutSyncedCapped(earnedMinutes: Int, workoutMinutes: Int)

    // Internal helper to post notification
    private static func post(identifier: String, title: String, body: String)
}
```

**Key behaviors:**
- Does NOT check settings - caller is responsible for checking settings
- Does NOT check "already notified" - caller is responsible
- Simply posts the notification via UNUserNotificationCenter
- Fires immediately (no scheduling)

### 2. `LockedIn/Views/SettingsView.swift`

Settings screen with notification toggles.

```swift
struct SettingsView: View {
    // Bind to SharedState notification settings
    @State private var notify5Min: Bool
    @State private var notify15Min: Bool
    @State private var notifyWorkout: Bool

    var body: some View {
        // Black background, brutalist style
        // SETTINGS header
        // NOTIFICATIONS section
        //   - Toggle: "5 min warning" (default ON)
        //   - Toggle: "15 min warning" (default OFF)
        //   - Toggle: "Workout synced" (default ON)
    }
}
```

**Design:**
- Matches brutalist aesthetic (AppColor.background, AppFont.label)
- Simple toggles, no explanatory text needed
- Back navigation to dashboard

## Files to Modify

### 1. `Shared/SharedState.swift`

Add notification settings and tracking:

```swift
// MARK: - Notification Settings

/// Whether to notify at 5 min remaining (default: true)
static var notify5MinWarning: Bool {
    get { defaults.object(forKey: Keys.notify5Min) as? Bool ?? true }
    set { defaults.set(newValue, forKey: Keys.notify5Min) }
}

/// Whether to notify at 15 min remaining (default: false)
static var notify15MinWarning: Bool {
    get { defaults.object(forKey: Keys.notify15Min) as? Bool ?? false }
    set { defaults.set(newValue, forKey: Keys.notify15Min) }
}

/// Whether to notify when workout syncs (default: true)
static var notifyWorkoutSync: Bool {
    get { defaults.object(forKey: Keys.notifyWorkout) as? Bool ?? true }
    set { defaults.set(newValue, forKey: Keys.notifyWorkout) }
}

/// Whether 5 min notification already sent today (prevents spam)
static var notified5MinToday: Bool {
    get {
        let storedDate = defaults.object(forKey: Keys.notified5MinDate) as? Date
        guard let date = storedDate, Calendar.current.isDateInToday(date) else {
            return false  // New day, reset
        }
        return defaults.bool(forKey: Keys.notified5MinToday)
    }
    set {
        defaults.set(newValue, forKey: Keys.notified5MinToday)
        defaults.set(Date(), forKey: Keys.notified5MinDate)
    }
}

/// Whether 15 min notification already sent today (prevents spam)
static var notified15MinToday: Bool { ... }  // Same pattern

/// Reset notification flags (call when balance goes above thresholds after workout)
static func resetNotificationFlags(for balance: Int) {
    if balance > 5 { notified5MinToday = false }
    if balance > 15 { notified15MinToday = false }
}

// Keys
private enum Keys {
    // ... existing keys ...
    static let notify5Min = "notify5Min"
    static let notify15Min = "notify15Min"
    static let notifyWorkout = "notifyWorkout"
    static let notified5MinToday = "notified5MinToday"
    static let notified5MinDate = "notified5MinDate"
    static let notified15MinToday = "notified15MinToday"
    static let notified15MinDate = "notified15MinDate"
}
```

### 2. `DeviceActivityMonitorExtension/DeviceActivityMonitorExtension.swift`

Add notification triggering after balance deduction:

```swift
override func eventDidReachThreshold(...) {
    // ... existing deduction logic ...

    // After balance update, check for notification triggers
    let previousBalance = currentBalance  // Before deduction
    let newBalance = result.newBalance    // After deduction

    checkAndPostLowBalanceNotification(
        previousBalance: previousBalance,
        newBalance: newBalance
    )

    // ... rest of existing logic ...
}

private func checkAndPostLowBalanceNotification(previousBalance: Int, newBalance: Int) {
    // Check 15 min threshold crossing
    if previousBalance > 15 && newBalance <= 15 {
        if SharedState.notify15MinWarning && !SharedState.notified15MinToday {
            NotificationManager.postLowBalance15MinWarning()
            SharedState.notified15MinToday = true
            SharedState.synchronize()
        }
    }

    // Check 5 min threshold crossing
    if previousBalance > 5 && newBalance <= 5 {
        if SharedState.notify5MinWarning && !SharedState.notified5MinToday {
            NotificationManager.postLowBalance5MinWarning()
            SharedState.notified5MinToday = true
            SharedState.synchronize()
        }
    }
}
```

### 3. `LockedIn/LockedInApp.swift`

Add workout notification after processing:

```swift
private func processNewWorkouts(_ workouts: [HKWorkout]) {
    for workout in workouts {
        // ... existing processing ...

        // Calculate what would be earned vs what was actually earned
        let workoutMinutes = Int(workout.duration / 60)
        let potentialEarned = Int(Double(workoutMinutes) * bankState.difficulty.screenMinutesPerWorkoutMinute)
        let balanceBefore = bankState.balance

        // Add to balance
        bankState.earn(
            workoutMinutes: workoutMinutes,
            source: source,
            timestamp: workout.endDate
        )

        // Calculate actual earned (may be capped)
        let actualEarned = bankState.balance - balanceBefore

        // Post notification if enabled
        if SharedState.notifyWorkoutSync && actualEarned > 0 {
            if actualEarned < potentialEarned {
                // Some earnings were lost to cap
                NotificationManager.postWorkoutSyncedCapped(
                    earnedMinutes: actualEarned,
                    workoutMinutes: potentialEarned
                )
            } else {
                NotificationManager.postWorkoutSynced(
                    earnedMinutes: actualEarned,
                    newBalance: bankState.balance,
                    maxBalance: bankState.maxBalance
                )
            }
        }

        // Reset notification flags if balance now above thresholds
        SharedState.resetNotificationFlags(for: bankState.balance)

        // Mark as processed
        SharedState.markWorkoutProcessed(workoutID)
    }
}
```

### 4. `LockedIn/Views/DashboardView.swift`

Add gear icon and settings navigation:

```swift
struct DashboardView: View {
    // ... existing properties ...
    @State private var showSettings = false  // ADD

    var body: some View {
        NavigationStack {
            // ... existing content ...
        }
        .navigationDestination(isPresented: $showSettings) {  // ADD
            SettingsView()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("LOCKEDIN")
                // ... existing ...

            Spacer()

            // ADD: Gear icon
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }
}
```

## Testing Strategy

### Unit Tests (NotificationManagerTests.swift)

1. Test notification content generation
2. Test settings check logic
3. Test "already notified" flag behavior
4. Test daily reset of notification flags

### Integration Tests

1. Test threshold crossing detection in extension
2. Test workout notification after sync
3. Test cap detection

### Manual Testing

1. Set balance to 16, use blocked app, verify 15 min notification
2. Continue to 6 min, verify 5 min notification
3. Do a workout, verify workout synced notification
4. Do a workout at cap, verify capped notification
5. Toggle settings off, verify no notifications
6. Verify notifications don't re-fire same day

## Notification Copy (Final)

| Type | Title | Body |
|------|-------|------|
| 5 min warning | LockedIn | 5 min left. The block is coming. |
| 15 min warning | LockedIn | 15 min remaining. |
| Workout synced | LockedIn | +30 min. Bank: 75/120. |
| Workout capped | LockedIn | +10 of 30 min. Bank full. |

## Edge Cases

1. **Rapid balance changes**: Extension might fire multiple events quickly. The "notifiedXMinToday" flags prevent spam.

2. **App killed during deduction**: Notification flags are persisted to SharedState, so they survive app termination.

3. **User disables notifications system-wide**: UNUserNotificationCenter will silently fail. App continues to work.

4. **Multiple workouts same day**: Each gets its own notification (no deduplication for workouts, only for balance warnings).

5. **Balance crosses both 15 and 5 in one deduction**: Both notifications fire (user has both enabled, crossed both). This is intentional - they asked for both.

## Acceptance Criteria Mapping

| Criterion | Implementation |
|-----------|---------------|
| User receives notification at 5 min remaining | DeviceActivityMonitorExtension checks threshold crossing |
| User receives notification when workout syncs | LockedInApp.processNewWorkouts calls NotificationManager |
| User can enable 15 min warning (default OFF) | SharedState.notify15MinWarning, SettingsView toggle |
| User can toggle each notification type independently | SettingsView with 3 toggles |
| Brand voice compliance | Copy in NotificationManager constants |
| Works when app is backgrounded | Extension can post notifications independently |
| No notification spam | notified5MinToday/notified15MinToday flags |
