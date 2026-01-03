# LockedIn - MVP Vision Document

> **Last Updated:** January 2, 2026
> **Status:** Draft v1.0

---

## 0. Naming Decision

**Official Name:** LockedIn (one word, camel case)

**Rationale:** "Locked in" is peak Gen Z slang (American Dialect Society top term, "The Great Lock In of 2025" viral trend). Despite existing competitors using variations of this name (Locked-In, Lock In, LockedIn), they are weak products with small user bases. Our fitness-for-screen-time mechanic is a genuine differentiator. We win on execution, not name novelty.

**Differentiation Strategy:**
- Subtitle emphasizes fitness angle: "Earn Screen Time"
- Aggressive App Store keyword optimization around "workout," "earn," "fitness"
- Brand voice and UX quality will separate us from low-effort competitors

---

## 1. Product Philosophy

### Core Tenets

| Tenet | Meaning |
|-------|---------|
| **Simplicity** | Download → Select apps → Start. No tutorials, no lengthy onboarding, no account creation. |
| **No Bullshit** | Hard blocks. No "just 5 more minutes." No mercy mode. You run out, you're done. |
| **Earn Your Scroll** | Screen time is a reward, not an entitlement. You want to rot your brain? Earn it. |
| **Difficulty as Identity** | Your chosen difficulty level reflects your commitment. Wear it as a badge. |

### The One-Liner

**"Earn your screen time. One workout at a time."**

---

## 2. Target User

### Primary Persona: "Recovering Scroller"

- **Age:** 18-35 (Millennial / Gen Z)
- **Mindset:** Self-aware about phone addiction, wants to change but lacks discipline
- **Fitness Level:** Ranges from "aspiring" to "consistent gym-goer"
- **Motivation:** Guilt about wasted time, desire for self-improvement
- **Tech Savvy:** Comfortable with apps, owns iPhone, likely has Apple Watch (but not required)

### Secondary Persona: "Disciplined Optimizer"

- Already fitness-focused
- Wants to eliminate remaining "brain rot" time
- Sees this as another tool in their self-optimization stack
- Will choose Hard/Extreme modes

### Who This Is NOT For

- Parents controlling kids' devices (use Screen Time or Opal)
- People who need gentle nudges (use One Sec or ScreenZen)
- Android users (iOS only for MVP)
- People unwilling to exercise

---

## 3. Core Mechanics

### 3.1 The Bank

Users have a **"bank"** of screen time minutes for blocked apps.

| Parameter | Default | Configurable? |
|-----------|---------|---------------|
| Starting Balance | 60 minutes | No |
| Maximum Balance (Cap) | Varies by difficulty | Via difficulty mode |
| Minimum Balance | 0 minutes | No |

**Bank Behavior:**
- Balance decrements in real-time while using blocked apps
- Balance increments after workouts sync from Apple Health
- Balance cannot go negative—at 0, hard block activates
- Balance cannot exceed cap—excess earned minutes are forfeited

### 3.2 Earning Minutes

Minutes are earned by completing workouts tracked via Apple Health.

**Conversion Rates by Difficulty:**

| Difficulty | Workout : Screen Time | Example |
|------------|----------------------|---------|
| **Easy** | 1 : 2 | 30 min workout = 60 min screen time |
| **Medium** | 1 : 1 | 30 min workout = 30 min screen time |
| **Hard** | 2 : 1 | 60 min workout = 30 min screen time |
| **Extreme** | 3 : 1 | 90 min workout = 30 min screen time |

**Bank Caps by Difficulty:**

| Difficulty | Maximum Bank |
|------------|--------------|
| **Easy** | 240 minutes (4 hours) |
| **Medium** | 180 minutes (3 hours) |
| **Hard** | 120 minutes (2 hours) |
| **Extreme** | 60 minutes (1 hour) |

**What Counts as a Workout:**
- ANY workout type logged to Apple Health
- Running, walking, cycling, strength training, HIIT, yoga, swimming, etc.
- Manual entries ARE accepted (trust-based system)
- No heart rate requirement (supports non-Apple Watch users)

