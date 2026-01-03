# Implementation Plan: Ticket 003 - App Blocking

## Overview

Implement the "spend" side of the core loop: blocked apps decrement balance, shield appears at zero.

**Key Insight:** DeviceActivityEvent thresholds fire when cumulative usage equals the threshold. Set threshold = current balance → fires exactly when balance exhausted.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                           MAIN APP                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────────┐ │
│  │  BankState  │  │  Blocking   │  │  FamilyControlsManager      │ │
│  │  (balance)  │←→│  Manager    │←→│  (selection)                │ │
│  └──────┬──────┘  └──────┬──────┘  └─────────────────────────────┘ │
│         │                │                                          │
│         └────────────────┼──────────────────────────────────────────┤
│                          │         APP GROUPS                       │
│                          ▼         (group.usdk.LockedIn)            │
│                   ┌──────────────┐                                  │
│                   │ SharedState  │ ← balance, selection, difficulty │
│                   └──────┬───────┘                                  │
└──────────────────────────┼──────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────────┐
        ▼                  ▼                      ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────────┐
│ DeviceActivity│  │ ShieldConfig  │  │ ShieldAction      │
│ Monitor Ext   │  │ Extension     │  │ Extension         │
│               │  │               │  │                   │
│ • intervalDid │  │ • Returns     │  │ • Handles button  │
│   Start/End   │  │   brutalist   │  │   taps on shield  │
│ • eventDid    │  │   UI config   │  │ • Opens main app  │
│   ReachThresh │  │               │  │                   │
└───────────────┘  └───────────────┘  └───────────────────┘
```

---

## Phase 1: App Groups & Shared State

### 1.1 Configure App Groups

**In Xcode:**
1. Select LockedIn target → Signing & Capabilities
2. Add "App Groups" capability
3. Create group: `group.usdk.LockedIn`

**In Developer Portal:**
- Enable App Groups for App ID `usdk.LockedIn`
- Add group identifier `group.usdk.LockedIn`

### 1.2 Create SharedState.swift

```swift
// LockedIn/Services/SharedState.swift
import Foundation
import FamilyControls

/// Shared state between main app and extensions via App Groups
enum SharedState {
    static let suiteName = "group.usdk.LockedIn"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    // MARK: - Balance

    static var balance: Int {
        get { defaults.integer(forKey: "balance") }
        set { defaults.set(newValue, forKey: "balance") }
    }

    // MARK: - Difficulty

    static var difficultyRaw: String {
        get { defaults.string(forKey: "difficulty") ?? "medium" }
        set { defaults.set(newValue, forKey: "difficulty") }
    }

    // MARK: - Selection

    static var selectionData: Data? {
        get { defaults.data(forKey: "selection") }
        set { defaults.set(newValue, forKey: "selection") }
    }

    // MARK: - Monitoring State

    static var isMonitoring: Bool {
        get { defaults.bool(forKey: "isMonitoring") }
        set { defaults.set(newValue, forKey: "isMonitoring") }
    }

    static var lastUsageCheck: Date? {
        get { defaults.object(forKey: "lastUsageCheck") as? Date }
        set { defaults.set(newValue, forKey: "lastUsageCheck") }
    }
}
```

### 1.3 Update Entitlements

Add to `LockedIn.entitlements`:
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.usdk.LockedIn</string>
</array>
```

---

## Phase 2: DeviceActivityMonitor Extension

### 2.1 Create Extension Target

**In Xcode:**
1. File → New → Target
2. Select "Device Activity Monitor Extension"
3. Name: `DeviceActivityMonitorExtension`
4. Bundle ID: `usdk.LockedIn.DeviceActivityMonitor`

### 2.2 Configure Extension

**Add to extension's entitlements:**
- Family Controls
- App Groups (same group)

### 2.3 Implement Monitor

```swift
// DeviceActivityMonitorExtension/DeviceActivityMonitorExtension.swift
import DeviceActivity
import ManagedSettings
import FamilyControls

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // Monitoring started - ensure shield state is correct
        syncShieldState()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Day ended - could reset daily tracking here
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)

        // Balance exhausted - apply shield!
        SharedState.balance = 0
        applyShield()
    }

    // MARK: - Shield Management

    private func syncShieldState() {
        if SharedState.balance <= 0 {
            applyShield()
        } else {
            removeShield()
        }
    }

    private func applyShield() {
        guard let data = SharedState.selectionData,
              let selection = try? PropertyListDecoder().decode(
                FamilyActivitySelection.self,
                from: data
              ) else { return }

        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
    }

    private func removeShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }
}
```

