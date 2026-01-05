# LockedIn Analytics

## Overview

LockedIn uses Firebase Analytics to understand user behavior and improve the product. We track meaningful events that answer key product questions—not vanity metrics.

### Privacy Stance

**What we DON'T collect:**
- Specific app names (only counts)
- Actual usage duration per app
- Personally identifiable information (PII)
- Advertising identifiers (IDFA)
- Location data
- Health data specifics (only workout type and duration)

**What we DO collect:**
- Anonymous event data (no user accounts)
- Aggregate patterns (difficulty choices, balance states)
- Feature engagement metrics

### Firebase Console

Access analytics at: https://console.firebase.google.com

---

## Event Reference

### Onboarding Funnel

Track where users drop off during first-time setup.

| Event | When It Fires | Parameters | Why It Matters |
|-------|---------------|------------|----------------|
| `onboarding_started` | User taps "GET STARTED" on welcome screen | None | Baseline for funnel |
| `onboarding_apps_selected` | User continues after selecting blocked apps | `app_count` | Did they engage with picker? |
| `onboarding_difficulty_selected` | User continues after choosing difficulty | `difficulty` | What commitment level do users choose? |
| `onboarding_permissions_granted` | User continues after permissions screen | `screen_time_granted`, `health_granted`, `notifications_granted` | Where is permission friction? |
| `onboarding_completed` | User finishes onboarding | `difficulty`, `app_count` | Conversion rate |

### Core Loop Events

Track the earn-spend-block mechanic health.

| Event | When It Fires | Parameters | Why It Matters |
|-------|---------------|------------|----------------|
| `workout_synced` | Workout credited to balance | `minutes_earned`, `workout_type`, `balance_after` | Is earn side working? |
| `balance_depleted` | Balance hits zero | `difficulty`, `days_since_install` | How often do users hit the wall? |
| `balance_recovered` | Balance goes from 0 to positive | `minutes_to_recover` | Do they workout to unlock or churn? |
| `shield_displayed` | Block screen shown | `display_count` | How many times does blocking engage? |

### Engagement Events

Track feature usage and settings changes.

| Event | When It Fires | Parameters | Why It Matters |
|-------|---------------|------------|----------------|
| `app_foregrounded` | App returns from background | `balance`, `difficulty` | Daily active engagement |
| `difficulty_changed` | User changes difficulty level | `from_difficulty`, `to_difficulty`, `balance_lost` | Sign of friction or commitment |
| `blocked_apps_modified` | User edits blocked apps | `app_count`, `category_count` | Are they adding or removing? |
| `activity_history_viewed` | User taps "SEE ALL" on activity | None | Feature engagement |
| `settings_opened` | User taps settings gear | None | Feature engagement |

### Milestone Events

Track significant user achievements.

| Event | When It Fires | Parameters | Why It Matters |
|-------|---------------|------------|----------------|
| `first_workout_synced` | First ever workout credited | `minutes_earned` | Activation metric |
| `first_block_hit` | First time balance hits zero | `days_since_install` | First "moment of truth" |
| `review_prompt_shown` | App Store review prompt displayed | `workout_count` | Review prompt timing |

---

## User Properties

Set once and updated on change. Used for segmentation.

| Property | When Set | Purpose |
|----------|----------|---------|
| `difficulty` | On onboarding completion and difficulty change | Segment by commitment level |
| `blocked_app_count` | On onboarding completion and app selection change | Segment by restriction scope |

---

## Key Metrics & Insights

### Onboarding Conversion

```
Funnel: started → apps_selected → difficulty_selected → permissions → completed

Example data:
  started:              1000
  apps_selected:         850 (85%)
  difficulty_selected:   820 (96%)
  permissions_granted:   600 (73%)
  completed:             580 (97%)

Insight: 27% drop at permissions step. Investigate friction:
- Are users confused about why we need Screen Time?
- Is the permission copy clear enough?
- Consider better explanation before requesting
```

### Difficulty Distribution

