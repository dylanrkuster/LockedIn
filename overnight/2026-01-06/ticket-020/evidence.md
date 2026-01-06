# Ticket 020: Low Balance Visual Warning - Evidence

## Changes Made

**Files Modified:**

### 1. BalanceDisplay.swift
- Added `lowBalanceThreshold` constant (5 minutes)
- Added `@State private var isPulsing` for animation state
- Added `isLowBalance` computed property
- Balance number pulses (opacity 1.0 → 0.6 → 1.0) when `balance <= 5`
- Animation uses `.easeInOut(duration: 1.25).repeatForever(autoreverses: true)`
- Added `.onAppear` and `.onChange` to handle pulse state transitions
- Added previews for low balance states

### 2. ProgressBar.swift
- Added `lowBalanceThreshold` constant (5 minutes)
- Added `effectiveColor` computed property
- Fill color overrides to `AppColor.extreme` (red) when `current <= 5`
- Works regardless of difficulty level (green Easy bar turns red at ≤5 min)
- Added previews for low balance states

## Design Compliance (MVP.md Appendix D)

- "Motion only for state changes, never for decoration" ✓
- Animation curve: `.easeInOut` only (no spring/bounce) ✓
- Animation duration: 1.25s per cycle (subtle, not aggressive) ✓
- No shaking, bouncing, or color change on balance number ✓
- Progress bar uses red to universally signal danger ✓

## Implementation Details

**Pulse Animation:**
```swift
.opacity(isPulsing && isLowBalance ? 0.6 : 1.0)
.animation(
    isLowBalance
        ? .easeInOut(duration: 1.25).repeatForever(autoreverses: true)
        : .default,
    value: isPulsing
)
```

**Color Override:**
```swift
private var effectiveColor: Color {
    clampedCurrent <= Self.lowBalanceThreshold ? AppColor.extreme : accentColor
}
```

## Testing

- **Build:** Passed
- **Unit Tests:** All 86 tests passed
- **Preview States:** Added previews for 0, 5, 6, and normal balance states

## Behavior

1. Balance > 5: Normal display, no animation, difficulty accent color
2. Balance <= 5:
   - Balance number pulses slowly (1.0 → 0.6 opacity)
   - Progress bar fill turns red regardless of difficulty
3. Balance transitions (6 → 5): Pulse starts, color changes
4. Balance transitions (5 → 6): Pulse stops, color returns to difficulty accent