### 3.3 Spending Minutes

When a user opens a blocked app:
1. App opens normally
2. Bank balance decrements every minute (rounded up)
3. When balance hits 0 → immediate hard block

### 3.4 The Hard Block

When balance = 0:
- Blocked apps display a full-screen block overlay
- No snooze, no "5 more minutes," no override
- Only escape: complete a workout and sync it

**Block Screen Content:**
```
┌─────────────────────────────────┐
│                                 │
│       🔒 YOU'RE LOCKED OUT      │
│                                 │
│    You're out of time.          │
│    Earn more by working out.    │
│                                 │
│    ┌─────────────────────┐      │
│    │   Open Apple Health  │      │
│    └─────────────────────┘      │
│                                 │
│    Current Bank: 0 min          │
│    Difficulty: HARD             │
│                                 │
└─────────────────────────────────┘
```

---

## 4. User Experience

### 4.1 Onboarding Flow (< 60 seconds)

**Screen 1: Welcome**
```
LOCKEDIN

Earn your screen time.
One workout at a time.

[Get Started]
```

**Screen 2: Select Your Poison**
```
Which apps rot your brain?

[✓] Instagram
[✓] TikTok
[✓] Snapchat
[✓] X (Twitter)
[✓] Facebook
[ ] YouTube
[ ] Reddit
[ ] Other... (add custom)

Popular picks pre-selected. Tap to toggle.

[Continue]
```

**Screen 3: Choose Your Difficulty**
```
How locked in are you?

┌─────────────────────────────────┐
│ EASY                            │
│ 1 workout min = 2 screen min    │
│ 240 min max bank                │
│ "I'm just getting started"      │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ MEDIUM (Recommended)            │
│ 1 workout min = 1 screen min    │
│ 180 min max bank                │
│ "Fair trade"                    │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ HARD                            │
│ 2 workout min = 1 screen min    │
│ 120 min max bank                │
│ "I'm serious about this"        │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ EXTREME                         │
│ 3 workout min = 1 screen min    │
│ 60 min max bank                 │
│ "No excuses. No mercy."         │
└─────────────────────────────────┘
```

**Screen 4: Permissions**
```
Two quick permissions:

1. Screen Time Access
   Required to block apps
   [Grant Access]

2. Apple Health Access
   Required to track workouts
   [Grant Access]

[Complete Setup]
```

**Screen 5: You're Live**
```
You're locked in.

Starting Bank: 60 min
Difficulty: HARD
Apps Blocked: 4

Your bank is ticking. Go earn more.

[Let's Go]
```

### 4.2 Main Dashboard

Minimal. One screen. No tabs.

```
┌─────────────────────────────────┐
│ LOCKEDIN               ⚙️       │
├─────────────────────────────────┤
│                                 │
│            47:32                │
│         minutes left            │
│                                 │
│     ████████████░░░░░░░░        │
│         47 / 120 min            │
│                                 │
│      Difficulty: HARD           │
│                                 │
├─────────────────────────────────┤
│                                 │
│  Blocked Apps (4)          ▼    │
│  Instagram, TikTok, X, Snap     │
│                                 │
└─────────────────────────────────┘
```

### 4.3 Settings Screen

Accessible via gear icon. Minimal options.

```
SETTINGS

Difficulty
└─ [HARD ▼] (changeable anytime)

Blocked Apps
└─ [Manage List →]

Notifications
└─ [On ▼]
   • Notify at 15 min remaining
   • Notify at 5 min remaining
   • Notify when workout syncs

Data
└─ [Export History →]
└─ [Reset Everything →]

About
└─ Version 1.0.0
└─ [Send Feedback →]
```

---

## 5. Notifications

| Trigger | Message |
|---------|---------|
| 15 min remaining | "15 minutes left in the bank. Time to earn more?" |
| 5 min remaining | "5 minutes. The block is coming." |
| 0 min (blocked) | "You're locked out. Workout to unlock." |
| Workout synced | "Nice. +32 min added to your bank." |
| Approaching cap | "Bank almost full. Don't let those gains go to waste." |

