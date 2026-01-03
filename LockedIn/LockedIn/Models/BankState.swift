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
        }
    }

    var transactions: [Transaction]

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
        let startingBalance = savedBalance > 0 ? savedBalance : SharedState.defaultStartingBalance

        self.init(
            balance: startingBalance,
            difficulty: savedDifficulty,
            transactions: []
        )
    }

    // MARK: - Balance Operations

    /// Add minutes to balance (from workout)
    func earn(_ minutes: Int) {
        let earned = max(0, minutes)
        let newBalance = min(balance + earned, maxBalance)
        if newBalance > balance {
            transactions.append(Transaction(
                id: UUID(),
                amount: newBalance - balance,
                source: "Workout",
                timestamp: Date()
            ))
            balance = newBalance
        }
    }

    /// Deduct minutes from balance (from app usage)
    func spend(_ minutes: Int, source: String) {
        let spent = max(0, minutes)
        let newBalance = max(0, balance - spent)
        if newBalance < balance {
            transactions.append(Transaction(
                id: UUID(),
                amount: -(balance - newBalance),
                source: source,
                timestamp: Date()
            ))
            balance = newBalance
        }
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
