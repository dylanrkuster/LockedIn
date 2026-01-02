# Ticket Workflow Skill

## Description
Structured workflow for implementing tickets with clear phase separation and quality gates.

## Triggers
- User mentions "ticket", "implement", "fix bug", "add feature"
- User references a ticket file (e.g., `tickets/XXX.yml`)
- User says "start workflow" or "/ticket"

## Phases

### Phase 1: PROPOSAL (Auto-advance)
**Goal:** Understand and clarify requirements

1. Read the ticket file completely
2. Identify acceptance criteria
3. Ask clarifying questions if requirements are ambiguous
4. Classify complexity: `trivial` | `standard` | `complex`

**Trivial tickets** (typos, config changes, single-line fixes):
- Skip to DEVELOP immediately
- No planning needed

**Output:** Updated understanding in SCRATCHPAD.md

---

### Phase 2: PLAN (User Gate)
**Goal:** Design implementation approach before writing code

1. Use `/plan` or explicit planning mode
2. Explore codebase to find relevant files
3. Identify patterns and integration points
4. Document approach in `plans/ticket-XXX.md`:
   - Files to modify
   - New files to create
   - Test strategy
   - Edge cases to handle
5. **STOP and ask user approval** before proceeding

**Output:** Plan file ready for user review

---

### Phase 3: DEVELOP (Auto-advance, test-gated)
**Goal:** Implement the approved plan

**Note:** Feature branch should already exist from Phase 0 setup. If not:
```bash
git checkout main && git pull origin main
git checkout -b ticket-XXX
```

1. Implement changes following the plan
3. Write unit tests covering:
   - Happy path
   - Edge cases from ticket
   - Regression tests if fixing a bug
4. Run build: `xcodebuild build -scheme LockedIn -project LockedIn/LockedIn.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2'`
5. **Run tests and VERIFY they pass:**
   ```bash
   xcodebuild test -scheme LockedIn -project LockedIn/LockedIn.xcodeproj \
     -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2'
   ```
   **BLOCKING:** Do NOT advance to VERIFY if tests fail. Fix failing tests first.
6. Commit with proper message

**Output:** Working code on feature branch with passing tests

---

### Phase 4: VERIFY (Auto-advance)
**Goal:** QA verification with evidence

1. Boot simulator if needed
2. Build and install app
3. Take screenshots proving feature works:
   - `qa/screenshots/ticket-XXX/` directory
4. Test persistence (if data feature)
5. Verify all acceptance criteria with evidence
6. Document verification in `qa/reports/ticket-XXX.md`

**Output:** Screenshots and verification report

---

### Phase 5: REVIEW (External Tool)
**Goal:** Independent code review

1. Generate diff summary
2. **Spawn Codex or external review agent**:
   ```
   Use Task tool with subagent_type="general-purpose"
   Prompt: "Review this diff for bugs, security issues, and code quality..."
   ```
3. Address any P1/P2 issues found
4. Re-run verification if changes made

**Output:** Review complete, issues addressed

---

### Phase 6: APPROVE (User Gate)
**Goal:** Final approval and merge

1. Present summary:
   - What was implemented
   - Test results
   - Screenshots taken
   - Review findings
2. **STOP and ask user for final approval**
3. On approval: merge to main, close ticket

**Output:** Ticket completed

---

## State Management

Use SCRATCHPAD.md to track:
```markdown
## Current Ticket: XXX

### Phase: DEVELOP (3/6)

### Key Decisions:
- Using BankManager pattern for balance updates
- Edge case handling: cap at max balance

### Files Modified:
- BankManager.swift
- HealthKitService.swift

### Blockers:
- None
```

## Automatic Optimizations (DO WITHOUT ASKING USER)

### 1. Parallel Exploration (PLAN phase)
Launch 3-5 Explore sub-agents simultaneously:
```
Task 1 (haiku): "Find files related to [feature area]"
Task 2 (haiku): "Search for similar patterns in codebase"
Task 3 (haiku): "Find tests for related functionality"
Task 4 (haiku): "Check for configuration or constants"
```
Don't wait for each - launch all at once, collect results.

### 2. Background Operations
Run long operations in background, continue other work:
```
Start build → document changes while building
Start tests → prepare verification report while testing
```

### 3. Model Selection (automatic)
| Task | Model | Reason |
|------|-------|--------|
| File search | Haiku | Fast, cheap |
| Implementation | Sonnet | Balanced |
| Code review | Sonnet | Thorough |
| Complex decisions | Opus + ultrathink | Max reasoning |

### 4. Context Management (at phase boundaries)
End of each phase:
1. Mentally check context usage
2. If >50%, update SCRATCHPAD.md
3. Suggest `/compact` if approaching 60%
4. After compact, re-read SCRATCHPAD.md

### 5. Todo Recitation
- Update todo list continuously
- Mark complete IMMEDIATELY when done
- Keeps objectives in attention

### 6. Pre-flight Checklist (before DEVELOP)
Verify silently:
- [ ] Understand ALL acceptance criteria
- [ ] Know which files to modify
- [ ] Know what tests to write
- [ ] Identified edge cases

### 7. Post-flight Checklist (before APPROVE)
Verify silently:
- [ ] All criteria have evidence
- [ ] Tests actually pass (verified via xcodebuild output showing "TEST SUCCEEDED")
- [ ] Screenshots taken for UI changes
- [ ] Code review done, P1/P2 fixed
- [ ] No debug code left behind

### 8. Test Failure Protocol
If tests fail during DEVELOP:
1. **DO NOT advance to VERIFY** - tests are a hard gate
2. Read the test failure output carefully
3. Fix the failing test or the code causing failure
4. Re-run full test suite
5. Only proceed when output shows "TEST SUCCEEDED"
6. Document any test fixes in commit message

**Iteration limits:**
- Interactive mode (`/ticket`, `/next-ticket`): 3 attempts, then escalate to user
- Autonomous mode (`/work-while-i-sleep`): 7 attempts, then mark FAILED and continue

**Document each attempt** when in autonomous mode:
```markdown
## Attempt 1
- Error: [error message]
- Hypothesis: [what might be wrong]
- Fix tried: [what was attempted]
- Result: [still failing / different error / success]
```

## Error Handling

If any phase fails:
1. Load the **debugging skill** for systematic diagnosis
2. Document failure in SCRATCHPAD.md
3. Follow the debugging framework:
   - Capture error → Classify → Isolate → Hypothesize → Fix → Verify
4. Do NOT advance to next phase until resolved

**Escalation policy:**
- Interactive mode: After 3 failed attempts, escalate to user with full context
- Autonomous mode: After 7 failed attempts, mark ticket FAILED, document thoroughly, continue to next ticket

## Branch Discipline

**CRITICAL:** Always start ticket work from a fresh, up-to-date main branch.

```bash
# Before starting ANY ticket
git status                    # Must be clean
git checkout main             # Switch to main
git pull origin main          # Get latest
git checkout -b ticket-XXX    # Create feature branch
```

**Why this matters:**
- Prevents merge conflicts with recently completed work
- Ensures you're building on the latest codebase
- Each ticket gets an isolated branch for clean history

**After ticket completion:**
```bash
git checkout main
git merge ticket-XXX
git push origin main
git branch -d ticket-XXX      # Clean up
```