```
Example distribution:
  EASY:     15%
  MEDIUM:   45%
  HARD:     30%
  EXTREME:  10%

Insights:
- Most users pick MEDIUM (the default). Consider if HARD should be default.
- 10% choosing EXTREME suggests strong demand for challenge.
- Monitor difficulty_changed events from EXTREME/HARD → EASY for churn signals.
```

### Core Loop Health

```
Key metrics to track:

  balance_depleted events per user per week:  2.3
  balance_recovered within 24h:               78%
  balance_recovered within 48h:               89%

Insights:
- Users hit zero ~2x per week on average. This is healthy—the mechanic is engaging.
- 78% recover within 24h by working out. These are successful users.
- 11% take 24-48h. These may need encouragement.
- 11% don't recover within 48h. High churn risk—consider intervention.
```

### Difficulty Downgrade Analysis

```
Example: Users who changed from HARD → EASY in week 1

  12% of HARD users downgraded in first week

Insights:
- Some users overcommit initially.
- Consider onboarding copy: "Start at MEDIUM, increase later"
- Or: show projected daily workout requirement before confirming difficulty
```

### Feature Engagement

```
Daily active user breakdown:

  activity_history_viewed:  34% of DAU
  settings_opened:          18% of DAU
  difficulty_changed:        2% of DAU

Insights:
- History is useful—34% check their transaction log regularly
- Settings rarely touched (good—simple app)
- Low difficulty changes = users are committed to their choice
```

### Shield Effectiveness

```
shield_displayed per blocked session analysis:

  Average shields shown before app switch:  1.2
  Users who immediately close blocked app:  67%
  Users who tap "GET ACTIVE":               28%
  Users who retry multiple times:            5%

Insights:
- Shield is effective—67% immediately leave
- 28% engage with CTA (potential workout trigger)
- 5% frustrated users may need different messaging
```

---

## Dashboard Recommendations

Create these dashboards in Firebase Console:

### 1. Onboarding Funnel
- Funnel visualization: started → completed
- Conversion rate by step
- Drop-off analysis

### 2. Daily Active Users
- DAU by difficulty
- DAU trend over time
- Session frequency

### 3. Core Loop Health
- workout_synced events per day
- balance_depleted events per day
- Recovery rate (balance_recovered / balance_depleted)

### 4. Retention Cohorts
- Day 1, Day 7, Day 30 retention
- Segment by difficulty
- Segment by initial app_count

### 5. Feature Usage
- Weekly active users per feature
- Settings engagement
- Activity history views

---

## Testing Analytics

### Enable Debug Mode

Add launch argument in Xcode scheme:
```
-FIRAnalyticsDebugEnabled
```

This enables real-time event viewing in Firebase DebugView.

### Verify Events

1. Run app with debug mode enabled
2. Open Firebase Console → DebugView
3. Perform actions and verify events appear
4. Check parameter values are correct

### Event Checklist

- [ ] `onboarding_started` fires on "GET STARTED" tap
- [ ] `onboarding_apps_selected` includes correct `app_count`
- [ ] `onboarding_difficulty_selected` includes correct `difficulty`
- [ ] `onboarding_permissions_granted` reflects actual permission state
- [ ] `onboarding_completed` fires with correct `difficulty` and `app_count`
- [ ] `workout_synced` fires when workout is credited
- [ ] `balance_depleted` fires when balance hits 0
- [ ] `balance_recovered` fires when going from 0 to positive
- [ ] `shield_displayed` fires when shield is shown (via extension counter)
- [ ] `app_foregrounded` fires on each foreground
- [ ] `difficulty_changed` fires with correct from/to values
- [ ] `blocked_apps_modified` fires when selection changes
- [ ] `activity_history_viewed` fires on "SEE ALL" tap
- [ ] `settings_opened` fires on gear icon tap
- [ ] `first_workout_synced` fires only once ever
- [ ] `first_block_hit` fires only once ever
- [ ] `review_prompt_shown` fires when prompt is displayed
