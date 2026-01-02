# Reopen Ticket

Reopen a closed ticket for rework, typically after overnight work that needs correction.

## Purpose

Use this command when:
- Overnight work completed a ticket incorrectly
- A merged ticket has bugs discovered in morning review
- The implementation approach needs to be redone
- Additional requirements surfaced after closure

## Workflow

```
LISTEN → REOPEN → PROPOSAL → PLAN → DEVELOP → VERIFY → REVIEW → APPROVE
   ↓                            ↑                          ↑         ↑
(user describes              (gate)                     (gate)    (gate)
 what went wrong)
```

This follows the standard ticket workflow with user gates, plus an initial phase to understand what went wrong.

## Instructions

### Phase 0: Listen

1. **Read the ticket file** to understand original requirements

2. **Check git history** for the ticket's previous work:
   ```bash
   git log --oneline --grep="ticket-XXX" | head -5
   git show <commit> --stat
   ```

3. **Ask user what went wrong**:
   ```
   Ticket XXX was previously closed.

   Original requirements:
   - [list acceptance criteria]

   Previous implementation:
   - Commit: abc1234
   - Files changed: [list]

   What needs to be fixed or redone?
   ```

4. **Document the issue** - add to ticket file:
   ```yaml
   rework_reason: |
     [User's description of what went wrong]

   rework_date: YYYY-MM-DD
   ```

### Phase 1: Reopen

1. **Update ticket status**:
   ```yaml
   status: open  # Changed from closed
   ```

2. **Decide on approach**:
   - **Fix in place**: If minor correction, branch from main, fix the issue
   - **Revert and redo**: If fundamental approach was wrong:
     ```bash
     git revert <commit-hash> -m 1
     ```

3. **Create fresh branch**:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b ticket-XXX-rework
   ```

### Phases 2-6: Standard Ticket Workflow

Execute the standard gated workflow:
- **PROPOSAL**: Incorporate user feedback about what went wrong
- **PLAN**: Design corrected approach (gate - get approval)
- **DEVELOP**: Implement fix, ensuring original issue is addressed
- **VERIFY**: Extra attention to the specific failure case
- **REVIEW**: Gate - confirm fix addresses user's concerns
- **APPROVE**: Gate - final sign-off before merge

### On Completion

1. **Merge to main**:
   ```bash
   git checkout main
   git merge ticket-XXX-rework
   git push origin main
   ```

2. **Update ticket**:
   ```yaml
   status: closed
   rework_completed: YYYY-MM-DD
   ```

3. **Clean up**:
   ```bash
   git branch -d ticket-XXX-rework
   ```

## Arguments

- `$ARGUMENTS` - ticket ID to reopen (e.g., `006` or `tickets/006.yml`)

## Example Usage

```
/reopen-ticket 006

> Ticket 006 (Hard Block Screen) was closed.
> What needs to be fixed or redone?

User: The block screen doesn't show the current bank balance.
      Also the "Open Apple Health" button doesn't work.

> Understood. I'll reopen the ticket and address:
> 1. Display current bank balance on block screen
> 2. Fix Apple Health deep link
>
> Creating rework branch from main...
```

## Notes

- Always branch from current main (includes the original work)
- Use `-rework` suffix on branch name to distinguish from original
- Document what went wrong in the ticket for future reference
- The original commit remains in history (don't rewrite)
