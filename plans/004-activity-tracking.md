# Plan: Ticket 004 - Activity Tracking and Balance System

## Overview

Implement the core loop: workouts earn minutes, blocked app usage spends minutes, all tracked in real-time with per-app granularity.

---

## Part 1: HealthKit Integration (Earning)

### New File: `LockedIn/Services/HealthKitManager.swift`

**Responsibilities:**
- Request HealthKit authorization on app launch
- Fetch workouts from last 7 days
- Observe new workouts in background
- Calculate earned minutes using difficulty multiplier
- Track processed workout UUIDs to prevent double-counting

**Key behaviors:**
- Background observer via `HKObserverQuery` + `enableBackgroundDelivery`
- Workout type mapping (Running → "Run", HIIT → "HIIT", etc.)
- Earned minutes calculation: `floor(duration_minutes × difficulty.screenMinutesPerWorkoutMinute)`

### Modifications:

**`LockedInApp.swift`:**
- Instantiate `HealthKitManager`
- Call `requestAuthorization()` on launch
- Set up workout observation callback to update `BankState`

**`Info.plist`:**
- Add `NSHealthShareUsageDescription` with clear copy

**`LockedIn.entitlements`:**
- Add HealthKit capability

---

## Part 2: Transaction Persistence

### Modifications to `SharedState.swift`:

Add new stored properties:
- `transactions: [TransactionRecord]` - Codable array, 7-day retention
- `processedWorkoutIDs: Set<String>` - Prevent double-counting
- `lastHealthKitSync: Date` - Track sync state

### New File: `LockedIn/Models/TransactionRecord.swift`

Codable struct for persistence:
```swift
struct TransactionRecord: Codable, Identifiable {
    let id: UUID
    let amount: Int
    let source: String
    let timestamp: Date
}
```

### Modifications to `BankState.swift`:

- Load transactions from `SharedState` on init
- Persist transactions to `SharedState` on mutation
- Auto-prune transactions older than 7 days

---

## Part 3: Per-App Usage Tracking (Spending)

### Challenge

DeviceActivityMonitor only fires when thresholds are reached—it doesn't provide real-time usage callbacks or per-app breakdown. The current implementation fires once when `total_usage >= balance`, then sets balance to 0.

### Solution: Individual App Events

Modify `BlockingManager` to create **separate events for each blocked app**:

```
For each app token in selection:
  Create event with threshold = 1 minute
  Event name = unique identifier for that app
```

When an event fires:
1. Extension receives `eventDidReachThreshold` with event name
2. Look up which app triggered (from event name)
3. Log 1-minute transaction for that specific app
4. Deduct 1 minute from balance

**Caveat:** Events fire once per monitoring interval. For continuous tracking, we'll restart monitoring after each event to reset thresholds.

### Resolving App Names from Tokens

FamilyControls tokens are opaque. Two approaches:

1. **Store metadata at selection time**: When user picks apps via `FamilyActivityPicker`, we don't get names. The picker only returns tokens.

2. **Use Application.localizedDisplayName**: `Application` objects have a `localizedDisplayName` property. We need to store the app name when creating events, using the token's hash as key.

Actually, the `Application` type has:
- `bundleIdentifier: String?`
- `localizedDisplayName: String?`
- `token: ApplicationToken`

We can store a mapping: `[token_hash: app_name]` in SharedState.

### Modifications:

**`BlockingManager.swift`:**
- Create per-app events instead of single threshold
- Track app token → name mapping
- Handle event callbacks to log per-app transactions

**`DeviceActivityMonitorExtension.swift`:**
- Handle per-app event thresholds
- Write transactions to SharedState with app names
- Restart monitoring to continue tracking after each event

**`SharedState.swift`:**
- Add `appNameMapping: [String: String]` (token hash → display name)

---

## Part 4: Wire Real Data to UI

### Modifications to `DashboardView.swift`:

Currently passes mock data:
```swift
ActivitySection(transactions: Transaction.mock, accentColor: ...)
```

Change to:
```swift
ActivitySection(transactions: bankState.recentTransactions, accentColor: ...)
```

`BankState.recentTransactions` already:
- Sorts by timestamp descending
- Returns only 8 most recent

### Modifications to `BankState.swift`:

The `earn()` method already creates transactions. Enhance it to:
- Accept workout type name as source (not just "Workout")
- Persist transaction to SharedState immediately

The `spend()` method already creates transactions. Enhance it to:
- Accept specific app name as source
- Persist transaction to SharedState immediately

---

## Implementation Order

1. **HealthKitManager** - New service, request auth, fetch/observe workouts
2. **TransactionRecord + SharedState persistence** - Codable storage
3. **BankState persistence** - Load/save transactions
4. **Per-app events in BlockingManager** - Individual app tracking
5. **Extension updates** - Log per-app spend transactions
6. **UI wiring** - Remove mock data, use real transactions
7. **Testing** - Build, run, verify all acceptance criteria

---

## Files to Create

| File | Purpose |
|------|---------|
| `LockedIn/Services/HealthKitManager.swift` | HealthKit auth, queries, observation |
| `LockedIn/Models/TransactionRecord.swift` | Codable transaction for persistence |

## Files to Modify

| File | Changes |
|------|---------|
| `LockedInApp.swift` | Init HealthKitManager, request auth on launch |
| `SharedState.swift` | Add transactions, processedWorkoutIDs, appNameMapping |
| `BankState.swift` | Load/save transactions, enhanced earn/spend |
| `BlockingManager.swift` | Per-app events, token→name mapping |
| `DeviceActivityMonitorExtension.swift` | Per-app event handling, transaction logging |
| `DashboardView.swift` | Wire real transactions to ActivitySection |
| `Info.plist` | HealthKit usage description |
| `LockedIn.entitlements` | HealthKit capability |

---

## Known Limitations

1. **Event granularity**: Per-app events fire after 1 minute of usage. Sub-minute tracking isn't practical.

2. **Monitoring restart**: After each event fires, monitoring must restart to reset thresholds. This may cause brief gaps in tracking.

3. **App names**: If FamilyActivityPicker doesn't expose names (only tokens), we may need to show generic names or use bundle IDs where available.

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Per-app events don't fire as expected | High | Test thoroughly; fallback to aggregate tracking |
| HealthKit background delivery unreliable | Medium | Also fetch on app foreground |
| Token → name mapping incomplete | Medium | Graceful fallback to "App" or bundle ID |