**Notification Philosophy:**
- Terse, direct, slightly confrontational
- No emoji spam
- No patronizing "Great job!" energy

---

## 6. Technical Architecture

### 6.1 iOS Frameworks Required

| Framework | Purpose |
|-----------|---------|
| **FamilyControls** | Request authorization to block apps |
| **ManagedSettings** | Apply app restrictions |
| **DeviceActivity** | Schedule and monitor blocking |
| **HealthKit** | Read workout data from Apple Health |

### 6.2 Data Model

```
User
├── difficulty: Difficulty (easy|medium|hard|extreme)
├── bankBalance: Int (minutes)
├── blockedApps: [ApplicationToken]
├── createdAt: Date
└── settings: UserSettings

UserSettings
├── notifyAt15Min: Bool
├── notifyAt5Min: Bool
└── notifyOnSync: Bool

WorkoutLog
├── id: UUID
├── date: Date
├── durationMinutes: Int
├── workoutType: String
├── minutesEarned: Int
└── syncedAt: Date

UsageLog
├── id: UUID
├── date: Date
├── appToken: ApplicationToken
├── minutesUsed: Int
└── timestamp: Date
```

### 6.3 Sync Logic

**Workout Sync (Pull from HealthKit):**
1. App checks HealthKit for new workouts on:
   - App foreground
   - Background refresh (every 15 min)
   - Manual pull-to-refresh
2. For each new workout since last sync:
   - Calculate earned minutes based on difficulty
   - Add to bank (capped at max)
   - Log to WorkoutLog
   - Send notification

**Usage Tracking:**
- DeviceActivity reports usage in real-time
- Bank decrements as usage accrues
- At 0: ManagedSettings applies hard block

### 6.4 Persistence

**Local Storage (MVP):**
- UserDefaults for settings
- Core Data for logs
- No server, no accounts, no cloud sync

**Future (Post-MVP):**
- iCloud sync for multi-device
- Optional account for social features

---

## 7. What's NOT in MVP

Explicitly descoped to ship fast:

| Feature | Why Not |
|---------|---------|
| **User accounts** | Adds friction, requires backend |
| **Social/friends** | Complex, not core to value prop |
| **Leaderboards** | Requires accounts + backend |
| **Streaks** | Nice-to-have, not essential |
| **Widgets** | Polish, not core |
| **Apple Watch app** | Companion app complexity |
| **Detailed analytics** | Basic "today" view is enough |
| **Multiple profiles** | Edge case, adds complexity |
| **Scheduled blocks** | Conflicts with bank mechanic |
| **Website blocking** | Safari content blockers are separate beast |
| **Android** | iOS first, validate then expand |
| **Paywall/Premium** | Win market first |

---

## 8. Monetization Strategy (Post-MVP)

### Phase 1: Free (MVP)
- All features free
- Build user base, gather feedback, iterate
- Target: 10K+ downloads before monetization

### Phase 2: Freemium (v2.0)

**Free Tier:**
- 3 blocked apps max
- Medium difficulty only
- Basic features

**Premium ($4.99/mo or $29.99/yr):**
- Unlimited blocked apps
- All difficulty modes
- Detailed analytics & history
- Widgets
- iCloud sync

### Phase 3: Expansion
- Social features (squads, challenges)
- B2B (universities, corporate wellness)
- Hardware partnerships (Whoop, Garmin)

---

## 9. Success Metrics

### North Star Metric
**Weekly Active Users (WAU)** who complete at least one workout sync

### Supporting Metrics

| Metric | Target (90 days post-launch) |
|--------|------------------------------|
| Downloads | 10,000 |
| D1 Retention | 40% |
| D7 Retention | 25% |
| D30 Retention | 15% |
| Avg. workouts/user/week | 3+ |
| App Store Rating | 4.5+ |
| Organic/word-of-mouth % | 30%+ |

### Qualitative Signals
- Unsolicited social media posts
- "This app changed my life" reviews
- Requests for Android version
- Users asking for harder difficulty modes

---

## 10. Risks & Honest Critique

