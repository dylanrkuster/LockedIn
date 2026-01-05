//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitorExtension
//
//  Monitors blocked app usage via incremental threshold events.
//  Each minute of usage triggers a callback, allowing real-time balance tracking.
//
//  IMPORTANT: The device's usage counter resets when monitoring starts.
//  Events are named "minute_N" where N is the cumulative minutes since monitoring started.
//  The main app resets SharedState.usedMinutesToday to 0 when starting monitoring.
//

import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

/// DeviceActivity monitor that tracks blocked app usage minute-by-minute.
/// Receives callbacks when each usage threshold is reached.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()

    // MARK: - Interval Callbacks

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        ExtensionLogger.logInterval("intervalDidStart", message: "activity=\(activity.rawValue)")
        SharedState.updateHeartbeat()

        // New monitoring interval (new day) - reset daily counter and calibration timestamp
        SharedState.usedMinutesToday = 0
        SharedState.monitoringStartedAt = Date().timeIntervalSince1970
        SharedState.synchronize()
        syncShieldState()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        ExtensionLogger.logInterval("intervalDidEnd", message: "activity=\(activity.rawValue)")
        SharedState.updateHeartbeat()
        SharedState.synchronize()

        // Day ended - reset daily usage tracking happens automatically
        // via the date check in SharedState.usedMinutesToday
    }

    // MARK: - Event Callbacks

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)

        // Update heartbeat immediately on entry
        SharedState.updateHeartbeat()

        // Parse the minute value from the event name (e.g., "minute_5" → 5)
        guard let minute = TrackingLogic.parseMinute(from: event.rawValue) else {
            ExtensionLogger.logError("parse_failed", context: "event=\(event.rawValue)")
            return
        }

        // Get current tracking state
        let previousUsed = SharedState.usedMinutesToday
        let currentBalance = SharedState.balance

        // Calibration: events within first 10 seconds of monitoring start are retroactive.
        // DeviceActivity fires events for ALL thresholds already passed (prior usage today).
        // These fire within milliseconds; real usage events take 60+ seconds.
        let calibrationWindow: TimeInterval = 10
        let timeSinceMonitoringStarted = Date().timeIntervalSince1970 - SharedState.monitoringStartedAt

        if timeSinceMonitoringStarted < calibrationWindow {
            // Sync our counter to device's counter without deducting
            SharedState.usedMinutesToday = max(SharedState.usedMinutesToday, minute)
            ExtensionLogger.logInterval("calibration", message: "synced to minute \(minute), time=\(String(format: "%.1f", timeSinceMonitoringStarted))s")
            SharedState.debugExtensionMessage = "Calibrated: min=\(minute)"
            SharedState.synchronize()
            return
        }

        // Calculate deduction using pure function
        let result = TrackingLogic.calculateDeduction(
            minute: minute,
            previousUsed: previousUsed,
            currentBalance: currentBalance
        )

        // Handle skip case
        if result.shouldSkip {
            ExtensionLogger.logSkip(
                minute: minute,
                previousUsed: previousUsed,
                reason: "minute <= previousUsed"
            )
            SharedState.debugExtensionMessage = "Skip: min=\(minute) prev=\(previousUsed)"
            SharedState.synchronize()
            return
        }

        // Update used minutes tracker
        SharedState.usedMinutesToday = minute

        // Apply balance change
        SharedState.balance = result.newBalance

        // Log the spend transaction
        if result.toDeduct > 0 {
            let blockedAppCount = getBlockedAppCount()
            let source = blockedAppCount == 1 ? "Blocked App" : "Blocked Apps"
            logSpendTransaction(minutes: result.toDeduct, source: source)
        }

        // Persistent file logging for diagnostics
        ExtensionLogger.logThreshold(
            minute: minute,
            previousUsed: previousUsed,
            currentBalance: currentBalance,
            newBalance: result.newBalance,
            deducted: result.toDeduct
        )

        // Debug logging (legacy - keep for backwards compatibility)
        SharedState.debugExtensionRunCount += 1
        SharedState.debugExtensionMessage = "min=\(minute) deduct=\(result.toDeduct) bal=\(result.newBalance)"

        SharedState.synchronize()

        // Check for low balance notifications
        checkAndPostLowBalanceNotification(
            previousBalance: currentBalance,
            newBalance: result.newBalance
        )

        // Apply shield if balance exhausted
        if TrackingLogic.shouldApplyShield(balance: result.newBalance) {
            ExtensionLogger.logInterval("shield_applied", message: "balance exhausted")
            applyShield()
        }
    }

    /// Get count of blocked apps from selection
    private func getBlockedAppCount() -> Int {
        guard let data = SharedState.selectionData,
              let selection = try? SharedState.plistDecoder.decode(
                  FamilyActivitySelection.self,
                  from: data
              )
        else { return 0 }

        return selection.applicationTokens.count + selection.categoryTokens.count
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        ExtensionLogger.logInterval("intervalWillStartWarning", message: "activity=\(activity.rawValue)")
        SharedState.updateHeartbeat()
        SharedState.synchronize()
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        ExtensionLogger.logInterval("intervalWillEndWarning", message: "activity=\(activity.rawValue)")
        SharedState.updateHeartbeat()
        SharedState.synchronize()
    }

    override func eventWillReachThresholdWarning(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        ExtensionLogger.logInterval("eventWillReachThresholdWarning", message: "event=\(event.rawValue)")
        SharedState.updateHeartbeat()
        SharedState.synchronize()
    }

    // MARK: - Notifications

    /// Check if balance crossed notification thresholds and post if needed.
    /// If balance drops through both 15 and 5 in one event, only fires 15 min warning
    /// (user will get 5 min warning later when they continue using blocked apps).
    private func checkAndPostLowBalanceNotification(previousBalance: Int, newBalance: Int) {
        var posted15Min = false

        // Check 15 min threshold crossing (from above 15 to at or below 15)
        if previousBalance > 15 && newBalance <= 15 {
            if SharedState.notify15MinWarning && !SharedState.notified15MinToday {
                NotificationManager.postLowBalance15MinWarning()
                SharedState.notified15MinToday = true
                posted15Min = true
                SharedState.synchronize()
                ExtensionLogger.logInterval("notification_15min", message: "balance=\(newBalance)")
            }
        }

        // Check 5 min threshold crossing (from above 5 to at or below 5)
        // Skip if we just posted 15 min warning (avoid notification spam)
        if previousBalance > 5 && newBalance <= 5 && !posted15Min {
            if SharedState.notify5MinWarning && !SharedState.notified5MinToday {
                NotificationManager.postLowBalance5MinWarning()
                SharedState.notified5MinToday = true
                SharedState.synchronize()
                ExtensionLogger.logInterval("notification_5min", message: "balance=\(newBalance)")
            }
        }
    }

    // MARK: - Transaction Logging

    private func logSpendTransaction(minutes: Int, source: String) {
        let record = TransactionRecord(
            id: UUID(),
            amount: -minutes,
            source: source,
            timestamp: Date()
        )
        SharedState.appendTransaction(record)
    }

    // MARK: - Shield Management

    private func syncShieldState() {
        if SharedState.balance <= 0 {
            applyShield()
        } else {
            removeShield()
        }
    }

    private func applyShield() {
        guard let data = SharedState.selectionData,
              let selection = try? SharedState.plistDecoder.decode(
                  FamilyActivitySelection.self,
                  from: data
              )
        else { return }

        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
    }

    private func removeShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }
}
