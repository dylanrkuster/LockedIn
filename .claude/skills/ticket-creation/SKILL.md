# Ticket Creation Skill

## Description
Transforms informal bug reports and feature requests into structured tickets ready for the development workflow.

## Triggers
- User runs `/new-ticket`
- User says "I want to report a bug" or "I have a feature idea"
- User describes a problem or enhancement informally

## Process

### Step 1: Capture Initial Description
Listen to the user's informal description. They might say things like:
- "The app crashes when..."
- "It would be nice if..."
- "There's a bug where..."
- "Can you add..."

### Step 2: Classify Type
Determine the ticket type:

| Type | Indicators |
|------|------------|
| `bug` | "crashes", "doesn't work", "broken", "error", "wrong" |
| `feature` | "add", "new", "would be nice", "I want" |
| `improvement` | "better", "faster", "cleaner", "refactor" |
| `chore` | "update", "upgrade", "maintenance", "cleanup" |

### Step 3: Ask Clarifying Questions

**For Bugs:**
1. What were you trying to do? (steps to reproduce)
2. What did you expect to happen?
3. What actually happened?
4. Does it happen every time?
5. Any error messages?

**For Features:**
1. What problem does this solve?
2. Who benefits from this?
3. What's the simplest version that would be useful?
4. Are there edge cases to consider?
5. How will we know it's working correctly?

**For Both:**
- Is this blocking anything?
- What priority would you assign? (P0-P3)

### Step 4: Extract Acceptance Criteria
Transform the answers into testable criteria:

**Bad criteria:**
- "App should work better"
- "Fix the bug"

**Good criteria:**
- "Bank balance updates within 5 seconds of workout sync"
- "Block screen displays current balance and difficulty level"
- "Notification fires when balance reaches 15 minutes"

Each criterion should be:
- **Specific**: Exactly what behavior is expected
- **Testable**: Can verify with a screenshot or test
- **Independent**: Can be checked separately

### Step 5: Determine Complexity
Based on the scope, estimate complexity:

| Complexity | Criteria |
|------------|----------|
| `trivial` | Single file, <10 lines, obvious fix |
| `standard` | Multiple files, clear requirements, 1-2 hours |
| `complex` | Architectural changes, ambiguous requirements, >2 hours |

### Step 6: Generate Ticket YAML

```yaml
id: 'XXX'  # Next available number
type: bug | feature | improvement | chore
title: Short, descriptive title (50 chars max)
priority: P0 | P1 | P2 | P3
complexity: trivial | standard | complex

description: |
  ## Summary
  One paragraph describing the issue or feature.

  ## Context
  Why this matters, who is affected.

  ## Technical Notes (if applicable)
  Any implementation hints or constraints.

acceptance_criteria:
- First testable criterion
- Second testable criterion
- Edge case criterion

# For bugs only:
steps_to_reproduce:
- Step 1
- Step 2
- Step 3

expected_behavior: What should happen
actual_behavior: What actually happens

status: pending
created: YYYY-MM-DD
```

### Step 7: Present for Approval
Show the generated ticket to the user:

```
Here's the ticket I've created:

---
[Show YAML]
---

Does this capture your intent? I can:
1. Save it as-is
2. Modify specific fields
3. Add more acceptance criteria
4. Start over
```

### Step 8: Save Ticket
Once approved:
1. Find next available ID: `ls tickets/*.yml | sort -V | tail -1`
2. Save to `tickets/XXX.yml`
3. Confirm save location

---

## Examples

### Bug Example
**User says:** "The bank balance doesn't update after I finish a workout"

**Generated ticket:**
```yaml
id: '004'
type: bug
title: Bank balance not updating after workout sync
priority: P1
complexity: standard

description: |
  ## Summary
  The bank balance remains unchanged after completing a workout and
  syncing with Apple Health, leaving users unable to earn screen time.

  ## Context
  This is a core mechanic failure. Users exercise expecting to earn
  minutes, but the balance doesn't reflect their effort.

acceptance_criteria:
- Bank balance increases within 30 seconds of workout appearing in HealthKit
- Notification fires confirming minutes earned
- Dashboard shows updated balance immediately
- WorkoutLog entry is created with correct minutes earned

steps_to_reproduce:
- Complete a workout (any type)
- Open Apple Health and verify workout logged
- Open LockedIn app
- Observe bank balance

expected_behavior: Bank balance increases by earned minutes
actual_behavior: Bank balance remains unchanged

status: pending
created: 2026-01-02
```

### Feature Example
**User says:** "Add a widget showing my remaining balance"

**After clarifying questions, generated ticket:**
```yaml
id: '005'
type: feature
title: Add home screen widget for bank balance
priority: P2
complexity: complex

description: |
  ## Summary
  Add a home screen widget that displays the current bank balance so
  users can check their remaining time without opening the app.

  ## Context
  Users want quick visibility into their balance. A widget reduces
  friction and keeps the bank balance top-of-mind.

  ## Technical Notes
  - Requires WidgetKit implementation
  - Need App Groups for data sharing between app and widget
  - Consider small, medium, and large widget sizes

acceptance_criteria:
- Small widget displays current balance in minutes
- Medium widget shows balance + difficulty level
- Widget updates within 1 minute of balance change
- Widget respects system dark/light mode
- Tapping widget opens main app

status: pending
created: 2026-01-02
```

---

## Priority Guide

| Priority | Meaning | Response Time |
|----------|---------|---------------|
| P0 | Critical - app unusable | Immediate |
| P1 | High - major feature broken | This sprint |
| P2 | Medium - annoying but workaround exists | Next sprint |
| P3 | Low - nice to have | Backlog |

---

## Tips for Good Tickets

1. **One issue per ticket** - Don't bundle multiple bugs/features
2. **User perspective** - Write criteria from user's point of view
3. **Avoid implementation details** - Focus on what, not how
4. **Include edge cases** - What happens at boundaries?
5. **Define "done"** - How do we know it's complete?
