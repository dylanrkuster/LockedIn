# Plan: Ticket 001 - Main Dashboard

## Overview

Replace the default Xcode template with the core LockedIn dashboard. This screen is the heart of the app—it displays bank balance, difficulty, and blocked apps. Nothing more.

## Current State

- Default SwiftUI template with `Item` model and `ContentView`
- SwiftData configured but using placeholder `Item` model
- No domain models exist yet

## Target State

Single-screen dashboard matching MVP.md Section 4.2 mockup, using mock data.

---

## Implementation Plan

### Step 1: Create Domain Models

**File:** `LockedIn/LockedIn/Models/Difficulty.swift`

```swift
enum Difficulty: String, CaseIterable {
    case easy = "EASY"
    case medium = "MEDIUM"
    case hard = "HARD"
    case extreme = "EXTREME"

    var conversionRate: Double { ... }  // workout:screen ratio
    var maxBalance: Int { ... }         // cap in minutes
    var tagline: String { ... }         // "I'm just getting started", etc.
}
```

**File:** `LockedIn/LockedIn/Models/BankState.swift`

```swift
@Observable
class BankState {
    var balance: Int           // current minutes
    var difficulty: Difficulty
    var maxBalance: Int { difficulty.maxBalance }
    var progress: Double { Double(balance) / Double(maxBalance) }
}
```

### Step 2: Create Dashboard View

**File:** `LockedIn/LockedIn/Views/DashboardView.swift`

Structure:
```
VStack
├── Header (LOCKEDIN + gear icon)
├── Balance Section
│   ├── Large "MM:SS" text
│   ├── "minutes left" label
│   ├── Progress bar
│   ├── "XX / YY min" label
│   └── Difficulty badge
├── Divider
└── Blocked Apps Section
    ├── Header with count + chevron
    └── App names
```

### Step 3: Create Subcomponents

**File:** `LockedIn/LockedIn/Views/Components/BalanceDisplay.swift`
- Large MM:SS display
- "minutes left" label

**File:** `LockedIn/LockedIn/Views/Components/ProgressBar.swift`
- Filled/unfilled bar based on progress ratio
- "XX / YY min" label

**File:** `LockedIn/LockedIn/Views/Components/BlockedAppsSection.swift`
- Collapsible list of blocked apps

### Step 4: Update App Entry Point

**File:** `LockedIn/LockedIn/LockedInApp.swift`
- Remove SwiftData `Item` schema (not needed yet)
- Create mock `BankState` with hardcoded values
- Render `DashboardView` instead of `ContentView`

### Step 5: Cleanup

- Delete `Item.swift` (unused Xcode template)
- Delete or replace `ContentView.swift`

---

## Files to Create

| Path | Purpose |
|------|---------|
| `Models/Difficulty.swift` | Difficulty enum with rates/caps |
| `Models/BankState.swift` | Observable bank state |
| `Views/DashboardView.swift` | Main dashboard screen |
| `Views/Components/BalanceDisplay.swift` | Balance number + label |
| `Views/Components/ProgressBar.swift` | Visual progress indicator |
| `Views/Components/BlockedAppsSection.swift` | Blocked apps list |

## Files to Modify

| Path | Change |
|------|--------|
| `LockedInApp.swift` | Replace ContentView with DashboardView, inject mock state |

## Files to Delete

| Path | Reason |
|------|--------|
| `Item.swift` | Xcode template placeholder, unused |
| `ContentView.swift` | Replaced by DashboardView |

---

## Mock Data for Development

```swift
let mockBank = BankState(balance: 47, difficulty: .hard)
let mockBlockedApps = ["Instagram", "TikTok", "X", "Snapchat"]
```

---

## Design Notes

- **Typography:** Balance should be the largest element, using a monospace or tabular font for the timer aesthetic
- **Progress bar:** Simple pill shape, filled portion uses accent color
- **Colors:** Keep it minimal—dark text on light background, single accent color
- **Spacing:** Generous padding, clear visual hierarchy
- **No tabs:** Single scroll view, no navigation complexity

---

## Verification

After implementation:
1. Build succeeds
2. App launches to dashboard
3. Balance displays as "47:00"
4. Progress bar shows ~39% filled (47/120)
5. Difficulty shows "HARD"
6. Blocked apps shows 4 apps
7. Settings gear is visible (non-functional for now)
