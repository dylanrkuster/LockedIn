//
//  AnalyticsManager.swift
//  LockedIn
//
//  Centralized analytics tracking. Functional. Not invasive.
//

import FirebaseAnalytics
import Foundation

// MARK: - Analytics Manager

enum AnalyticsManager {
    /// Background queue for analytics - never block the main thread
    private static let queue = DispatchQueue(label: "com.lockedin.analytics", qos: .utility)

    /// Track an analytics event (fire-and-forget, never blocks UI)
    static func track(_ event: AnalyticsEvent) {
        queue.async {
            Analytics.logEvent(event.name, parameters: event.parameters)
        }
    }

    /// Set a user property (persists across sessions)
    static func setUserProperty(_ value: String, forName name: String) {
        queue.async {
            Analytics.setUserProperty(value, forName: name)
        }
    }

    /// Set difficulty user property
    static func setDifficulty(_ difficulty: String) {
        setUserProperty(difficulty, forName: "difficulty")
    }

    /// Set blocked app count user property
    static func setBlockedAppCount(_ count: Int) {
        setUserProperty("\(count)", forName: "blocked_app_count")
    }
}

// MARK: - Analytics Events

enum AnalyticsEvent {
    // Onboarding funnel
    case onboardingStarted
    case onboardingAppsSelected(count: Int)
    case onboardingDifficultySelected(difficulty: String)
    case onboardingPermissionsGranted(screenTime: Bool, health: Bool, notifications: Bool)
    case onboardingCompleted(difficulty: String, appCount: Int)

    // Core loop
    case workoutSynced(minutesEarned: Int, workoutType: String, balanceAfter: Int)
    case balanceDepleted(difficulty: String, daysSinceInstall: Int)
    case balanceRecovered(minutesToRecover: Int)
    case shieldDisplayed(count: Int)

    // Engagement
    case appForegrounded(balance: Int, difficulty: String)
    case difficultyChanged(from: String, to: String, balanceLost: Int)
    case blockedAppsModified(appCount: Int, categoryCount: Int)
    case activityHistoryViewed
    case settingsOpened

    // Milestones
    case reviewPromptShown(workoutCount: Int)
    case firstWorkoutSynced(minutesEarned: Int)
    case firstBlockHit(daysSinceInstall: Int)

    var name: String {
        switch self {
        case .onboardingStarted: return "onboarding_started"
        case .onboardingAppsSelected: return "onboarding_apps_selected"
        case .onboardingDifficultySelected: return "onboarding_difficulty_selected"
        case .onboardingPermissionsGranted: return "onboarding_permissions_granted"
        case .onboardingCompleted: return "onboarding_completed"
        case .workoutSynced: return "workout_synced"
        case .balanceDepleted: return "balance_depleted"
        case .balanceRecovered: return "balance_recovered"
        case .shieldDisplayed: return "shield_displayed"
        case .appForegrounded: return "app_foregrounded"
        case .difficultyChanged: return "difficulty_changed"
        case .blockedAppsModified: return "blocked_apps_modified"
        case .activityHistoryViewed: return "activity_history_viewed"
        case .settingsOpened: return "settings_opened"
        case .reviewPromptShown: return "review_prompt_shown"
        case .firstWorkoutSynced: return "first_workout_synced"
        case .firstBlockHit: return "first_block_hit"
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .onboardingStarted:
            return nil

        case .onboardingAppsSelected(let count):
            return ["app_count": count]

        case .onboardingDifficultySelected(let difficulty):
            return ["difficulty": difficulty]

        case .onboardingPermissionsGranted(let screenTime, let health, let notifications):
            return [
                "screen_time_granted": screenTime,
                "health_granted": health,
                "notifications_granted": notifications
            ]

        case .onboardingCompleted(let difficulty, let appCount):
            return [
                "difficulty": difficulty,
                "app_count": appCount
            ]

        case .workoutSynced(let minutesEarned, let workoutType, let balanceAfter):
            return [
                "minutes_earned": minutesEarned,
                "workout_type": workoutType,
                "balance_after": balanceAfter
            ]

        case .balanceDepleted(let difficulty, let daysSinceInstall):
            return [
                "difficulty": difficulty,
                "days_since_install": daysSinceInstall
            ]

        case .balanceRecovered(let minutesToRecover):
            return ["minutes_to_recover": minutesToRecover]

        case .shieldDisplayed(let count):
            return ["display_count": count]

        case .appForegrounded(let balance, let difficulty):
            return [
                "balance": balance,
                "difficulty": difficulty
            ]

        case .difficultyChanged(let from, let to, let balanceLost):
            return [
                "from_difficulty": from,
                "to_difficulty": to,
                "balance_lost": balanceLost
            ]

        case .blockedAppsModified(let appCount, let categoryCount):
            return [
                "app_count": appCount,
                "category_count": categoryCount
            ]

        case .activityHistoryViewed:
            return nil

        case .settingsOpened:
            return nil

        case .reviewPromptShown(let workoutCount):
            return ["workout_count": workoutCount]

        case .firstWorkoutSynced(let minutesEarned):
            return ["minutes_earned": minutesEarned]

        case .firstBlockHit(let daysSinceInstall):
            return ["days_since_install": daysSinceInstall]
        }
    }
}
