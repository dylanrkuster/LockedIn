//
//  BlockingManager.swift
//  LockedIn
//
//  Orchestrates DeviceActivity monitoring and ManagedSettings shields.
//  Bridges between main app state and the extension infrastructure.
//

import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

@Observable
final class BlockingManager {
    // MARK: - Properties

    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore()

    private(set) var isMonitoring = false

    // MARK: - Constants

    static let activityName = DeviceActivityName("lockedin.daily")
    static let balanceExhaustedEvent = DeviceActivityEvent.Name("balanceExhausted")

    // MARK: - Init

    init() {
        isMonitoring = SharedState.isMonitoring
    }

    // MARK: - Monitoring

    /// Start monitoring blocked apps. Sets up a threshold event that fires
    /// when cumulative usage equals the current balance.
    func startMonitoring(
        selection: FamilyActivitySelection,
        balance: Int
    ) throws {
        guard balance > 0 else {
            // No balance - apply shield immediately, no need to monitor
            applyShield(for: selection)
            return
        }

        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty else {
            // Nothing to monitor
            return
        }

        // Schedule covers the full day, repeats daily
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        // Event fires when cumulative usage equals remaining balance
        // This is the moment to apply the shield
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            threshold: DateComponents(minute: balance)
        )

        try center.startMonitoring(
            Self.activityName,
            during: schedule,
            events: [Self.balanceExhaustedEvent: event]
        )

        isMonitoring = true
        SharedState.isMonitoring = true
        SharedState.synchronize()
    }

    /// Stop all monitoring
    func stopMonitoring() {
        center.stopMonitoring([Self.activityName])
        isMonitoring = false
        SharedState.isMonitoring = false
        SharedState.synchronize()
    }

    /// Update the threshold when balance changes (e.g., after workout)
    func updateMonitoring(balance: Int, selection: FamilyActivitySelection) throws {
        // Apply shield first to avoid gap in protection during transition
        syncShieldState(balance: balance, selection: selection)

        // Then update monitoring
        stopMonitoring()

        if balance > 0 && (!selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty) {
            try startMonitoring(selection: selection, balance: balance)
        }
    }

    // MARK: - Shield Management

    /// Apply shield to all selected apps (blocks access)
    func applyShield(for selection: FamilyActivitySelection) {
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
    }

    /// Remove all shields (restores access)
    func removeShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    /// Sync shield state based on current balance
    func syncShieldState(balance: Int, selection: FamilyActivitySelection) {
        if balance <= 0 {
            applyShield(for: selection)
        } else {
            removeShield()
        }
    }

    // MARK: - Status

    /// Check if monitoring is currently active for our activity
    var activitiesBeingMonitored: [DeviceActivityName] {
        center.activities
    }
}