### Technical Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Users can disable Screen Time permissions** | HIGH | Fundamental iOS limitation. No mitigation. Be transparent that LockedIn requires user commitment. |
| **Apple changes/restricts Screen Time API** | MEDIUM | Monitor Apple developer relations, have contingency plans. |
| **HealthKit sync delays** | LOW | Background refresh + manual sync option. |
| **Apple Health can be spoofed** | LOW | Accept it. Users who game the system are only cheating themselves. |

### Product Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Too harsh → rage uninstalls** | HIGH | Starting with 60 min gives buffer. Easy mode exists. Messaging emphasizes user choice. |
| **Name collision with competitors** | MEDIUM | Multiple "Locked In" variants exist. Differentiate via subtitle ("Earn Screen Time"), fitness angle, and superior execution. |
| **Direct competitors improve** | MEDIUM | Move fast, build brand loyalty, differentiate on UX and voice. |
| **Narrow audience** | MEDIUM | Validate with niche first, expand messaging later. |
| **No social = no virality** | MEDIUM | Rely on word-of-mouth, influencers, content marketing initially. |

### Brutal Honesty: What Could Suck

1. **The "hard block" is a lie.** iOS doesn't allow truly unbypassable blocks for third-party apps. Users can always go to Settings → Screen Time → disable LockedIn's access. The block is only as strong as the user's willpower. This is a fundamental limitation of the platform, not something you can engineer around. **Mitigation:** Be transparent. Market it as "accountability tool" not "prison." The friction is the feature.

2. **Trust-based workout tracking is gameable.** Someone can log fake workouts via third-party apps or manual Health entries. You'll have users gaming the system day one. **Mitigation:** Accept it. Those users were never your target audience. The honest users will get value.

3. **60 minutes starting balance might be too generous.** A user could download the app and immediately burn through 60 minutes of Instagram without ever working out, then uninstall in frustration when blocked. **Counter-argument:** This is intentional. The first block is the moment of truth. Users who uninstall weren't committed. Users who workout instead are your core audience.

4. **"Difficulty as identity" might not resonate.** The assumption that users will take pride in their difficulty level is unvalidated. They might just pick Easy and never think about it. **Mitigation:** Make difficulty visible and prominent. Consider future social features that display difficulty.

5. **No recurring revenue = no sustainability.** A free app with no monetization can't sustain development long-term. The "win market first" strategy works only if you actually monetize later. **Mitigation:** Plan freemium transition at specific milestone (10K users or 6 months, whichever first).

---

## 11. Launch Checklist

### Pre-Launch
- [ ] Apple Developer account with Screen Time entitlement
- [ ] App Store listing (screenshots, description, keywords)
- [ ] Landing page (lockedin.app or similar)
- [ ] Social accounts (@lockedinapp)
- [ ] Press kit

### Launch Channels
- [ ] Product Hunt launch
- [ ] Reddit: r/nosurf, r/digitalminimalism, r/getdisciplined, r/fitness
- [ ] Twitter/X fitness & productivity community
- [ ] TikTok content (screen time before/after)
- [ ] Micro-influencer outreach (fitness, productivity)

### Post-Launch (Week 1)
- [ ] Monitor crash reports
- [ ] Respond to all App Store reviews
- [ ] Gather feedback via in-app prompt
- [ ] Iterate based on user pain points

---

## 12. Open Questions

1. **Should difficulty be changeable anytime, or locked for X days?** Allowing changes anytime lets users "cheat down" to Easy. But locking it feels punitive. Current stance: Allow changes, trust the user.

2. **What happens on day 1 if user has no workout history?** They get 60 min, period. No retroactive credit for past workouts. Clean slate.

3. **Should the app have a "vacation mode"?** Temporarily disable blocking for travel, illness, etc. Current stance: No. You can always uninstall. Vacation mode undermines the no-bullshit philosophy.

4. **Minimum workout duration to count?** Current stance: None. If Apple Health logged it, it counts. A 5-minute walk earns 5 minutes (on Medium). This might be too generous.

5. **Should we show cumulative stats?** "You've earned 47 hours and blocked 89 hours of brain rot." Motivational, but adds complexity. Current stance: Post-MVP.

