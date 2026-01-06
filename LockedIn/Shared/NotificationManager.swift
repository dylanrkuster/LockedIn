//
//  NotificationManager.swift
//  LockedIn (Shared)
//
//  Centralized notification posting for balance warnings and workout sync.
//  This file should be added to ALL targets (main app + extensions).
//

import UserNotifications

/// Delegate to handle foreground notification display.
/// Without this, iOS silently suppresses notifications when app is in foreground.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    private override init() {
        super.init()
    }

    /// Show notification banners even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

/// Handles posting local notifications for LockedIn events.
/// Caller is responsible for checking settings and spam prevention.
enum NotificationManager {

    // MARK: - Notification Identifiers

    private enum Identifier {
        static let lowBalance5Min = "lockedin.lowbalance.5min"
        static let lowBalance15Min = "lockedin.lowbalance.15min"
        static let workoutSynced = "lockedin.workout.synced"
    }

    // MARK: - Notification Title

    private static let appTitle = "LOCKEDIN"

    // MARK: - Low Balance Notifications

    /// Post 5 minute warning notification.
    /// Caller should check SharedState.notify5MinWarning and notified5MinToday first.
    static func postLowBalance5MinWarning() {
        post(
            identifier: Identifier.lowBalance5Min,
            title: appTitle,
            body: "5 min of screen time remaining."
        )
    }

    /// Post 15 minute warning notification.
    /// Caller should check SharedState.notify15MinWarning and notified15MinToday first.
    static func postLowBalance15MinWarning() {
        post(
            identifier: Identifier.lowBalance15Min,
            title: appTitle,
            body: "15 min of screen time remaining."
        )
    }

    // MARK: - Workout Notifications

    /// Post workout synced notification.
    /// - Parameter earnedMinutes: Minutes earned from the workout
    static func postWorkoutSynced(earnedMinutes: Int) {
        post(
            identifier: Identifier.workoutSynced,
            title: appTitle,
            body: "Workout complete. +\(earnedMinutes) min added to your bank."
        )
    }

    /// Post workout synced notification when earnings were capped.
    /// - Parameter earnedMinutes: Minutes actually earned (after cap)
    static func postWorkoutSyncedCapped(earnedMinutes: Int) {
        post(
            identifier: Identifier.workoutSynced,
            title: appTitle,
            body: "Workout complete. +\(earnedMinutes) min added. Bank full."
        )
    }

    // MARK: - Internal

    private static func post(identifier: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // Fire immediately (no trigger = immediate delivery)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                // Log but don't crash - notifications are non-critical
                print("Failed to post notification: \(error.localizedDescription)")
            }
        }
    }
}
