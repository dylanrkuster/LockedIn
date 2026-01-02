# LockedIn Project Guide

## Workflow
Use `/ticket [id]` to start the structured workflow:

```
PROPOSAL → PLAN → DEVELOP → VERIFY → REVIEW → APPROVE
           ↑                          ↑
        (gate)                     (gate)
```

**Gates require user approval.** Other phases auto-advance.

**Trivial changes** (typos, config) skip planning and go straight to implement.

## Phase Rules
1. **PLAN**: Always get approval before coding non-trivial changes
2. **VERIFY**: Take screenshots as evidence; tests must pass
3. **REVIEW**: Spawn code-reviewer agent for independent review
4. **APPROVE**: Present summary and wait for user sign-off

## Project Structure
```
LockedIn/LockedIn/        # iOS app source
  ├── LockedInApp.swift
  ├── ContentView.swift
  └── ...
LockedIn/LockedIn.xcodeproj
tickets/                  # Ticket definitions (YAML)
qa/screenshots/           # QA evidence
plans/                    # Implementation plans
```

## Build Commands
```bash
# Build
xcodebuild build -scheme LockedIn \
  -project LockedIn/LockedIn.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2'

# Test (must pass before VERIFY phase)
xcodebuild test -scheme LockedIn \
  -project LockedIn/LockedIn.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2'
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
