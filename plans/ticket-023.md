# Ticket 023: Add Minus Prefix to Spent Amounts

## Overview
Trivial visual consistency fix. Add "-" prefix to spent amounts in day summaries.

## Changes

### Files Modified
1. `LockedIn/LockedIn/Views/Components/TodaySummary.swift` (line 60)
   - Changed: `Text("\(todayStats.spent)")` → `Text("-\(todayStats.spent)")`

2. `LockedIn/LockedIn/Views/ActivityHistoryView.swift` (line 166)
   - Changed: `Text("\(group.spent)")` → `Text("-\(group.spent)")`

## Result
- Before: "EARNED +45  SPENT 32  NET +13"
- After: "EARNED +45  SPENT -32  NET +13"
