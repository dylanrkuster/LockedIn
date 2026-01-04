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

    // MARK: - Cached Instances (Memory Optimization)

    /// Single UserDefaults instance per process (was creating new instance on every access)
    private static let defaults: UserDefaults = {
        guard let suite = UserDefaults(suiteName: suiteName) else {
            assertionFailure("App Groups UserDefaults not accessible!")
            return .standard
        }
        return suite
    }()

    /// Reusable JSON decoder (avoid allocation per decode)
    private static let jsonDecoder = JSONDecoder()

    /// Reusable JSON encoder (avoid allocation per encode)
    private static let jsonEncoder = JSONEncoder()

    /// Reusable PropertyList decoder for FamilyActivitySelection
    static let plistDecoder = PropertyListDecoder()

    /// Check if App Groups is properly accessible (use for debugging)
    static var isAppGroupAccessible: Bool {
        UserDefaults(suiteName: suiteName) != nil
    }

    /// Debug marker written by main app, readable by extensions
    static var debugMainAppMarker: String {
        get { defaults.string(forKey: Keys.debugMainAppMarker) ?? "not_set" }
        set { defaults.set(newValue, forKey: Keys.debugMainAppMarker) }
    }

    // MARK: - Balance

    /// Current bank balance in minutes
    static var balance: Int {
        get { defaults.integer(forKey: Keys.balance) }
        set { defaults.set(newValue, forKey: Keys.balance) }
    }

    /// Starting balance for new users (TEMP: 2 minutes for testing)
    static let defaultStartingBalance = 2

    /// Whether the app has been launched before (distinguishes fresh install from zero balance)
    static var hasLaunched: Bool {
        get { defaults.bool(forKey: Keys.hasLaunched) }
        set { defaults.set(newValue, forKey: Keys.hasLaunched) }
    }

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

    // MARK: - Transactions

    /// Persisted transaction history (7-day rolling window)
    /// Main app reads this; includes any pending transactions from extensions.
    static var transactions: [TransactionRecord] {
        get {
            var result: [TransactionRecord] = []

            // Get main transactions
            if let data = defaults.data(forKey: Keys.transactions),
               let decoded = try? jsonDecoder.decode([TransactionRecord].self, from: data) {
                result = decoded
            }

            // Include pending transactions (from extensions)
            result.append(contentsOf: pendingTransactions)

            return result.sorted { $0.timestamp > $1.timestamp }
        }
        set {
            // Only prune when array is large (reduces filter overhead)
            let toEncode: [TransactionRecord]
            if newValue.count > 500 {
                let cutoff = Date().addingTimeInterval(-7 * 24 * 60 * 60)
                toEncode = newValue.filter { $0.timestamp > cutoff }
            } else {
                toEncode = newValue
            }
            if let encoded = try? jsonEncoder.encode(toEncode) {
                defaults.set(encoded, forKey: Keys.transactions)
            }
        }
    }

    /// Pending transactions written by extensions (not yet merged)
    private static var pendingTransactions: [TransactionRecord] {
        get {
            guard let data = defaults.data(forKey: Keys.pendingTransactions),
                  let decoded = try? jsonDecoder.decode([TransactionRecord].self, from: data)
            else { return [] }
            return decoded
        }
        set {
            if let encoded = try? jsonEncoder.encode(newValue) {
                defaults.set(encoded, forKey: Keys.pendingTransactions)
            }
        }
    }

    /// Append a transaction efficiently (for extensions).
    /// Uses a small pending array to avoid decoding the full transaction history.
    static func appendTransaction(_ record: TransactionRecord) {
        var pending = pendingTransactions
        pending.append(record)
        pendingTransactions = pending
        synchronize()
    }

    /// Merge pending transactions into main array (call from main app on foreground).
    /// Also performs 7-day pruning.
    static func mergePendingTransactions() {
        let pending = pendingTransactions
        guard !pending.isEmpty else { return }

        // Read main transactions directly (skip pending in getter)
        var main: [TransactionRecord] = []
        if let data = defaults.data(forKey: Keys.transactions),
           let decoded = try? jsonDecoder.decode([TransactionRecord].self, from: data) {
            main = decoded
        }

        // Merge and prune
        main.append(contentsOf: pending)
        let cutoff = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let pruned = main.filter { $0.timestamp > cutoff }

        // Write merged transactions
        if let encoded = try? jsonEncoder.encode(pruned) {
            defaults.set(encoded, forKey: Keys.transactions)
        }

        // Clear pending
        defaults.removeObject(forKey: Keys.pendingTransactions)
        synchronize()
    }

    // MARK: - HealthKit Tracking

    /// UUIDs of workouts that have been processed (prevents double-counting)
    static var processedWorkoutIDs: Set<String> {
        get { Set(defaults.stringArray(forKey: Keys.processedWorkouts) ?? []) }
        set { defaults.set(Array(newValue), forKey: Keys.processedWorkouts) }
    }

    /// Mark a workout as processed
    static func markWorkoutProcessed(_ uuid: String) {
        var ids = processedWorkoutIDs
        ids.insert(uuid)
        processedWorkoutIDs = ids
        synchronize()
    }

    /// Last HealthKit sync timestamp
    static var lastHealthKitSync: Date? {
        get { defaults.object(forKey: Keys.lastHealthKitSync) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastHealthKitSync) }
    }

    // MARK: - App Usage Tracking (from DeviceActivityReport)

    /// Mapping of encoded ApplicationToken → display name
    /// Populated by DeviceActivityReportExtension
    static var appTokenToName: [String: String] {
        get {
            guard let data = defaults.data(forKey: Keys.appTokenToName),
                  let decoded = try? jsonDecoder.decode([String: String].self, from: data)
            else { return [:] }
            return decoded
        }
        set {
            if let encoded = try? jsonEncoder.encode(newValue) {
                defaults.set(encoded, forKey: Keys.appTokenToName)
            }
        }
    }

    /// Per-app usage records from DeviceActivityReport
    /// Used for displaying per-app breakdown in Activity section
    static var appUsageRecords: [AppUsageRecord] {
        get {
            guard let data = defaults.data(forKey: Keys.appUsageRecords),
                  let decoded = try? jsonDecoder.decode([AppUsageRecord].self, from: data)
            else { return [] }
            return decoded
        }
        set {
            if let encoded = try? jsonEncoder.encode(newValue) {
                defaults.set(encoded, forKey: Keys.appUsageRecords)
            }
        }
    }

    /// Last time DeviceActivityReport was synced
    static var lastUsageReportSync: Date? {
        get { defaults.object(forKey: Keys.lastUsageReportSync) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastUsageReportSync) }
    }

    /// Total usage minutes already processed/deducted today
    /// Reset at start of each day to avoid double-counting
    static var processedUsageMinutes: Int {
        get {
            // Check if stored date is today, otherwise reset
            let storedDate = defaults.object(forKey: Keys.processedUsageDate) as? Date
            let calendar = Calendar.current
            if let date = storedDate, calendar.isDateInToday(date) {
                return defaults.integer(forKey: Keys.processedUsageMinutes)
            }
            return 0  // New day, reset to 0
        }
        set {
            defaults.set(newValue, forKey: Keys.processedUsageMinutes)
            defaults.set(Date(), forKey: Keys.processedUsageDate)
        }
    }

    /// Total blocked app usage minutes tracked today via DeviceActivityMonitor
    /// This is used to set up threshold events correctly
    static var usedMinutesToday: Int {
        get {
            // Check if stored date is today, otherwise reset
            let storedDate = defaults.object(forKey: Keys.usedMinutesDate) as? Date
            let calendar = Calendar.current
            if let date = storedDate, calendar.isDateInToday(date) {
                return defaults.integer(forKey: Keys.usedMinutesToday)
            }
            return 0  // New day, reset to 0
        }
        set {
            defaults.set(newValue, forKey: Keys.usedMinutesToday)
            defaults.set(Date(), forKey: Keys.usedMinutesDate)
        }
    }

    /// Calculate total usage from today's app usage records
    static var totalUsageMinutesToday: Int {
        appUsageRecords
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.durationMinutes }
    }

    /// Look up app display name from encoded token
    static func appName(forTokenKey tokenKey: String) -> String? {
        appTokenToName[tokenKey]
    }

    // MARK: - Debug

    /// Debug counter to verify extension writes are reaching main app
    static var debugExtensionRunCount: Int {
        get { defaults.integer(forKey: Keys.debugExtensionRunCount) }
        set { defaults.set(newValue, forKey: Keys.debugExtensionRunCount) }
    }

    /// Debug message from extension
    static var debugExtensionMessage: String {
        get { defaults.string(forKey: Keys.debugExtensionMessage) ?? "none" }
        set { defaults.set(newValue, forKey: Keys.debugExtensionMessage) }
    }

    /// Extension heartbeat - updated every time extension fires a callback.
    /// Main app can check this to detect if extension has stopped responding.
    static var extensionHeartbeat: Date? {
        get { defaults.object(forKey: Keys.extensionHeartbeat) as? Date }
        set { defaults.set(newValue, forKey: Keys.extensionHeartbeat) }
    }

    /// Check if extension heartbeat is stale (>2 minutes old while monitoring is active)
    static var isExtensionHeartbeatStale: Bool {
        guard isMonitoring else { return false }
        guard let heartbeat = extensionHeartbeat else { return true }
        let staleThreshold: TimeInterval = 2 * 60 // 2 minutes
        return Date().timeIntervalSince(heartbeat) > staleThreshold
    }

    /// Update extension heartbeat to current time
    static func updateHeartbeat() {
        extensionHeartbeat = Date()
    }

    // MARK: - Keys

    private enum Keys {
        static let balance = "balance"
        static let hasLaunched = "hasLaunched"
        static let difficulty = "difficulty"
        static let selection = "selection"
        static let isMonitoring = "isMonitoring"
        static let lastUsageCheck = "lastUsageCheck"
        static let transactions = "transactions"
        static let pendingTransactions = "pendingTransactions"
        static let processedWorkouts = "processedWorkouts"
        static let lastHealthKitSync = "lastHealthKitSync"
        static let appTokenToName = "appTokenToName"
        static let appUsageRecords = "appUsageRecords"
        static let lastUsageReportSync = "lastUsageReportSync"
        static let processedUsageMinutes = "processedUsageMinutes"
        static let processedUsageDate = "processedUsageDate"
        static let usedMinutesToday = "usedMinutesToday"
        static let usedMinutesDate = "usedMinutesDate"
        static let debugExtensionRunCount = "debugExtensionRunCount"
        static let debugExtensionMessage = "debugExtensionMessage"
        static let debugMainAppMarker = "debugMainAppMarker"
        static let extensionHeartbeat = "extensionHeartbeat"
    }

    // MARK: - Sync

    /// Force synchronize UserDefaults (call after critical writes)
    static func synchronize() {
        defaults.synchronize()
    }

    // MARK: - Keychain-based Sharing (for report extension)

    /// Keychain access group - must include Team ID prefix to match entitlements
    /// The entitlement $(AppIdentifierPrefix)group.usdk.LockedIn expands to this
    private static let keychainAccessGroup = "2GDFC79M88.group.usdk.LockedIn"

    /// Write app usage data to Keychain (call from report extension)
    static func writeAppUsageToKeychain(_ apps: [String: Int]) {
        guard let data = try? jsonEncoder.encode(apps) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "appUsageData",
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecValueData as String: data
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }

    /// Read app usage data from Keychain (call from main app)
    static var appUsageFromKeychain: [String: Int] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "appUsageData",
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let apps = try? jsonDecoder.decode([String: Int].self, from: data)
        else { return [:] }

        return apps
    }

    /// Write timestamp to Keychain to verify cross-process communication
    static func writeKeychainTimestamp() {
        let timestamp = Date().timeIntervalSince1970
        guard let data = "\(timestamp)".data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "reportTimestamp",
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    /// Read timestamp from Keychain
    static var keychainTimestamp: String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "reportTimestamp",
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let str = String(data: data, encoding: .utf8)
        else { return "none" }

        return str
    }
}