---

## Phase 3: ShieldConfiguration Extension

### 3.1 Create Extension Target

**In Xcode:**
1. File → New → Target
2. Select "Shield Configuration Extension"
3. Name: `ShieldConfigurationExtension`
4. Bundle ID: `usdk.LockedIn.ShieldConfiguration`

### 3.2 Configure Extension

**Add to extension's entitlements:**
- Family Controls
- App Groups (same group)

### 3.3 Implement Shield UI

```swift
// ShieldConfigurationExtension/ShieldConfigurationExtension.swift
import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        makeConfiguration()
    }

    private func makeConfiguration() -> ShieldConfiguration {
        let balance = SharedState.balance

        return ShieldConfiguration(
            backgroundBlurStyle: .dark,
            backgroundColor: .black,
            icon: nil, // Use default lock icon
            title: ShieldConfiguration.Label(
                text: "YOU'RE LOCKED OUT",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: balance <= 0
                    ? "Balance: 0 minutes\nEarn more by working out."
                    : "Balance: \(balance) minutes",
                color: .init(white: 0.6, alpha: 1.0)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open LockedIn",
                color: .white
            ),
            primaryButtonBackgroundColor: .init(white: 0.2, alpha: 1.0),
            secondaryButtonLabel: nil
        )
    }
}
```

---

## Phase 4: ShieldAction Extension

### 4.1 Create Extension Target

**In Xcode:**
1. File → New → Target
2. Select "Shield Action Extension"
3. Name: `ShieldActionExtension`
4. Bundle ID: `usdk.LockedIn.ShieldAction`

### 4.2 Implement Button Handler

```swift
// ShieldActionExtension/ShieldActionExtension.swift
import ManagedSettings
import ManagedSettingsUI

class ShieldActionExtension: ShieldActionHandler {

    override func handle(
        action: ShieldAction,
        for application: Application,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            // Open main app
            completionHandler(.defer)
        case .secondaryButtonPressed:
            completionHandler(.none)
        @unknown default:
            completionHandler(.none)
        }
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomain,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handle(action: action, for: Application(), completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategory,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handle(action: action, for: Application(), completionHandler: completionHandler)
    }
}
```

---

## Phase 5: BlockingManager Service

### 5.1 Create BlockingManager.swift

```swift
// LockedIn/Services/BlockingManager.swift
import DeviceActivity
import ManagedSettings
import FamilyControls

@Observable
final class BlockingManager {
    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore()

    private(set) var isMonitoring = false

    static let activityName = DeviceActivityName("lockedin.daily")
    static let balanceEvent = DeviceActivityEvent.Name("balanceExhausted")

    init() {
        isMonitoring = SharedState.isMonitoring
    }

    // MARK: - Monitoring

    func startMonitoring(
        selection: FamilyActivitySelection,
        balance: Int
    ) throws {
        // Schedule covers full day
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        // Event fires when usage equals remaining balance
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            threshold: DateComponents(minute: balance)
        )

        try center.startMonitoring(
            Self.activityName,
            during: schedule,
            events: [Self.balanceEvent: event]
        )

        isMonitoring = true
        SharedState.isMonitoring = true
    }

    func stopMonitoring() {
        center.stopMonitoring([Self.activityName])
        isMonitoring = false
        SharedState.isMonitoring = false
    }

    func updateThreshold(balance: Int, selection: FamilyActivitySelection) throws {
        stopMonitoring()
        if balance > 0 && !selection.applicationTokens.isEmpty {
            try startMonitoring(selection: selection, balance: balance)
        }
    }

    // MARK: - Shield Management

    func applyShield(for selection: FamilyActivitySelection) {
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
    }

    func removeShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    func syncShieldState(balance: Int, selection: FamilyActivitySelection) {
        if balance <= 0 {
            applyShield(for: selection)
        } else {
            removeShield()
        }
    }
}
```

---

## Phase 6: BankState Integration

### 6.1 Update BankState.swift

Make BankState persist to App Groups and sync with blocking:

