# Ticket Workflow Guide

## Overview

This project uses a single-instance Claude Code workflow with skill-based phases. Instead of spawning multiple agent processes, we leverage Claude Code's native features for speed and quality.

```
/new-ticket → PROPOSAL → PLAN → DEVELOP → VERIFY → REVIEW → APPROVE
                         ↑                          ↑
                      (gate)                     (gate)
```

**Gates** require explicit user approval. Other phases auto-advance.

---

## Quick Start

```bash
# 1. Create a ticket from your bug/feature description
/new-ticket The bank balance doesn't update after a workout syncs

# 2. Run the implementation workflow
/ticket 003
```

---

## Creating Tickets with `/new-ticket`

The `/new-ticket` command transforms informal bug reports and feature requests into structured tickets.

### Basic Usage

```bash
# With inline description
/new-ticket <your description here>

# Interactive mode (Claude asks questions)
/new-ticket
```

### Examples

#### Bug Report
```
/new-ticket The app crashes when I select an app to block
```

Claude will ask clarifying questions like:
- Does this happen every time?
- What app were you trying to block?
- Do you see an error message before the crash?

Then generate:
```yaml
id: '004'
type: bug
title: App crashes when selecting app to block
priority: P1
complexity: standard

description: |
  ## Summary
  The app crashes when attempting to select an app for blocking
  during onboarding or in settings.

  ## Context
  Users cannot complete setup if they can't select apps to block.
  This is a critical path failure.

acceptance_criteria:
- App picker displays without crashing
- Selected apps are saved to blocklist
- Existing blocked apps are unaffected
- No crash or data loss occurs

steps_to_reproduce:
- Open the app
- Navigate to app selection
- Tap on an app to block

expected_behavior: App is added to blocked list
actual_behavior: App crashes immediately

status: pending
created: 2026-01-02
```

#### Feature Request
```
/new-ticket I want to see my workout history and how many minutes I've earned
```

Claude will ask:
- How far back should history go?
- Should it show individual workouts or daily summaries?
- Do you want to see which apps consumed the earned time?

Then generate:
```yaml
id: '005'
type: feature
title: Add workout history with earned minutes
priority: P2
complexity: complex

description: |
  ## Summary
  Allow users to view their workout history and see how many
  minutes they've earned from each workout.

  ## Context
  Users want visibility into their fitness-to-screen-time
  conversion to stay motivated and understand the system.

  ## Technical Notes
  - Pull data from WorkoutLog entries
  - Consider infinite scroll or pagination
  - May need date range filtering

acceptance_criteria:
- History view accessible from main dashboard
- Shows last 30 days of workouts by default
- Each entry shows: date, workout type, duration, minutes earned
- Can tap workout for details
- Total earned this week/month visible

status: pending
created: 2026-01-02
```

### Ticket Types

| Type | When to Use |
|------|-------------|
| `bug` | Something is broken or not working as expected |
| `feature` | New functionality that doesn't exist yet |
| `improvement` | Enhancement to existing functionality |
| `chore` | Maintenance, cleanup, typos, dependency updates |

### Priority Levels

| Priority | Meaning | Examples |
|----------|---------|----------|
| `P0` | Critical - app unusable | Crash on launch, data loss |
| `P1` | High - major feature broken | Can't block apps, HealthKit broken |
| `P2` | Medium - annoying but workaround exists | Slow sync, minor UI bug |
| `P3` | Low - nice to have | Typos, minor polish |

### Complexity Levels

| Complexity | Criteria | Workflow Impact |
|------------|----------|-----------------|
| `trivial` | Single file, <10 lines, obvious fix | Skips PLAN phase |
| `standard` | Multiple files, clear requirements | Full workflow |
| `complex` | Architectural changes, ambiguous scope | Extra planning, may need ultrathink |

---

## Running Tickets with `/ticket`

Once a ticket is created, run the implementation workflow:

```bash
/ticket 003
```

### Phases

#### 1. PROPOSAL (Auto-advance)
- Read and understand the ticket
- Classify complexity: `trivial` | `standard` | `complex`
- Ask clarifying questions if requirements are ambiguous

**Trivial tickets** skip directly to DEVELOP.

#### 2. PLAN (User Gate)
- Explore codebase to find relevant files
- Design implementation approach
- Document plan in `plans/ticket-XXX.md`
- **Stop and wait for user approval**

#### 3. DEVELOP (Auto-advance)
- Create feature branch: `git checkout -b ticket-XXX`
- Implement changes following the approved plan
- Write unit tests
- Run build and tests
- Commit with proper message

