# Ticket 022: Watch Complication Onboarding

## Overview
Add Apple Watch complication setup section to the WidgetsScreen in onboarding flow.

## Design Approach

### Conditional Display
- Check `WCSession.default.isPaired` to detect if user has Apple Watch
- Only show watch section if watch is paired
- Use `WCSession.isSupported()` guard for devices without WatchConnectivity

### UI Changes to WidgetsScreen

1. **Add state for watch detection**
   - `@State private var isWatchPaired = false`
   - Check on `.onAppear`

2. **Add Watch Complication Showcase** (after Home Screen widget)
   - Title: "APPLE WATCH"
   - Subtitle: "Complication on your watch face"
   - Preview: Reuse `LockScreenWidgetPreview` (circular gauge matches watch aesthetic)

3. **Add Watch-Specific Instructions** (shown only if watch paired)
   - Step 1: "Long press watch face"
   - Step 2: "Tap Edit, then swipe to complications"
   - Step 3: "Select slot, choose LOCKEDIN"

### Implementation

Modify `WidgetsScreen` in OnboardingView.swift:
- Add `WatchConnectivity` import
- Add watch paired state
- Add conditional watch section with showcase and instructions

## Files Modified
- `LockedIn/LockedIn/Views/OnboardingView.swift`

## Testing
- Build and run on simulator
- Manual verification of UI layout
- Test with/without watch paired (if possible)
