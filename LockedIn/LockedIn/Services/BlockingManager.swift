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

    /// Maximum number of minute-by-minute events to track.
    /// Must be >= the highest possible balance (Easy mode = 240 min).
    static let maxIncrementalMinutes = 240

    /// Generate event name for a specific minute threshold
    static func eventName(forMinute minute: Int) -> DeviceActivityEvent.Name {
        DeviceActivityEvent.Name("minute_\(minute)")
    }

    /// Extract minute value from event name (returns nil if not a minute event)
    static func minute(fromEventName name: DeviceActivityEvent.Name) -> Int? {
        let raw = name.rawValue
        guard raw.hasPrefix("minute_"),
              let minute = Int(raw.dropFirst(7))
        else { return nil }
        return minute
    }

    // MARK: - Init

    init() {
        isMonitoring = SharedState.isMonitoring
    }

    // MARK: - Monitoring

    /// Start monitoring blocked apps. Sets up incremental threshold events
    /// that fire every minute to track usage in real-time.
    ///
    /// IMPORTANT: Calling this resets the device's internal usage counter.
    /// Only call when monitoring isn't already running or when selection changes.
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
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )

        // CRITICAL: When monitoring starts/restarts, the device resets its usage counter.
        // We must reset our tracking to match and create events from minute 1.
        SharedState.usedMinutesToday = 0
        SharedState.synchronize()

        // Create events from minute 1 to min(balance, maxIncrementalMinutes)
        let maxMinutes = min(balance, Self.maxIncrementalMinutes)
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        for minute in 1...maxMinutes {
            let event = DeviceActivityEvent(
                applications: selection.applicationTokens,
                categories: selection.categoryTokens,
                threshold: DateComponents(minute: minute)
            )
            events[Self.eventName(forMinute: minute)] = event
        }

        try center.startMonitoring(
            Self.activityName,
            during: schedule,
            events: events
        )

        isMonitoring = true
        SharedState.isMonitoring = true
        SharedState.synchronize()
    }

    /// Start monitoring only if not already active. Safe to call repeatedly.
    /// Use this for app launch/foreground to avoid resetting device counters.
    func startMonitoringIfNeeded(
        selection: FamilyActivitySelection,
        balance: Int
    ) throws {
        // Check if already monitoring this activity
        if center.activities.contains(Self.activityName) {
            return
        }
        try startMonitoring(selection: selection, balance: balance)
    }

    /// Stop all monitoring
    func stopMonitoring() {
        center.stopMonitoring([Self.activityName])
        isMonitoring = false
        SharedState.isMonitoring = false
        SharedState.synchronize()
    }

    /// Update monitoring when selection changes.
    /// Only restarts monitoring if forceRestart is true or monitoring isn't running.
    ///
    /// - Parameters:
    ///   - balance: Current balance in minutes
    ///   - selection: Currently selected apps to block
    ///   - forceRestart: If true, stops and restarts monitoring (resets device counter).
    ///                   Only set true when app selection actually changes.
    func updateMonitoring(
        balance: Int,
        selection: FamilyActivitySelection,
        forceRestart: Bool = false
    ) throws {
        // Always sync shield state (doesn't affect monitoring)
        syncShieldState(balance: balance, selection: selection)

        // Only restart monitoring if forced (selection changed) or not currently running
        let isCurrentlyMonitoring = center.activities.contains(Self.activityName)

        guard forceRestart || !isCurrentlyMonitoring else {
            // Monitoring is running and we shouldn't restart - just keep it going
            return
        }

        // Stop existing monitoring if running
        if isCurrentlyMonitoring {
            stopMonitoring()
        }

        // Start fresh monitoring if we have balance and apps to monitor
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
