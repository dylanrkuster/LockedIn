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

        // New monitoring interval (new day) - sync shield state and reset daily counter
        SharedState.usedMinutesToday = 0
        SharedState.synchronize()
        syncShieldState()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Day ended - reset daily usage tracking happens automatically
        // via the date check in SharedState.usedMinutesToday
    }

    // MARK: - Event Callbacks

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)

        // Parse the minute value from the event name (e.g., "minute_5" → 5)
        guard let minute = parseMinute(from: event) else { return }

        // Get current tracking state
        let previousUsed = SharedState.usedMinutesToday
        let currentBalance = SharedState.balance

        // Safety check: only process if this is a new minute (avoid re-processing)
        // This should always be true if events fire in order: minute_1, minute_2, etc.
        guard minute > previousUsed else {
            // Log unexpected state for debugging
            SharedState.debugExtensionMessage = "Skip: min=\(minute) prev=\(previousUsed)"
            SharedState.synchronize()
            return
        }

        // Calculate new usage since last processed event (usually 1 minute)
        let newMinutesUsed = minute - previousUsed

        // Update used minutes tracker
        SharedState.usedMinutesToday = minute

        // Deduct from balance (can't go below 0)
        let toDeduct = min(newMinutesUsed, currentBalance)
        let newBalance = max(0, currentBalance - toDeduct)

        SharedState.balance = newBalance

        // Log the spend transaction
        if toDeduct > 0 {
            let blockedAppCount = getBlockedAppCount()
            let source = blockedAppCount == 1 ? "Blocked App" : "Blocked Apps"
            logSpendTransaction(minutes: toDeduct, source: source)
        }

        // Debug logging
        SharedState.debugExtensionRunCount += 1
        SharedState.debugExtensionMessage = "min=\(minute) deduct=\(toDeduct) bal=\(newBalance)"

        SharedState.synchronize()

        // Apply shield if balance exhausted
        if newBalance <= 0 {
            applyShield()
        }
    }

    /// Parse minute value from event name like "minute_5"
    private func parseMinute(from event: DeviceActivityEvent.Name) -> Int? {
        let raw = event.rawValue
        guard raw.hasPrefix("minute_"),
              let minute = Int(raw.dropFirst(7))
        else { return nil }
        return minute
    }

    /// Get count of blocked apps from selection
    private func getBlockedAppCount() -> Int {
        guard let data = SharedState.selectionData,
              let selection = try? PropertyListDecoder().decode(
                  FamilyActivitySelection.self,
                  from: data
              )
        else { return 0 }

        return selection.applicationTokens.count + selection.categoryTokens.count
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        // Could send notification before interval starts
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        // Could send notification before interval ends
    }

    override func eventWillReachThresholdWarning(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        // Could send "5 minutes remaining" notification here
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
              let selection = try? PropertyListDecoder().decode(
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
