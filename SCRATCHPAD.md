# Scratchpad - Persistent State

This file tracks current work state across context resets.

## Current Ticket
004 - Activity Tracking and Balance System (Core Loop)

## Phase
APPROVE (6/6) - GATE

## Complexity
complex

## Acceptance Criteria

### Earning
- [ ] Completing a workout in Apple Health adds earned minutes to balance
- [ ] Earned minutes respect difficulty ratio (Hard 2:1 = 30min workout → +15)
- [ ] Balance cannot exceed difficulty cap (excess forfeited)
- [ ] Same workout synced twice is only counted once
- [ ] Workout transaction shows workout type name, not generic "Workout"
- [ ] Balance updates without manual refresh (background observer)

### Spending
- [ ] Using a blocked app decrements balance in real-time
- [ ] Each blocked app creates its own transaction with app name
- [ ] Spending is 1:1 (10 min on TikTok = -10 from balance)
- [ ] Balance stops at 0 (no negative balance)
- [ ] Shield activates immediately when balance hits 0

### Activity Display
- [ ] Activity section shows real transactions, not mock data
- [ ] Shows 8 most recent transactions
- [ ] Sorted by timestamp, most recent first
- [ ] Transactions older than 7 days are not shown

### Persistence
- [ ] Balance persists across app launches
- [ ] Transactions persist across app launches
- [ ] Workouts are not double-counted after app restart

### Authorization
- [ ] HealthKit permission requested appropriately
- [ ] App functions (spend-only) if HealthKit denied

## Key Formulas

**Earning:**
```
earned_minutes = floor(workout_duration_minutes × difficulty_multiplier)
```

| Difficulty | Multiplier | Max Balance |
|------------|------------|-------------|
| Easy       | 2.0        | 240 min     |
| Medium     | 1.0        | 180 min     |
| Hard       | 0.5        | 120 min     |
| Extreme    | 0.33       | 60 min      |

**Spending:**
```
spent_minutes = actual_minutes_in_blocked_app (1:1, always)
```

## Workout Type Display Names
- Running → "Run"
- Walking → "Walk"
- Cycling → "Cycling"
- Functional/Traditional Strength Training → "Strength"
- High Intensity Interval Training → "HIIT"
- Yoga → "Yoga"
- Swimming → "Swim"
- All others → "Workout"

## Key Decisions
- (none yet)

## Affected Areas
- (to be determined in PLAN phase)

## Files Modified
- (to be determined in PLAN phase)

## Blockers
None

---

## Phase Checklist Template

### PROPOSAL
- [ ] Read ticket
- [ ] Classify complexity
- [ ] Identify acceptance criteria
- [ ] Ask clarifying questions (if needed)

### PLAN
- [ ] Explore codebase
- [ ] Identify files to modify
- [ ] Document approach in plans/ticket-XXX.md
- [ ] **Get user approval**

### DEVELOP
- [ ] Create feature branch
- [ ] Implement changes
- [ ] Write tests
- [ ] Build passes
- [ ] Tests pass
- [ ] Commit with proper message

### VERIFY
- [ ] Boot simulator
- [ ] Install and launch app
- [ ] Screenshot each acceptance criterion
- [ ] Test persistence
- [ ] Document in qa/reports/ticket-XXX.md

### REVIEW
- [ ] Spawn code-reviewer agent
- [ ] Address P1/P2 issues
- [ ] Re-verify if changes made

### APPROVE
- [ ] Present summary
- [ ] **Get user approval**
- [ ] Merge to main
- [ ] Update ticket status
