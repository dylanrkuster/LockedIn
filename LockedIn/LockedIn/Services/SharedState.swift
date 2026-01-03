//
//  SharedState.swift
//  LockedIn (Shared)
//
//  Shared state between main app and extensions via App Groups.
//  This file should be added to ALL targets (main app + extensions).
//

import Foundation

/// App Groups shared state for cross-process data access
enum SharedState {
    static let suiteName = "group.usdk.LockedIn"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    // MARK: - Balance

    /// Current bank balance in minutes
    static var balance: Int {
        get { defaults.integer(forKey: Keys.balance) }
        set { defaults.set(newValue, forKey: Keys.balance) }
    }

    /// Starting balance for new users (60 minutes)
    static let defaultStartingBalance = 1 // fixme

    // MARK: - Difficulty

    /// Raw difficulty value for cross-process access
    static var difficultyRaw: String {
        get { defaults.string(forKey: Keys.difficulty) ?? "MEDIUM" }
        set { defaults.set(newValue, forKey: Keys.difficulty) }
    }

    /// Max balance based on current difficulty
    static var maxBalance: Int {
        switch difficultyRaw {
        case "EASY": return 240
        case "MEDIUM": return 180
        case "HARD": return 120
        case "EXTREME": return 60
        default: return 180
        }
    }

    // MARK: - App Selection

    /// Encoded FamilyActivitySelection data
    static var selectionData: Data? {
        get { defaults.data(forKey: Keys.selection) }
        set { defaults.set(newValue, forKey: Keys.selection) }
    }

    // MARK: - Monitoring State

    /// Whether DeviceActivity monitoring is active
    static var isMonitoring: Bool {
        get { defaults.bool(forKey: Keys.isMonitoring) }
        set { defaults.set(newValue, forKey: Keys.isMonitoring) }
    }

    /// Last time we checked/updated usage
    static var lastUsageCheck: Date? {
        get { defaults.object(forKey: Keys.lastUsageCheck) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastUsageCheck) }
    }

    // MARK: - Keys

    private enum Keys {
        static let balance = "balance"
        static let difficulty = "difficulty"
        static let selection = "selection"
        static let isMonitoring = "isMonitoring"
        static let lastUsageCheck = "lastUsageCheck"
    }

    // MARK: - Sync

    /// Force synchronize UserDefaults (call after critical writes)
    static func synchronize() {
        defaults.synchronize()
    }
}
