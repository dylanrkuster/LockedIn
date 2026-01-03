//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitorExtension
//
//  Monitors blocked app usage and applies shields when balance is exhausted.
//

import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

/// DeviceActivity monitor that tracks blocked app usage.
/// Receives callbacks when usage thresholds are reached.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()

    // MARK: - Interval Callbacks

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // New monitoring interval started - sync shield state
        syncShieldState()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Interval ended - could reset daily tracking here if needed
    }

    // MARK: - Event Callbacks

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)

        // Balance exhausted! User has used all their screen time.
        // Set balance to 0 and apply shield.
        SharedState.balance = 0
        SharedState.synchronize()

        applyShield()
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
