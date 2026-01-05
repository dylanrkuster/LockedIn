# Plan: Ticket 011 - Onboarding Flow

## Overview

5-screen onboarding flow that runs once for new users before showing the dashboard.

## Architecture Decision

**Single file approach** (`OnboardingView.swift`) with internal views for each screen:
- Keeps navigation state management cohesive
- Reduces file proliferation for a self-contained flow
- Internal views can be extracted later if needed

## File Changes

### 1. New File: `LockedIn/LockedIn/Views/OnboardingView.swift`

Contains:
- `OnboardingView` - Container managing navigation state
- `OnboardingStep` enum - Step tracking
- Private internal views for each screen:
  - `WelcomeScreen`
  - `AppSelectionScreen`
  - `DifficultyScreen`
  - `PermissionsScreen`
  - `ActivationScreen`

### 2. Modify: `LockedIn/Shared/SharedState.swift`

Add:
```swift
// Keys
static let hasCompletedOnboarding = "hasCompletedOnboarding"

// Property
static var hasCompletedOnboarding: Bool {
    get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
    set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
}

// Update defaultStartingBalance from 2 to 60
static let defaultStartingBalance = 60
```

### 3. Modify: `LockedIn/LockedIn/LockedInApp.swift`

Change root view logic:
```swift
var body: some Scene {
    WindowGroup {
        if SharedState.hasCompletedOnboarding {
            DashboardView(...)
        } else {
            OnboardingView(
                familyControlsManager: familyControlsManager,
                healthKitManager: healthKitManager,
                onComplete: { difficulty in
                    // Set difficulty, set balance, mark complete
                    // Then navigate to dashboard
                }
            )
        }
    }
}
```

## Screen Specifications

### Screen 1: Welcome
- Header: "LOCKEDIN"
- Body: "Earn your screen time.\nOne workout at a time."
- CTA: "GET STARTED"
- No back button

### Screen 2: App Selection
- Header: "SELECT YOUR POISON"
- Subtext: "These apps get blocked when your bank hits zero."
- Button: "CHOOSE APPS" opens FamilyActivityPicker as sheet
- Shows count after selection: "4 apps selected"
- Continue disabled until ≥1 app selected
- Back button enabled

### Screen 3: Difficulty Selection
- Header: "HOW LOCKED IN ARE YOU?"
- Four tappable cards showing:
  - Rank bars (1-4 filled)
  - Difficulty name
  - Ratio display
  - Max bank
  - Tagline
- MEDIUM pre-selected
- Selected card has accent color border
- Continue always enabled
- Back button enabled

### Screen 4: Permissions
Combined Screen Time + Health permissions:
- Screen Time first (required):
  - Header: "SCREEN TIME ACCESS"
  - Subtext: "Required to block apps."
  - "GRANT ACCESS" triggers FamilyControls auth
  - If denied: show alert, cannot proceed
- Health second (optional):
  - Header: "APPLE HEALTH ACCESS"
  - Subtext: "Required to track workouts."
  - "GRANT ACCESS" triggers HealthKit auth
  - If denied: show warning text, allow continue
- Back button enabled

### Screen 5: Activation
- Header: "YOU'RE LOCKED IN"
- Shows: "Starting Bank: 60 min"
- Shows: difficulty badge + blocked app count
- Tagline: "Your bank is ticking. Go earn more."
- CTA: "LET'S GO" completes onboarding
- No back button (final commit screen)

## State Management

```swift
enum OnboardingStep: Int, CaseIterable {
    case welcome
    case appSelection
    case difficulty
    case permissions
    case activation
}

// Track within OnboardingView
@State private var currentStep: OnboardingStep = .welcome
@State private var selectedDifficulty: Difficulty = .medium
@State private var hasGrantedScreenTime: Bool = false
@State private var hasGrantedHealth: Bool = false
@State private var healthDenied: Bool = false
```

## UI Components

### Reuse existing:
- `AppColor`, `AppFont`, `AppSpacing` (DesignSystem.swift)
- `Difficulty.color`, `Difficulty.barCount`
- FamilyActivityPicker pattern from BlockedAppsSection

### New components (internal to OnboardingView):
- `OnboardingButton` - White outline button style
- `DifficultyCard` - Larger card for selection (different from DifficultyBadge)

## Button Style

```swift
// Consistent CTA style throughout
Text("GET STARTED")
    .font(AppFont.label(13))
    .tracking(2)
    .foregroundStyle(AppColor.textPrimary)
    .frame(maxWidth: .infinity)
    .frame(height: 52)
    .overlay(
        Rectangle()
            .stroke(AppColor.textPrimary, lineWidth: 1)
    )
```

## Navigation

- Forward: Replace current screen with next (no stack)
- Back: Replace with previous (where allowed)
- Use `@State var currentStep` to drive which screen shows
- No NavigationStack - simple switch-based rendering

## Permission Flow

### Screen Time (FamilyControls):
```swift
func requestScreenTimeAccess() async {
    let authorized = await familyControlsManager.requestAuthorizationIfNeeded()
    hasGrantedScreenTime = authorized
    if familyControlsManager.wasDenied {
        showDeniedAlert = true
    }
}
```

### Health (HealthKit):
```swift
func requestHealthAccess() async {
    do {
        try await healthKitManager.requestAuthorization()
        hasGrantedHealth = true
    } catch {
        healthDenied = true
    }
}
```

## Completion Flow

When user taps "LET'S GO":
1. Save selected difficulty to SharedState
2. Initialize balance at 60 minutes
3. Set `SharedState.hasCompletedOnboarding = true`
4. Trigger re-render showing DashboardView

## Edge Cases

| Case | Handling |
|------|----------|
| App killed mid-flow | Restart from beginning (no partial state saved) |
| Screen Time already authorized | Show screen, auto-show success state |
| Screen Time denied | Block progress with alert |
| Health already authorized | Show screen, auto-show success state |
| Health denied | Show warning, allow continue |
| No apps selected | Continue button disabled |

## Testing Notes

- Test fresh install → onboarding → dashboard
- Test Screen Time denial flow
- Test Health denial flow (should allow continue)
- Test back navigation on each screen
- Test app kill mid-onboarding
- Test that onboarding flag persists (only shows once)
- Verify 60-minute starting balance after completion