```swift
@Observable
final class BankState {
    var balance: Int {
        didSet {
            let clamped = max(0, min(balance, maxBalance))
            if balance != clamped { balance = clamped }
            SharedState.balance = balance
        }
    }

    var difficulty: Difficulty {
        didSet {
            SharedState.difficultyRaw = difficulty.rawValue
        }
    }

    // ... rest of implementation

    init() {
        // Load from SharedState or use defaults
        let savedBalance = SharedState.balance
        let savedDifficulty = Difficulty(rawValue: SharedState.difficultyRaw) ?? .medium

        self.difficulty = savedDifficulty
        self.balance = savedBalance > 0 ? savedBalance : 60 // Default starting balance

        // Sync to SharedState
        SharedState.balance = self.balance
        SharedState.difficultyRaw = self.difficulty.rawValue
    }
}
```

### 6.2 Update FamilyControlsManager.swift

Persist selection to SharedState instead of regular UserDefaults:

```swift
private func saveSelection() {
    do {
        let data = try PropertyListEncoder().encode(selection)
        SharedState.selectionData = data  // Changed from UserDefaults.standard
    } catch {
        print("Failed to save selection: \(error)")
    }
}

private func loadSelection() {
    guard let data = SharedState.selectionData else { return }  // Changed
    do {
        selection = try PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
    } catch {
        print("Failed to load selection: \(error)")
    }
}
```

---

## Phase 7: App Integration

### 7.1 Update LockedInApp.swift

Initialize blocking on app launch:

```swift
@main
struct LockedInApp: App {
    @State private var bankState = BankState()
    @State private var familyControlsManager = FamilyControlsManager()
    @State private var blockingManager = BlockingManager()

    var body: some Scene {
        WindowGroup {
            DashboardView(
                bankState: bankState,
                familyControlsManager: familyControlsManager
            )
            .onAppear {
                setupBlocking()
            }
            .onChange(of: familyControlsManager.selection) { _, newSelection in
                updateBlocking(selection: newSelection)
            }
            .onChange(of: bankState.balance) { _, newBalance in
                updateBlocking(balance: newBalance)
            }
        }
    }

    private func setupBlocking() {
        guard familyControlsManager.isAuthorized,
              familyControlsManager.hasBlockedApps else { return }

        blockingManager.syncShieldState(
            balance: bankState.balance,
            selection: familyControlsManager.selection
        )

        try? blockingManager.startMonitoring(
            selection: familyControlsManager.selection,
            balance: bankState.balance
        )
    }

    private func updateBlocking(selection: FamilyActivitySelection? = nil, balance: Int? = nil) {
        let sel = selection ?? familyControlsManager.selection
        let bal = balance ?? bankState.balance

        blockingManager.syncShieldState(balance: bal, selection: sel)
        try? blockingManager.updateThreshold(balance: bal, selection: sel)
    }
}
```

---

## File Summary

### New Files
| File | Purpose |
|------|---------|
| `Services/SharedState.swift` | App Groups shared state |
| `Services/BlockingManager.swift` | Monitoring orchestration |
| `DeviceActivityMonitorExtension/` | Usage tracking extension |
| `ShieldConfigurationExtension/` | Shield UI customization |
| `ShieldActionExtension/` | Shield button handling |

### Modified Files
| File | Changes |
|------|---------|
| `LockedIn.entitlements` | Add App Groups |
| `Models/BankState.swift` | Persist to SharedState |
| `Services/FamilyControlsManager.swift` | Use SharedState for selection |
| `LockedInApp.swift` | Initialize and manage blocking |
| `project.pbxproj` | New targets, frameworks |

---

## Testing Plan

1. **Select apps** → Verify monitoring starts
2. **Open blocked app** → Watch balance (update on app foreground)
3. **Use blocked app until balance = 0** → Shield should appear
4. **Tap "Open LockedIn"** → Main app opens
5. **Set balance > 0 manually** → Shield should disappear
6. **Kill main app, use blocked app** → Shield still works

---

## Known Limitations

1. **Balance UI doesn't update in real-time while using blocked app**
   - Updates when user returns to LockedIn
   - Acceptable for MVP; enhancement: background refresh

2. **1-minute threshold granularity**
   - Can't track seconds, only whole minutes
   - Acceptable for the use case

3. **Shield customization limits**
   - Apple controls overall layout
   - Can set colors, text, buttons - not full custom UI
