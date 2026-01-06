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

    /// Starting balance for new users (60 minutes = 1 hour)
    static let defaultStartingBalance = 60

    /// Whether the app has been launched before (distinguishes fresh install from zero balance)
    static var hasLaunched: Bool {
        get { defaults.bool(forKey: Keys.hasLaunched) }
        set { defaults.set(newValue, forKey: Keys.hasLaunched) }
    }

    /// Whether user has completed onboarding (show dashboard vs onboarding)
    static var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
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

    /// Timestamp when monitoring started (for calibration window)
    static var monitoringStartedAt: TimeInterval {
        get { defaults.double(forKey: Keys.monitoringStartedAt) }
        set { defaults.set(newValue, forKey: Keys.monitoringStartedAt) }
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
    ///
    /// IMPORTANT: This uses ID-based removal to prevent race conditions.
    /// If extension appends a new transaction while we're merging, it won't be lost.
    static func mergePendingTransactions() {
        let pending = pendingTransactions
        guard !pending.isEmpty else { return }

        // Capture the IDs of transactions we're about to merge
        let pendingIDs = Set(pending.map { $0.id })

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

        // Re-read pending and only remove the specific IDs we processed.
        // This preserves any transactions the extension added while we were merging.
        var currentPending = pendingTransactions
        let countBefore = currentPending.count
        currentPending.removeAll { pendingIDs.contains($0.id) }

        if currentPending.isEmpty {
            defaults.removeObject(forKey: Keys.pendingTransactions)
        } else {
            // Some new transactions arrived during merge - preserve them
            pendingTransactions = currentPending
        }

        synchronize()

        // Log if we preserved transactions (useful for debugging)
        if !currentPending.isEmpty {
            let preserved = currentPending.count
            let merged = countBefore - preserved
            print("[SharedState] Merged \(merged) transactions, preserved \(preserved) new arrivals")
        }
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

    // MARK: - App Store Review

    /// Total workouts processed (for review prompt trigger)
    static var workoutCount: Int {
        get { defaults.integer(forKey: Keys.workoutCount) }
        set { defaults.set(newValue, forKey: Keys.workoutCount) }
    }

    /// Whether we've already prompted for App Store review
    static var hasPromptedReview: Bool {
        get { defaults.bool(forKey: Keys.hasPromptedReview) }
        set { defaults.set(newValue, forKey: Keys.hasPromptedReview) }
    }

    // MARK: - Analytics

    /// Install date for calculating days_since_install
    static var installDate: Date? {
        get { defaults.object(forKey: Keys.installDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.installDate) }
    }

    /// Days since app was installed
    static var daysSinceInstall: Int {
        guard let install = installDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: install, to: Date()).day ?? 0
    }

    /// Whether first_block_hit event has been recorded (fires only once ever)
    static var firstBlockHitRecorded: Bool {
        get { defaults.bool(forKey: Keys.firstBlockHitRecorded) }
        set { defaults.set(newValue, forKey: Keys.firstBlockHitRecorded) }
    }

    /// Shield display count from extension (incremented by ShieldConfigurationExtension)
    static var shieldDisplayCount: Int {
        get { defaults.integer(forKey: Keys.shieldDisplayCount) }
        set { defaults.set(newValue, forKey: Keys.shieldDisplayCount) }
    }

    /// Last known shield display count (for calculating delta in main app)
    static var lastKnownShieldDisplayCount: Int {
        get { defaults.integer(forKey: Keys.lastKnownShieldDisplayCount) }
        set { defaults.set(newValue, forKey: Keys.lastKnownShieldDisplayCount) }
    }

    /// Last known app build version. Used to detect app updates/reinstalls
    /// and force-restart DeviceActivity monitoring when the extension binary changes.
    static var lastKnownBuildVersion: String? {
        get { defaults.string(forKey: Keys.lastKnownBuildVersion) }
        set { defaults.set(newValue, forKey: Keys.lastKnownBuildVersion) }
    }

    // MARK: - Notification Settings

    /// Whether to notify at 5 min remaining (default: true)
    static var notify5MinWarning: Bool {
        get { defaults.object(forKey: Keys.notify5Min) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.notify5Min) }
    }

    /// Whether to notify at 15 min remaining (default: false)
    static var notify15MinWarning: Bool {
        get { defaults.object(forKey: Keys.notify15Min) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Keys.notify15Min) }
    }

    /// Whether to notify when workout syncs (default: true)
    static var notifyWorkoutSync: Bool {
        get { defaults.object(forKey: Keys.notifyWorkout) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.notifyWorkout) }
    }

    /// Whether 5 min notification already sent today (prevents spam)
    static var notified5MinToday: Bool {
        get {
            let storedDate = defaults.object(forKey: Keys.notified5MinDate) as? Date
            guard let date = storedDate, Calendar.current.isDateInToday(date) else {
                return false  // New day, reset
            }
            return defaults.bool(forKey: Keys.notified5MinToday)
        }
        set {
            defaults.set(newValue, forKey: Keys.notified5MinToday)
            defaults.set(Date(), forKey: Keys.notified5MinDate)
        }
    }

    /// Whether 15 min notification already sent today (prevents spam)
    static var notified15MinToday: Bool {
        get {
            let storedDate = defaults.object(forKey: Keys.notified15MinDate) as? Date
            guard let date = storedDate, Calendar.current.isDateInToday(date) else {
                return false  // New day, reset
            }
            return defaults.bool(forKey: Keys.notified15MinToday)
        }
        set {
            defaults.set(newValue, forKey: Keys.notified15MinToday)
            defaults.set(Date(), forKey: Keys.notified15MinDate)
        }
    }

    /// Reset notification flags when balance goes above thresholds (after workout)
    static func resetNotificationFlags(for balance: Int) {
        if balance > 5 {
            notified5MinToday = false
        }
        if balance > 15 {
            notified15MinToday = false
        }
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

    // MARK: - Inter-Process Locking

    /// File URL for balance lock (inter-process synchronization)
    private static let balanceLockURL: URL? = {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: suiteName
        ) else { return nil }
        return containerURL.appendingPathComponent(".balance.lock")
    }()

    /// Execute a closure with an exclusive inter-process lock on balance operations.
    /// This prevents race conditions between main app and extensions when modifying balance.
    /// - Parameter operation: The operation to perform while holding the lock
    /// - Returns: The result of the operation
    static func withBalanceLock<T>(_ operation: () -> T) -> T {
        guard let lockURL = balanceLockURL else {
            // Fallback: execute without lock if container not available
            return operation()
        }

        // Create lock file if it doesn't exist
        if !FileManager.default.fileExists(atPath: lockURL.path) {
            FileManager.default.createFile(atPath: lockURL.path, contents: nil)
        }

        let fd = open(lockURL.path, O_RDWR)
        guard fd >= 0 else {
            // Fallback: execute without lock if file can't be opened
            return operation()
        }
        defer { close(fd) }

        // Acquire exclusive lock (blocks until available)
        flock(fd, LOCK_EX)
        defer { flock(fd, LOCK_UN) }

        return operation()
    }

    /// Atomically add to balance (read-modify-write with lock).
    /// Use this instead of directly setting balance when adding earned minutes.
    /// - Parameters:
    ///   - amount: Minutes to add (positive) or subtract (negative)
    ///   - maxBalance: Maximum allowed balance (for capping)
    /// - Returns: The new balance after the operation
    @discardableResult
    static func atomicBalanceAdd(_ amount: Int, maxBalance: Int) -> Int {
        withBalanceLock {
            let current = balance
            let newBalance = max(0, min(current + amount, maxBalance))
            balance = newBalance
            synchronize()
            return newBalance
        }
    }

    /// Atomically set balance with lock protection.
    /// Use this when setting balance from extension to prevent races.
    static func atomicBalanceSet(_ newBalance: Int) {
        withBalanceLock {
            balance = newBalance
            synchronize()
        }
    }

    // MARK: - Keys

    private enum Keys {
        static let balance = "balance"
        static let hasLaunched = "hasLaunched"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let difficulty = "difficulty"
        static let selection = "selection"
        static let isMonitoring = "isMonitoring"
        static let monitoringStartedAt = "monitoringStartedAt"
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

        // Notification settings
        static let notify5Min = "notify5Min"
        static let notify15Min = "notify15Min"
        static let notifyWorkout = "notifyWorkout"
        static let notified5MinToday = "notified5MinToday"
        static let notified5MinDate = "notified5MinDate"
        static let notified15MinToday = "notified15MinToday"
        static let notified15MinDate = "notified15MinDate"

        // App Store review
        static let workoutCount = "workoutCount"
        static let hasPromptedReview = "hasPromptedReview"

        // Analytics
        static let installDate = "installDate"
        static let firstBlockHitRecorded = "firstBlockHitRecorded"
        static let shieldDisplayCount = "shieldDisplayCount"
        static let lastKnownShieldDisplayCount = "lastKnownShieldDisplayCount"
        static let lastKnownBuildVersion = "lastKnownBuildVersion"
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
