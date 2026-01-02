# Start Ticket Workflow

Load the specified ticket and begin structured implementation with gated approvals.

## Workflow Phases

```
PROPOSAL → PLAN → DEVELOP → VERIFY → REVIEW → APPROVE
             ↑                          ↑         ↑
          (gate)                     (gate)    (gate)
```

**Gates require explicit user approval before proceeding.** Do NOT advance past a gate without user confirmation.

## Instructions

### Phase 0: Setup (CRITICAL)

**Always start from a clean, up-to-date main branch:**
```bash
git status                    # Must be clean
git checkout main             # Switch to main
git pull origin main          # Get latest changes
git checkout -b ticket-XXX    # Create feature branch
```

If working directory is dirty, stash or commit changes first. **Never start a ticket on a stale branch.**

### Phase 1: Read Ticket

1. **Read the ticket** from the path provided (default: look in `tickets/` directory)

2. **Classify complexity**:
   - `trivial`: Single-file, obvious fix (typos, config) → Skip PLAN, go to DEVELOP
   - `standard`: Multi-file, clear requirements → Full workflow
   - `complex`: Architectural changes, ambiguous requirements → Extra planning

3. **Update ticket status**:
   ```yaml
   status: in_progress
   ```

4. **Initialize state** in SCRATCHPAD.md:
   ```markdown
   ## Current Ticket: [ID]
   ### Phase: PROPOSAL (1/6)
   ### Complexity: [trivial|standard|complex]
   ### Acceptance Criteria:
   - [ ] Criterion 1
   - [ ] Criterion 2
   ```

5. **Create todo list** with explicit phases

6. **Execute phases with gates**:

### Phase 1: PROPOSAL
- Summarize requirements and understanding
- Ask clarifying questions if needed
- Auto-advance to PLAN (or DEVELOP for trivial)

### Phase 2: PLAN (gate)
- Investigate codebase, identify files to change
- Write implementation plan
- **STOP and ask user: "Plan complete. Ready to implement?"**
- Do NOT write code until user approves

### Phase 3: DEVELOP
- Implement changes according to approved plan
- Build and fix any compilation errors
- Auto-advance to VERIFY

### Phase 4: VERIFY
- Run tests, take screenshots as evidence
- Verify acceptance criteria are met
- Auto-advance to REVIEW

### Phase 5: REVIEW (gate)
- Spawn code-reviewer agent for independent review
- Address any issues found
- **STOP and ask user: "Code review complete. Ready to commit and merge?"**
- Do NOT commit until user approves

### Phase 6: APPROVE (gate)
- Present summary of changes
- **Wait for user sign-off**
- Only then: mark ticket closed, commit, and push

## Arguments
- `$ARGUMENTS` - ticket path or ID (e.g., `tickets/002.yml` or just `002`)

## Example Usage
```
/ticket 003
/ticket tickets/feature-xyz.yml
```

## Critical Rules
- **Never skip gates** - always wait for explicit user approval
- **Never commit without approval** - even if code review passes
- **Never merge without approval** - user must confirm before push
