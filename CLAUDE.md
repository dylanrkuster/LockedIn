# LockedIn Project Guide

## Workflow
Use `/ticket [id]` to start the structured workflow:

```
PROPOSAL → PLAN → DEVELOP → VERIFY → REVIEW → APPROVE
           ↑        ↑                  ↑
        (gate)   (test)             (gate)
```

**Gates require user approval.** Other phases auto-advance.

**Trivial changes** (typos, config) skip planning and go straight to implement.

## Phase Rules
1. **PLAN**: Always get approval before coding non-trivial changes
2. **DEVELOP**: Bug fixes and feature changes require unit tests
   - New features: Add tests covering the new functionality
   - Bug fixes: Add regression test proving the fix works
   - Tests must pass before advancing to VERIFY
3. **VERIFY**: Take screenshots as evidence; tests must pass
4. **REVIEW**: Spawn code-reviewer agent for independent review
5. **APPROVE**: Present summary and wait for user sign-off

## Project Structure
```
LockedIn/
  ├── Shared/                      # Shared code (multi-target membership)
  │   ├── SharedState.swift        # Cross-process state
  │   ├── ExtensionLogger.swift    # Diagnostic logging
  │   ├── TrackingLogic.swift      # Pure tracking logic (testable)
  │   ├── AppUsageRecord.swift
  │   └── TransactionRecord.swift
  ├── LockedIn/                    # Main iOS app (app-specific code only)
  │   ├── LockedInApp.swift
  │   ├── Models/
  │   ├── Views/
  │   └── DesignSystem.swift
  ├── LockedInTests/               # Unit tests (86 tests)
  │   ├── BankStateTests.swift
  │   ├── DifficultyTests.swift
  │   ├── ExtensionLoggerTests.swift
  │   ├── SharedStateTests.swift
  │   ├── TrackingLogicTests.swift
  │   └── TransactionTests.swift
  ├── DeviceActivityMonitorExtension/
  ├── ShieldActionExtension/
  ├── ShieldConfigurationExtension/
  └── LockedIn.xcodeproj
tickets/                  # Ticket definitions (YAML)
qa/screenshots/           # QA evidence
plans/                    # Implementation plans
```

## Shared Files Architecture

The `Shared/` folder contains code compiled into ALL targets (main app + 3 extensions).

**How it works:**
- `Shared/` is a File System Synchronized Group
- It has target membership for: LockedIn, DeviceActivityMonitorExtension, ShieldConfigurationExtension, ShieldActionExtension
- Files appear ONCE in Xcode, compile to all targets

**Adding new shared files:**
1. Create file in `Shared/` folder
2. It automatically compiles to all targets (no manual steps needed)

**DO NOT**:
- Create duplicate files in target folders
- Put target-specific code in `Shared/`

## Build Commands
```bash
# Build
xcodebuild build -scheme LockedIn \
  -project LockedIn/LockedIn.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'

# Test (must pass before VERIFY phase)
xcodebuild test -scheme LockedIn \
  -project LockedIn/LockedIn.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'
```

## Key Frameworks
- **FamilyControls**: Request authorization to block apps
- **ManagedSettings**: Apply app restrictions
- **DeviceActivity**: Schedule and monitor blocking
- **HealthKit**: Read workout data from Apple Health

## Quality Standards
- Evidence-first: screenshots prove UI changes work
- Tests required for logic changes
- Self-review before spawning external reviewer
- No hallucinated results - use tools to verify

## Optimization
- Use `ultrathink` for complex decisions
- Parallelize with Explore sub-agents (haiku)
- Compact context at phase boundaries
- Update SCRATCHPAD.md to maintain state
