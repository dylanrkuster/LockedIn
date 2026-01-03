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
    /// Extended mock data for design review (multiple days)
    static var designReviewMock: [Transaction] {
        let now = Date()
        let calendar = Calendar.current

        // Today - net +20
        let today: [Transaction] = [
            Transaction(id: UUID(), amount: 30, source: "Run",
                       timestamp: calendar.date(bySettingHour: 7, minute: 15, second: 0, of: now)!),
            Transaction(id: UUID(), amount: -8, source: "Instagram",
                       timestamp: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: now)!),
            Transaction(id: UUID(), amount: -12, source: "TikTok",
                       timestamp: calendar.date(bySettingHour: 12, minute: 45, second: 0, of: now)!),
            Transaction(id: UUID(), amount: 15, source: "HIIT",
                       timestamp: calendar.date(bySettingHour: 17, minute: 30, second: 0, of: now)!),
            Transaction(id: UUID(), amount: -5, source: "X",
                       timestamp: calendar.date(bySettingHour: 20, minute: 15, second: 0, of: now)!),
        ]

        // Yesterday - net +28
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let yesterdayTx: [Transaction] = [
            Transaction(id: UUID(), amount: 45, source: "Cycling",
                       timestamp: calendar.date(bySettingHour: 6, minute: 30, second: 0, of: yesterday)!),
            Transaction(id: UUID(), amount: -15, source: "Instagram",
                       timestamp: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: yesterday)!),
            Transaction(id: UUID(), amount: -22, source: "YouTube",
                       timestamp: calendar.date(bySettingHour: 14, minute: 30, second: 0, of: yesterday)!),
            Transaction(id: UUID(), amount: 20, source: "Strength",
                       timestamp: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: yesterday)!),
        ]

        // 2 days ago - net +12
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now)!
        let twoDaysAgoTx: [Transaction] = [
            Transaction(id: UUID(), amount: 60, source: "Run",
                       timestamp: calendar.date(bySettingHour: 5, minute: 45, second: 0, of: twoDaysAgo)!),
            Transaction(id: UUID(), amount: -30, source: "TikTok",
                       timestamp: calendar.date(bySettingHour: 11, minute: 15, second: 0, of: twoDaysAgo)!),
            Transaction(id: UUID(), amount: -18, source: "Instagram",
                       timestamp: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: twoDaysAgo)!),
        ]

        // 3 days ago - net +20
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!
        let threeDaysAgoTx: [Transaction] = [
            Transaction(id: UUID(), amount: 25, source: "Walk",
                       timestamp: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: threeDaysAgo)!),
            Transaction(id: UUID(), amount: 35, source: "Yoga",
                       timestamp: calendar.date(bySettingHour: 18, minute: 30, second: 0, of: threeDaysAgo)!),
            Transaction(id: UUID(), amount: -40, source: "Netflix",
                       timestamp: calendar.date(bySettingHour: 21, minute: 0, second: 0, of: threeDaysAgo)!),
        ]

        // 5 days ago - net +30
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: now)!
        let fiveDaysAgoTx: [Transaction] = [
            Transaction(id: UUID(), amount: 90, source: "Run",
                       timestamp: calendar.date(bySettingHour: 6, minute: 0, second: 0, of: fiveDaysAgo)!),
            Transaction(id: UUID(), amount: -25, source: "X",
                       timestamp: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: fiveDaysAgo)!),
            Transaction(id: UUID(), amount: -15, source: "Reddit",
                       timestamp: calendar.date(bySettingHour: 16, minute: 45, second: 0, of: fiveDaysAgo)!),
            Transaction(id: UUID(), amount: -20, source: "Instagram",
                       timestamp: calendar.date(bySettingHour: 22, minute: 30, second: 0, of: fiveDaysAgo)!),
        ]

        return today + yesterdayTx + twoDaysAgoTx + threeDaysAgoTx + fiveDaysAgoTx
    }

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
