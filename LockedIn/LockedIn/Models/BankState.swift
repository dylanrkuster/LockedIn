//
//  BankState.swift
//  LockedIn
//
//  Core state model for the bank balance. Persists to SharedState
//  for access by extensions.
//

import Foundation

@Observable
final class BankState {
    var balance: Int {
        didSet {
            let clamped = max(0, min(balance, maxBalance))
            if balance != clamped {
                balance = clamped
            } else {
                // Persist to SharedState for extension access
                SharedState.balance = balance
                SharedState.synchronize()
            }
        }
    }

    var difficulty: Difficulty {
        didSet {
            // Persist to SharedState for extension access
            SharedState.difficultyRaw = difficulty.rawValue
            SharedState.synchronize()
            // Re-clamp balance if max changed
            balance = min(balance, maxBalance)
            // Update app icon to reflect new difficulty
            AppIconManager.updateIcon(for: difficulty)
        }
    }

    private(set) var transactions: [Transaction]

    var maxBalance: Int {
        difficulty.maxBalance
    }

    var progress: Double {
        guard maxBalance > 0 else { return 0 }
        return max(0, min(1, Double(balance) / Double(maxBalance)))
    }

    var isLocked: Bool {
        balance <= 0
    }

    /// Most recent transactions first
    var recentTransactions: [Transaction] {
        transactions.sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Init

    /// Initialize with explicit values (used for previews/testing)
    init(
        balance: Int,
        difficulty: Difficulty,
        transactions: [Transaction] = []
    ) {
        self.difficulty = difficulty
        self.balance = max(0, min(balance, difficulty.maxBalance))
        self.transactions = transactions

        // Sync to SharedState
        SharedState.balance = self.balance
        SharedState.difficultyRaw = self.difficulty.rawValue
        SharedState.synchronize()
    }

    /// Initialize from persisted SharedState (production use)
    convenience init() {
        let savedDifficulty = Difficulty(rawValue: SharedState.difficultyRaw) ?? .medium
        let savedBalance = SharedState.balance

        // Use saved balance if available, otherwise start with default
        let isFreshInstall = savedBalance <= 0
        let startingBalance = isFreshInstall ? SharedState.defaultStartingBalance : savedBalance

        // On fresh install, reset stale tracking data from App Groups
        if isFreshInstall {
            SharedState.usedMinutesToday = 0
            SharedState.transactions = []
            SharedState.synchronize()
        }

        // Load persisted transactions
        let savedTransactions = SharedState.transactions.map { $0.toTransaction() }

        self.init(
            balance: startingBalance,
            difficulty: savedDifficulty,
            transactions: savedTransactions
        )

        // Set initial app icon based on difficulty (only on first launch)
        AppIconManager.setInitialIconIfNeeded(for: savedDifficulty)
    }

    // MARK: - Balance Operations

    /// Add minutes to balance from a workout
    /// - Parameters:
    ///   - workoutMinutes: Duration of the workout in minutes
    ///   - source: Display name for the workout type (e.g., "Run", "HIIT")
    ///   - timestamp: When the workout ended (defaults to now)
    func earn(workoutMinutes: Int, source: String, timestamp: Date = Date()) {
        let earnedMinutes = Int(Double(workoutMinutes) * difficulty.screenMinutesPerWorkoutMinute)
        let actualEarned = min(earnedMinutes, maxBalance - balance)

        guard actualEarned > 0 else { return }

        let transaction = Transaction(
            id: UUID(),
            amount: actualEarned,
            source: source,
            timestamp: timestamp
        )
        transactions.append(transaction)
        balance += actualEarned

        // Persist transaction
        SharedState.appendTransaction(TransactionRecord(from: transaction))
    }

    /// Deduct minutes from balance (from app usage)
    /// - Parameters:
    ///   - minutes: Minutes to deduct
    ///   - source: App name or description
    ///   - timestamp: When the usage started (defaults to now)
    func spend(_ minutes: Int, source: String, timestamp: Date = Date()) {
        let spent = max(0, minutes)
        let actualSpent = min(spent, balance) // Can't go negative

        guard actualSpent > 0 else { return }

        let transaction = Transaction(
            id: UUID(),
            amount: -actualSpent,
            source: source,
            timestamp: timestamp
        )
        transactions.append(transaction)
        balance -= actualSpent

        // Persist transaction
        SharedState.appendTransaction(TransactionRecord(from: transaction))
    }

    /// Reload transactions from SharedState (call after extension updates)
    func reloadTransactions() {
        transactions = SharedState.transactions.map { $0.toTransaction() }
    }

    /// Sync both balance and transactions from SharedState
    /// Used when returning from background to pick up extension changes
    func syncFromSharedState() {
        // Temporarily disable didSet persistence by setting directly
        let sharedBalance = SharedState.balance
        let sharedTransactions = SharedState.transactions.map { $0.toTransaction() }

        // Update without triggering persistence (it's already persisted)
        self.transactions = sharedTransactions

        // Clamp to current difficulty max
        self.balance = max(0, min(sharedBalance, maxBalance))
    }
}

// MARK: - Mock Data (for Previews)

extension BankState {
    static let mock = BankState(
        balance: 47,
        difficulty: .hard,
        transactions: Transaction.mock
    )
}
