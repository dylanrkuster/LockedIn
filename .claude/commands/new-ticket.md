# Create New Ticket

Takes an informal bug report or feature description and creates a structured ticket for the workflow.

## Instructions

1. **Listen to the user's description** - they may describe a bug, feature, or improvement informally

2. **Load the ticket-creation skill** for structured guidance

3. **Ask clarifying questions** to fill gaps:
   - What's the expected behavior?
   - What's the actual behavior? (for bugs)
   - Who is affected?
   - Are there edge cases to consider?
   - What does "done" look like?

4. **Generate the ticket** in proper YAML format

5. **Get user approval** before saving

6. **Save to `tickets/XXX.yml`** with next available ID

## Arguments
- `$ARGUMENTS` - Initial description of the bug or feature (optional, can be provided interactively)

## Example Usage
```
/new-ticket The bank balance doesn't update after a workout syncs

/new-ticket Add the ability to customize notification messages

/new-ticket
(then describe interactively)
```
