# Scratchpad - Persistent State

This file tracks current work state across context resets.

## Current Ticket
001 - Build Main Dashboard screen

## Phase
REVIEW (5/6) - GATE

## Complexity
standard

## Acceptance Criteria
- [ ] Large, prominent balance display showing minutes remaining (e.g., "47:32")
- [ ] "minutes left" label below the balance
- [ ] Progress bar showing balance relative to max (based on difficulty)
- [ ] Current difficulty mode displayed (e.g., "Difficulty: HARD")
- [ ] Blocked Apps section showing count and app names
- [ ] Settings gear icon in navigation bar
- [ ] Works with hardcoded/mock data initially
- [ ] Matches brand voice (direct, minimal, no fluff)

## Key Decisions
- (none yet)

## Affected Areas
- LockedIn/LockedIn/ (main app source)

## Files Modified
- LockedInApp.swift (updated)
- CLAUDE.md (updated OS version)
- Models/Difficulty.swift (new)
- Models/BankState.swift (new)
- Views/DashboardView.swift (new)
- Views/Components/BalanceDisplay.swift (new)
- Views/Components/ProgressBar.swift (new)
- Views/Components/BlockedAppsSection.swift (new)
- Item.swift (deleted)
- ContentView.swift (deleted)

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
