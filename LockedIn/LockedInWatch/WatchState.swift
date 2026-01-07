//
//  WatchState.swift
//  LockedInWatch
//
//  Local state storage for Apple Watch.
//  Receives updates from iPhone via Watch Connectivity.
//  Widget reads from this state via UserDefaults.
//

import Foundation
import WidgetKit

@Observable
final class WatchState {
    static let shared = WatchState()

    // MARK: - Storage Keys

    private enum Keys {
        static let balance = "watch_balance"
        static let maxBalance = "watch_maxBalance"
        static let difficulty = "watch_difficulty"
        static let lastSync = "watch_lastSync"
    }

    // Use shared UserDefaults for app + widget extension access
    private static let appGroupID = "group.usdk.LockedIn.watchkit"
    private let defaults = UserDefaults(suiteName: WatchState.appGroupID) ?? UserDefaults.standard

    // MARK: - Properties

    var balance: Int {
        didSet {
            defaults.set(balance, forKey: Keys.balance)
            refreshWidget()
        }
    }

    var maxBalance: Int {
        didSet {
            defaults.set(maxBalance, forKey: Keys.maxBalance)
            refreshWidget()
        }
    }

    var difficulty: String {
        didSet {
            defaults.set(difficulty, forKey: Keys.difficulty)
            refreshWidget()
        }
    }

    var lastSync: Date? {
        didSet {
            if let date = lastSync {
                defaults.set(date.timeIntervalSince1970, forKey: Keys.lastSync)
            }
        }
    }

    var progress: Double {
        guard maxBalance > 0 else { return 0 }
        return min(1, Double(max(0, balance)) / Double(maxBalance))
    }

    // MARK: - Init

    private init() {
        // Load persisted values
        self.balance = defaults.integer(forKey: Keys.balance)
        self.maxBalance = defaults.integer(forKey: Keys.maxBalance)
        self.difficulty = defaults.string(forKey: Keys.difficulty) ?? "MEDIUM"

        let syncTimestamp = defaults.double(forKey: Keys.lastSync)
        self.lastSync = syncTimestamp > 0 ? Date(timeIntervalSince1970: syncTimestamp) : nil

        // Set defaults if first launch
        if maxBalance == 0 {
            maxBalance = 120  // Default for MEDIUM
        }
    }

    // MARK: - Update

    /// Update state from iPhone data
    func update(balance: Int, maxBalance: Int, difficulty: String) {
        self.balance = balance
        self.maxBalance = maxBalance
        self.difficulty = difficulty
        self.lastSync = Date()
        // Force immediate write to disk for widget access
        defaults.synchronize()
    }

    // MARK: - Widget Refresh

    private func refreshWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "LockedInWatchWidget")
    }
}

// MARK: - Static Access for Widget

extension WatchState {
    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
    }

    /// Read balance directly from UserDefaults (for widget timeline provider)
    static var storedBalance: Int {
        sharedDefaults.integer(forKey: Keys.balance)
    }

    static var storedMaxBalance: Int {
        let value = sharedDefaults.integer(forKey: Keys.maxBalance)
        return value > 0 ? value : 120
    }

    static var storedDifficulty: String {
        sharedDefaults.string(forKey: Keys.difficulty) ?? "MEDIUM"
    }

    static var storedProgress: Double {
        let balance = storedBalance
        let storedMax = storedMaxBalance
        guard storedMax > 0 else { return 0 }
        return min(1, Double(max(0, balance)) / Double(storedMax))
    }
}
