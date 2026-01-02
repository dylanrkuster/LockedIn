# Work While I Sleep

Process up to 5 open tickets overnight with fully autonomous execution. Creates a morning report for verification.

## Overview

This command runs the standard ticket workflow on multiple tickets without user gates. Each ticket is implemented, tested, reviewed, and merged automatically. A comprehensive morning report documents all work for your review.

## Workflow

```
PREPARATION → [FOR EACH TICKET] → MORNING REPORT
                    │
                    ▼
    PROPOSAL → PLAN → DEVELOP → VERIFY → REVIEW → MERGE
       ↓         ↓        ↓         ↓        ↓        ↓
    (auto)    (auto)   (test-    (auto)  (auto-   (auto)
                       gated)            fix P1s)
```

**No user gates.** All phases auto-advance. Tests must pass. Merges to main after each ticket.

## Instructions

### Phase 1: Preparation

1. **Verify clean state**:
   ```bash
   git status  # Must be clean
   git checkout main
   git pull origin main
   ```
   If working directory is dirty, STOP and inform user.

2. **Find open tickets**:
   - Scan `tickets/*.yml` in numeric ID order
   - Collect tickets with `status: open`
   - Limit to first 5 tickets

3. **Create overnight directory**:
   ```bash
   mkdir -p overnight/$(date +%Y-%m-%d)
   ```

4. **Present work plan and get single approval**:
   ```
   ## Overnight Work Plan

   I will process these tickets in order:

   1. Ticket 006: Implement hard block screen (feature, P1)
   2. Ticket 007: Fix HealthKit sync delay (bug, P2)
   3. Ticket 008: Add difficulty mode selector (feature, P2)

   Each ticket will be:
   - Implemented on a fresh branch from main
   - Tested (must pass to proceed)
   - QA verified with screenshots
   - Code reviewed (P1 issues auto-fixed)
   - Merged to main
   - Documented in morning report

   Approve to begin? (This is the only approval needed)
   ```

5. **On approval, begin autonomous execution**

### Phase 2: Per-Ticket Execution

For each ticket, execute autonomously:

1. **Branch from fresh main**:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b ticket-XXX
   ```

2. **PROPOSAL**: Read ticket, understand requirements (auto-advance)

3. **PLAN**:
   - Explore codebase, design approach
   - Save plan to `plans/ticket-XXX.md`
   - Auto-advance (no user gate)

4. **DEVELOP**:
   - Implement changes following plan
   - Write/update unit tests
   - Build and test (up to 7 attempts if failures)
   - **BLOCKING**: Do NOT proceed if tests fail after 7 attempts
   - Document each attempt in `overnight/YYYY-MM-DD/ticket-XXX/attempts.md`

5. **VERIFY**:
   - Take screenshots proving feature works
   - Save to `qa/screenshots/ticket-XXX/`
   - Generate QA report

6. **REVIEW**:
   - Spawn code-reviewer agent
   - Auto-fix P1 and P2 issues if possible
   - Document all findings
   - If P1 cannot be fixed, mark ticket as NEEDS_ATTENTION but continue

7. **MERGE** (replaces APPROVE gate):
   ```bash
   git checkout main
   git merge ticket-XXX
   git push origin main
   git branch -d ticket-XXX
   ```
   - Update ticket status to `closed`
   - Log success in morning report

8. **On failure at any step**:
   - Document failure reason and attempts
   - Leave branch intact for inspection
   - Mark ticket as FAILED in morning report
   - **Continue to next ticket** (do not stop)

### Phase 3: Morning Report

After all tickets processed, generate `overnight/YYYY-MM-DD/report.md`:

```markdown
# Overnight Work Report - YYYY-MM-DD

## Summary
| Metric | Count |
|--------|-------|
| Tickets Attempted | 5 |
| Completed & Merged | 4 |
| Failed | 1 |

## Completed Tickets

### Ticket 006: Implement hard block screen
- **Commit:** abc1234
- **Tests:** 48 passed, 0 failed
- **Code Review:** APPROVED (2 P3 suggestions)
- **Evidence:** overnight/YYYY-MM-DD/ticket-006/
- **Changes:**
  - Added BlockScreenView with lock icon
  - Integrated with ManagedSettings
  - Added 3 new unit tests

### Ticket 007: Fix HealthKit sync delay
...

## Failed Tickets

### Ticket 009: Add widget support
- **Branch:** ticket-009 (not merged, inspect manually)
- **Failed At:** DEVELOP phase
- **Attempts:** 7
- **Last Error:** WidgetKit requires app group configuration
- **Recommendation:** Consider `/reopen-ticket 009` with app group setup guidance

## Evidence Locations
- Plans: plans/ticket-XXX.md
- Screenshots: qa/screenshots/ticket-XXX/
- QA Reports: qa/reports/ticket-XXX.md
- Attempt Logs: overnight/YYYY-MM-DD/ticket-XXX/

## Your Review Checklist
For each completed ticket, verify:
- [ ] Implementation matches requirements
- [ ] Screenshots show expected behavior
- [ ] Code quality acceptable
- [ ] No unintended side effects

## Rollback Instructions
If any ticket needs reverting:
git revert <commit-hash> -m 1
```

## Limits & Safety

- **Maximum 5 tickets** per overnight run
- **7 attempts max** per ticket before marking failed
- **Never force push** or rewrite history
- **Always merge to main** (no dangling branches for completed work)
- **Full test suite must pass** before any merge

## Example Usage

```
/work-while-i-sleep
```

## Related Commands

- `/ticket [id]` - Work on single ticket with user gates
- `/next-ticket` - Work on next open ticket with user gates
- `/reopen-ticket [id]` - Reopen and redo failed overnight work
