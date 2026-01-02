# QA Verification Procedures

## iOS Simulator Commands

### Setup
```bash
# List available simulators
xcrun simctl list devices available

# Boot iPhone 16 simulator (iOS 18.2)
xcrun simctl boot "iPhone 16"

# Check if booted
xcrun simctl list devices | grep Booted
```

### Build and Install
```bash
# Build for simulator
xcodebuild build \
  -scheme LockedIn \
  -project LockedIn/LockedIn.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' \
  -derivedDataPath build

# Install app
xcrun simctl install booted \
  build/Build/Products/Debug-iphonesimulator/LockedIn.app

# Launch app
xcrun simctl launch booted com.lockedin.LockedIn
```

### Screenshots
```bash
# Create screenshot directory
mkdir -p qa/screenshots/ticket-XXX

# Take screenshot
xcrun simctl io booted screenshot qa/screenshots/ticket-XXX/description.png
```

### Persistence Testing
```bash
# Terminate app
xcrun simctl terminate booted com.lockedin.LockedIn

# Relaunch
xcrun simctl launch booted com.lockedin.LockedIn

# Take screenshot to prove persistence
xcrun simctl io booted screenshot qa/screenshots/ticket-XXX/after-restart.png
```

### App Data Access
```bash
# Get app container path
xcrun simctl get_app_container booted com.lockedin.LockedIn data

# List contents
ls -la "$(xcrun simctl get_app_container booted com.lockedin.LockedIn data)"
```

## Verification Checklist

For each acceptance criterion:
1. [ ] Perform the user action
2. [ ] Observe the result
3. [ ] Take screenshot as evidence
4. [ ] Document in verification report

## Report Format

Create `qa/reports/ticket-XXX.md`:
```markdown
# QA Report: Ticket XXX

## Summary
- Status: PASS | FAIL
- Date: YYYY-MM-DD
- Tester: Claude Code

## Acceptance Criteria Verification

### Criterion 1: [Description]
- **Expected:** [What should happen]
- **Actual:** [What happened]
- **Evidence:** [Screenshot path]
- **Result:** PASS | FAIL

### Criterion 2: ...

## Edge Cases Tested
- [ ] Edge case 1 - Result
- [ ] Edge case 2 - Result

## Persistence Test
- Data survives app restart: YES | NO
- Evidence: [Screenshot path]

## Issues Found
- None | List issues

## Screenshots
- qa/screenshots/ticket-XXX/main-feature.png
- qa/screenshots/ticket-XXX/edge-case.png
- qa/screenshots/ticket-XXX/after-restart.png
```

## LockedIn-Specific Testing

### Bank Balance Testing
```bash
# Check UserDefaults for balance
xcrun simctl spawn booted defaults read com.lockedin.LockedIn bankBalance
```

### HealthKit Testing
Note: Simulator has limited HealthKit support. For full testing:
1. Use sample workout data injection
2. Test on physical device for complete verification

### Screen Time Testing
Note: FamilyControls and ManagedSettings require:
1. Physical device testing
2. Proper entitlements
3. Family Sharing setup (for some features)

Document when simulator limitations prevent full verification.