---

## 13. Version Roadmap

### v1.0 (MVP) - Target: 8 weeks
- Core bank mechanic
- Apple Health sync
- Hard blocking
- Difficulty modes
- Minimal settings

### v1.1 - Target: MVP + 4 weeks
- Widgets
- Improved analytics (weekly view)
- Bug fixes from v1.0 feedback

### v1.2 - Target: MVP + 8 weeks
- Streaks
- iCloud sync
- Apple Watch companion (view-only)

### v2.0 - Target: MVP + 16 weeks
- Freemium paywall
- Social features (squads, challenges)
- Detailed analytics

---

## Appendix A: Competitive Positioning

| App | Positioning | LockedIn Differentiator |
|-----|-------------|-------------------------|
| Opal | Premium focus tool, $99/yr | Free, fitness-integrated, harsher |
| One Sec | Mindful pauses, breathing | No pauses, hard blocks |
| ScreenZen | Gentle, awareness-focused | No gentleness, accountability |
| Fitlock | Fitness → screen time | Better UX, stronger brand, harsher |
| Fit to Scroll | Exercise reps → minutes | Apple Health integration (any workout) |

**LockedIn's position:** The no-bullshit option. For people who've tried the gentle apps and need something harsher.

---

## Appendix B: Brand Voice Examples

**Do:**
- "You're out of time."
- "Earn more by working out."
- "No excuses. No mercy."
- "47 minutes left. Make them count."

**Don't:**
- "Great job! You've earned screen time! 🎉"
- "Oopsie! Looks like you've run out of time 😅"
- "Remember, it's okay to take breaks!"
- "You're doing amazing sweetie!"

The voice is: **Direct. Terse. Slightly confrontational. Respects the user's intelligence.**

---

## Appendix C: App Store Metadata

**App Name:** LockedIn: Earn Screen Time

**Subtitle:** Workout to Unlock Your Apps

**Keywords:** screen time, app blocker, digital detox, workout, fitness, brain rot, doom scrolling, focus, productivity, health

**Description (Draft):**
```
Earn your screen time. One workout at a time.

LockedIn blocks your brain rot apps until you've earned the right to use them. No mercy. No excuses. Just results.

HOW IT WORKS
• Select the apps that waste your time
• Start with 60 minutes in the bank
• Every minute of exercise earns screen time
• When you hit zero, you're locked out
• Workout to unlock

CHOOSE YOUR DIFFICULTY
• Easy: For beginners
• Medium: Fair trade
• Hard: For the serious
• Extreme: No excuses. No mercy.

FEATURES
• Syncs with Apple Health (any workout counts)
• Hard blocks—no snooze, no "5 more minutes"
• Simple, clean interface
• No account required
• No ads. No BS.

Stop doom scrolling. Start earning.
```

---

## Appendix D: Design Language

### Philosophy: Industrial Brutalism

LockedIn's visual design embodies **functional beauty through restraint**. Every pixel earns its place. The UI itself is "no bullshit"—raw, stark, confident.

**Core Principles:**

| Principle | Meaning |
|-----------|---------|
| **Restraint** | Remove everything unnecessary. If it doesn't serve function, delete it. |
| **Precision** | Exact spacing, perfect alignment, intentional typography. |
| **Contrast** | Pure black canvas. White text. Color used sparingly and meaningfully. |
| **Weight** | The balance number should feel heavy, precious, earned—like checking a vault. |
| **Tension** | The design creates subtle psychological pressure that motivates action. |

**Influences:**
- Dieter Rams / Braun (functional beauty)
- Swiss International Style (typography-driven hierarchy)
- Industrial design (raw materials, visible structure)
- Terminal/banking interfaces (monospace, data-dense)

---

### Color System

**Base Palette (Dark Mode Only):**

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#000000` | Pure black canvas |
| `surface` | `#111111` | Elevated surfaces (if needed) |
| `border` | `#222222` | Dividers, progress bar track |
| `textPrimary` | `#FFFFFF` | Balance number, headers |
| `textSecondary` | `#888888` | Labels, secondary info |
| `textTertiary` | `#666666` | Hints, disabled states |

