//
//  BankState.swift
//  LockedIn
//

import Foundation

@Observable
final class BankState {
    var balance: Int
    var difficulty: Difficulty
    var blockedApps: [String]
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

    init(
        balance: Int,
        difficulty: Difficulty,
        blockedApps: [String] = [],
        transactions: [Transaction] = []
    ) {
        self.balance = max(0, min(balance, difficulty.maxBalance))
        self.difficulty = difficulty
        self.blockedApps = blockedApps
        self.transactions = transactions
    }
}

// MARK: - Mock Data

extension BankState {
    static let mock = BankState(
        balance: 47,
        difficulty: .hard,
        blockedApps: ["Instagram", "TikTok", "X", "Snapchat"],
        transactions: Transaction.mock
    )
}
