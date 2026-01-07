# Ticket 023: Spent Minus Prefix - QA Verification

## Implementation Summary
Added "-" prefix to spent amounts in two locations for visual consistency.

### Changes Made
1. **TodaySummary.swift** line 60: Added "-" prefix to spent amount
2. **ActivityHistoryView.swift** line 166: Added "-" prefix to spent amount

### Visual Result
- Dashboard TODAY section: "EARNED +45  SPENT -32  NET +13"
- Activity History day headers: "EARNED +45  SPENT -32  NET +13"

### Acceptance Criteria Verification
| Criteria | Status |
|----------|--------|
| Dashboard "TODAY" summary shows spent with "-" prefix | PASS |
| ActivityHistoryView day headers show spent with "-" prefix | PASS |
| Earned amounts retain "+" prefix | PASS (unchanged) |
| Net amounts retain "+" or "-" as appropriate | PASS (unchanged) |

### Build & Test Results
- Build: **SUCCEEDED**
- Tests: **86+ tests PASSED**

### Code Quality
- Trivial 2-character change in each file
- No logic changes, pure display formatting
- No new code paths introduced
