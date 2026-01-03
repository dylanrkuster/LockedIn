//
//  ActivitySection.swift
//  LockedIn
//
//  Transaction history. The story of your balance.
//

import SwiftUI

struct ActivitySection: View {
    let transactions: [Transaction]
    let accentColor: Color
    let currentBalance: Int
    var onSeeAll: (() -> Void)?

    private let maxVisible = 5

    /// Shows consolidated transactions with running balance
    private var ledgerItems: [LedgerItem] {
        let consolidated = consolidateTransactions(transactions, limit: maxVisible)
        return calculateRunningBalance(items: consolidated, currentBalance: currentBalance)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header with SEE ALL action
            HStack(alignment: .center) {
                Text("ACTIVITY")
                    .font(AppFont.label(11))
                    .tracking(3)
                    .foregroundStyle(AppColor.textSecondary)

                Spacer()

                if !transactions.isEmpty, let action = onSeeAll {
                    Button(action: action) {
                        Text("SEE ALL")
                            .font(AppFont.label(10))
                            .tracking(2)
                            .foregroundStyle(AppColor.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Activity list (always visible)
            VStack(alignment: .leading, spacing: AppSpacing.xs + 2) {
                if ledgerItems.isEmpty {
                    Text("No activity yet")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.textTertiary)
                } else {
                    ForEach(ledgerItems) { item in
                        LedgerRow(item: item, accentColor: accentColor)
                    }
                }
            }
        }
    }
}

// MARK: - Ledger Item (transaction + resulting balance)

struct LedgerItem: Identifiable {
    let id: UUID
    let amount: Int
    let source: String
    let timestamp: Date
    let balanceAfter: Int

    var isEarned: Bool { amount > 0 }

    var formattedAmount: String {
        amount >= 0 ? "+\(amount)" : "\(amount)"
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter.string(from: timestamp).lowercased()
    }
}

// MARK: - Ledger Row (unified format)

struct LedgerRow: View {
    let item: LedgerItem
    let accentColor: Color

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            // Amount (prominent, colored)
            Text(item.formattedAmount)
                .font(AppFont.mono(13))
                .foregroundStyle(item.isEarned ? accentColor : AppColor.textSecondary)
                .frame(width: 40, alignment: .leading)

            // Source
            Text(item.source)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)

            Spacer()

            // Timestamp
            Text(item.formattedTime)
                .font(AppFont.mono(11))
                .foregroundStyle(AppColor.textTertiary)

            // Balance after (the result)
            Text("→\(item.balanceAfter)")
                .font(AppFont.mono(11))
                .foregroundStyle(AppColor.textTertiary)
                .frame(width: 44, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.isEarned ? "Earned" : "Spent") \(abs(item.amount)) minutes on \(item.source), balance now \(item.balanceAfter)")
    }
}

// MARK: - Running Balance Calculation

/// Calculate balance after each transaction, working backwards from current balance
func calculateRunningBalance(items: [ActivityItem], currentBalance: Int) -> [LedgerItem] {
    var result: [LedgerItem] = []
    var runningBalance = currentBalance

    for item in items {
        result.append(LedgerItem(
            id: item.id,
            amount: item.amount,
            source: item.source,
            timestamp: item.timestamp,
            balanceAfter: runningBalance
        ))
        // Undo the transaction to get the balance before it
        runningBalance -= item.amount
    }

    return result
}

// MARK: - Transaction Consolidation (shared logic)

/// Consolidates sequential same-source spend transactions within 10 minutes
func consolidateTransactions(_ transactions: [Transaction], limit: Int? = nil) -> [ActivityItem] {
    // Sort transactions by timestamp (oldest first for grouping)
    let sorted = transactions.sorted { $0.timestamp < $1.timestamp }

    // Consolidate sequential transactions with same source within 10 minutes
    var consolidated: [ActivityItem] = []
    var currentGroup: (source: String, amount: Int, startTime: Date, endTime: Date)?

    for tx in sorted {
        if let group = currentGroup {
            // Check if this transaction should be grouped
            let timeDiff = tx.timestamp.timeIntervalSince(group.endTime)
            let sameSource = tx.source == group.source
            let bothSpends = tx.amount < 0 && group.amount < 0

            if sameSource && bothSpends && timeDiff < 600 { // Within 10 minutes
                // Add to current group
                currentGroup = (group.source, group.amount + tx.amount, group.startTime, tx.timestamp)
            } else {
                // Finalize current group and start new one
                consolidated.append(ActivityItem.consolidated(
                    amount: group.amount,
                    source: group.source,
                    timestamp: group.startTime
                ))
                currentGroup = (tx.source, tx.amount, tx.timestamp, tx.timestamp)
            }
        } else {
            // Start first group
            currentGroup = (tx.source, tx.amount, tx.timestamp, tx.timestamp)
        }
    }

    // Finalize last group
    if let group = currentGroup {
        consolidated.append(ActivityItem.consolidated(
            amount: group.amount,
            source: group.source,
            timestamp: group.startTime
        ))
    }

    // Sort by timestamp (most recent first) and optionally limit
    let sorted_result = consolidated.sorted { $0.timestamp > $1.timestamp }
    if let limit = limit {
        return Array(sorted_result.prefix(limit))
    }
    return sorted_result
}

// MARK: - Activity Item (for consolidation)

enum ActivityItem: Identifiable {
    case transaction(Transaction)
    case consolidated(amount: Int, source: String, timestamp: Date)

    var id: UUID {
        switch self {
        case .transaction(let tx):
            return tx.id
        case .consolidated(let amount, let source, let timestamp):
            // Generate stable ID from content hash
            let hash = "\(timestamp.timeIntervalSince1970)-\(source)-\(amount)".hashValue
            return UUID(uuidString: String(format: "%08X-0000-0000-0000-000000000000",
                                           UInt32(bitPattern: Int32(truncatingIfNeeded: hash)))) ?? UUID()
        }
    }

    var timestamp: Date {
        switch self {
        case .transaction(let tx): tx.timestamp
        case .consolidated(_, _, let ts): ts
        }
    }

    var amount: Int {
        switch self {
        case .transaction(let tx): tx.amount
        case .consolidated(let amt, _, _): amt
        }
    }

    var source: String {
        switch self {
        case .transaction(let tx): tx.source
        case .consolidated(_, let src, _): src
        }
    }

    var isEarned: Bool { amount > 0 }
}

// MARK: - Previews

#Preview {
    ActivitySection(
        transactions: Transaction.mock,
        accentColor: AppColor.hard,
        currentBalance: 47,
        onSeeAll: { print("See all tapped") }
    )
    .padding(24)
    .background(Color.black)
}

#Preview("Empty") {
    ActivitySection(
        transactions: [],
        accentColor: AppColor.medium,
        currentBalance: 60
    )
    .padding(24)
    .background(Color.black)
}

#Preview("Ledger Row") {
    VStack(spacing: 8) {
        LedgerRow(
            item: LedgerItem(
                id: UUID(),
                amount: 30,
                source: "Run",
                timestamp: Date(),
                balanceAfter: 90
            ),
            accentColor: AppColor.hard
        )
        LedgerRow(
            item: LedgerItem(
                id: UUID(),
                amount: -12,
                source: "Instagram",
                timestamp: Date().addingTimeInterval(-3600),
                balanceAfter: 60
            ),
            accentColor: AppColor.hard
        )
    }
    .padding(24)
    .background(Color.black)
}