#### 4. VERIFY (Auto-advance)
- Boot iOS simulator
- Build and install app
- Take screenshots proving feature works
- Test data persistence (if applicable)
- Document verification in `qa/reports/ticket-XXX.md`

#### 5. REVIEW (Auto-advance)
- Spawn code-reviewer sub-agent for independent review
- Address any P1/P2 issues found
- Re-verify if changes were made

#### 6. APPROVE (User Gate)
- Present summary of all work done
- Show test results and screenshots
- **Stop and wait for user approval**
- On approval: merge to main, close ticket

---

## Key Commands

| Command | Purpose |
|---------|---------|
| `/new-ticket [description]` | Create a new ticket from informal description |
| `/ticket [id]` | Start workflow for a ticket |
| `/next-ticket` | Start workflow for next open ticket |
| `/work-while-i-sleep` | Autonomous overnight work on multiple tickets |
| `/reopen-ticket [id]` | Reopen and rework a closed ticket |
| `ultrathink` | Deep thinking for complex decisions |
| `/compact` | Reset context (use at phase boundaries) |
| `/context` | Check context usage (target <60%) |
| `Esc+Esc` | Rewind to previous checkpoint |
| `/plan` | Enter planning mode explicitly |

---

## Directory Structure

```
.claude/
├── skills/
│   ├── ticket-creation/
│   │   └── SKILL.md      # Ticket creation skill
│   ├── ticket-workflow/
│   │   ├── SKILL.md      # Main workflow (loads on-demand)
│   │   └── QA.md         # QA procedures
│   └── debugging/
│       └── SKILL.md      # Debugging framework
├── commands/
│   ├── new-ticket.md     # /new-ticket command
│   ├── ticket.md         # /ticket command
│   ├── next-ticket.md    # /next-ticket command
│   ├── work-while-i-sleep.md  # Overnight autonomous work
│   └── reopen-ticket.md  # Reopen closed tickets
└── agents/
    └── code-reviewer.md  # Independent review agent

plans/                    # Implementation plans
qa/
├── reports/             # Verification reports
└── screenshots/         # Evidence screenshots
tickets/                  # Ticket definitions (YAML)
overnight/                # Overnight work logs
```

---

## State Management

### SCRATCHPAD.md
Tracks current work state across context resets:
```markdown
## Current Ticket: 003
### Phase: DEVELOP (3/6)
### Key Decisions:
- Using BankManager for balance operations
### Files Modified:
- BankManager.swift
- HealthKitService.swift
```

### Todo List
Claude maintains an explicit todo list with phase tracking. This serves as "recitation" - keeping objectives in the model's attention span.

---

## Optimization Tips

### Context Management
- Use `/context` to monitor usage
- Compact when reaching 60% capacity
- Update SCRATCHPAD.md before compacting

### Parallelization
- Explore sub-agents run searches in parallel
- Tests can run in background while documenting
- Use `run_in_background: true` for long operations

### Model Selection
- **Haiku**: Quick file searches, simple checks
- **Sonnet**: Standard implementation, code review
- **Opus + ultrathink**: Complex architectural decisions

### Speed Tips
- Trivial tickets skip planning phase
- Parallel Explore agents for codebase search
- Background test execution
- Streamlined context (no serialization overhead)

---

## Quality Standards

1. **Evidence-first**: Screenshots prove UI changes work
2. **Tests required**: Logic changes need unit tests
3. **No hallucination**: Use tools to verify, never claim without proof
4. **Independent review**: Code-reviewer agent checks for bugs

---

## Troubleshooting

### Context window filling up
1. Check with `/context`
2. Update SCRATCHPAD.md with current state
3. Run `/compact` to reset
4. Continue from recorded state

### Phase stuck or wrong
1. Use `Esc+Esc` to rewind
2. Update SCRATCHPAD.md manually
3. Re-state current phase to Claude

### Screenshots not working
```bash
# Check simulator is booted
xcrun simctl list devices | grep Booted

# Boot if needed
xcrun simctl boot "iPhone 16"

# Verify app is installed
xcrun simctl listapps booted | grep LockedIn
```

### Build failures
```bash
# Clean build
xcodebuild clean -scheme LockedIn -project LockedIn/LockedIn.xcodeproj

# Rebuild
xcodebuild build -scheme LockedIn \
  -project LockedIn/LockedIn.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2'
```

### HealthKit Testing Limitations
The iOS Simulator has limited HealthKit support:
- Cannot grant full HealthKit permissions
- Workout data may not sync properly
- For complete testing, use a physical device

### FamilyControls/Screen Time Testing
These APIs require:
- Physical device with proper entitlements
- Apple Developer account with Screen Time capability
- Device not in supervised mode (unless testing MDM features)