**Difficulty Accent Colors:**

| Difficulty | Hex | Rationale |
|------------|-----|-----------|
| **Easy** | `#22C55E` | Green = growth, beginning |
| **Medium** | `#EAB308` | Amber = caution, balance |
| **Hard** | `#F97316` | Orange = warning, intensity |
| **Extreme** | `#DC2626` | Red = danger, maximum |

**Color Rules:**
- Accent colors appear ONLY for difficulty-related elements (rank bars, progress fill, difficulty label)
- No gradients. No shadows. Flat, honest color.
- The accent color is earned—it represents the user's commitment level

---

### Typography

**Hierarchy:**

| Element | Font | Size | Weight | Tracking |
|---------|------|------|--------|----------|
| Balance Number | SF Mono | 120pt | Bold | 0 |
| Section Label | SF Pro | 11-12pt | Semibold | 3-6pt |
| Body Text | SF Pro | 14pt | Regular | 0 |
| Mono Data | SF Mono | 10-11pt | Medium | 0 |

**Rules:**
- Labels are ALL CAPS with generous letter-spacing (tracking)
- Numbers use monospace for the "data terminal" aesthetic
- No decorative fonts. System fonts only.
- Hierarchy through size and weight, never through decoration

---

### Spacing System

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4pt | Tight gaps (between rank bars) |
| `sm` | 8pt | Related elements |
| `md` | 16pt | Section internal padding |
| `lg` | 24pt | Section separation |
| `xl` | 32pt | Major section breaks |
| `xxl` | 48pt | Hero element breathing room |

**Rules:**
- Generous whitespace (blackspace) around the balance—it's the star
- Consistent horizontal padding (24pt from edges)
- Let spacing create hierarchy, not boxes or dividers

---

### Component Patterns

**The Balance Display (Hero)**
```
        47
      MINUTES

       ▮▮▮░
       HARD
```
- Massive centered number
- Understated label below
- Difficulty rank with bars

**Difficulty Rank Bars**
```
▮░░░  EASY
▮▮░░  MEDIUM
▮▮▮░  HARD
▮▮▮▮  EXTREME
```
- 4 bars total, filled based on level
- Colored in difficulty accent
- Unfilled bars use `border` color

**Progress Bar**
```
0 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 120
        ▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░
              47 / 120
```
- 4pt height, sharp edges (no border radius)
- Fill color = difficulty accent
- Track color = `border`
- Min/max labels at edges

**Section Dividers**
- 1pt horizontal line in `border` color
- Full width minus horizontal padding
- No decorative elements

---

### What We Don't Do

| Anti-Pattern | Why |
|--------------|-----|
| Rounded corners | Too soft. We're sharp and direct. |
| Shadows/elevation | Flat design. Honest surfaces. |
| Gradients | Unnecessary decoration. |
| Icons for everything | Text is clearer. Icons only where universal (gear for settings). |
| Animations for delight | Motion only for state changes, never for decoration. |
| Light mode | Dark mode reinforces focus and seriousness. |
| Emoji | Brand voice is direct, not playful. |
| Celebration states | No confetti. No "Great job!" The work is its own reward. |

---

### Dashboard Layout

```
┌─────────────────────────────────────────────┐
│                                             │
│  LOCKEDIN                              [⚙]  │
│                                             │
│                                             │
│                                             │
│                   47                        │
│                MINUTES                      │
│                                             │
│                 ▮▮▮░                        │
│                 HARD                        │
│                                             │
│                                             │
│  0 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 120  │
│              47 / 120                       │
│                                             │
│  ─────────────────────────────────────────  │
│                                             │
│  BLOCKED                                 4  │
│                                             │
└─────────────────────────────────────────────┘
```

**Hierarchy:**
1. Balance number (the vault)
2. Difficulty rank (identity)
3. Progress bar (context)
4. Blocked apps (reference)

---

*Document authored by Claude. Updated January 2, 2026. Ready for founder review and iteration.*
