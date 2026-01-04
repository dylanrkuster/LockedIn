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

        // New monitoring interval (new day) - sync shield state and reset daily counter
        SharedState.usedMinutesToday = 0
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
