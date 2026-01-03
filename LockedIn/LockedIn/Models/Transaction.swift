//
//  Transaction.swift
//  LockedIn
//
//  A record of time earned or spent. The story of your balance.
//

import Foundation

struct Transaction: Identifiable {
    let id: UUID
    let amount: Int      // positive = earned, negative = spent
    let source: String   // "Workout", "Instagram", etc.
    let timestamp: Date

    var isEarned: Bool { amount > 0 }

    /// Formats timestamp as concise date/time: "7:37pm" for today, "1/2 7:37pm" for older
    var formattedTimestamp: String {
        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mma"
        timeFormatter.amSymbol = "am"
        timeFormatter.pmSymbol = "pm"

        if calendar.isDateInToday(timestamp) {
            return timeFormatter.string(from: timestamp)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d h:mma"
            dateFormatter.amSymbol = "am"
            dateFormatter.pmSymbol = "pm"
            return dateFormatter.string(from: timestamp)
        }
    }

    /// Formatted amount with sign: "+15" or "-25"
    var formattedAmount: String {
        if amount >= 0 {
            return "+\(amount)"
        } else {
            return "\(amount)"
        }
    }
}

// MARK: - Mock Data

extension Transaction {
    /// Realistic mock data for HARD difficulty (2:1 ratio)
    /// - Workouts: 60 min workout → 30 earned, 30 min workout → 15 earned
    /// - Spending: 1:1 (time spent = minutes deducted)
    static let mock: [Transaction] = [
        Transaction(
            id: UUID(),
            amount: 15,
            source: "Workout",
            timestamp: Date().addingTimeInterval(-300)      // 5m ago
        ),
        Transaction(
            id: UUID(),
            amount: -12,
            source: "Instagram",
            timestamp: Date().addingTimeInterval(-720)      // 12m ago
        ),
        Transaction(
            id: UUID(),
            amount: -25,
            source: "X",
            timestamp: Date().addingTimeInterval(-2700)     // 45m ago
        ),
        Transaction(
            id: UUID(),
            amount: 30,
            source: "Workout",
            timestamp: Date().addingTimeInterval(-7200)     // 2h ago
        ),
        Transaction(
            id: UUID(),
            amount: -8,
            source: "TikTok",
            timestamp: Date().addingTimeInterval(-10800)    // 3h ago
        ),
        Transaction(
            id: UUID(),
            amount: -18,
            source: "Snapchat",
            timestamp: Date().addingTimeInterval(-14400)    // 4h ago
        ),
        Transaction(
            id: UUID(),
            amount: 45,
            source: "Workout",
            timestamp: Date().addingTimeInterval(-28800)    // 8h ago
        ),
        Transaction(
            id: UUID(),
            amount: -30,
            source: "Instagram",
            timestamp: Date().addingTimeInterval(-43200)    // 12h ago
        ),
        Transaction(
            id: UUID(),
            amount: -15,
            source: "X",
            timestamp: Date().addingTimeInterval(-64800)    // 18h ago
        ),
        Transaction(
            id: UUID(),
            amount: 20,
            source: "Workout",
            timestamp: Date().addingTimeInterval(-86400)    // 1d ago
        ),
    ]
}
