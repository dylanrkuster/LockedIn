//
//  TodaySummary.swift
//  LockedIn
//
//  Today's aggregate stats. Earned. Spent. Net. Simple.
//

import SwiftUI

struct TodaySummary: View {
    let transactions: [Transaction]
    let accentColor: Color

    private var todayStats: (earned: Int, spent: Int, net: Int) {
        let calendar = Calendar.current
        let today = Date()

        let todayTransactions = transactions.filter {
            calendar.isDateInToday($0.timestamp)
        }

        let earned = todayTransactions
            .filter { $0.amount > 0 }
            .reduce(0) { $0 + $1.amount }

        let spent = todayTransactions
            .filter { $0.amount < 0 }
            .reduce(0) { $0 + abs($1.amount) }

        return (earned: earned, spent: spent, net: earned - spent)
    }

    var body: some View {
        HStack {
            Text("TODAY")
                .font(AppFont.label(11))
                .tracking(3)
                .foregroundStyle(AppColor.textSecondary)

            Spacer()

            HStack(spacing: AppSpacing.lg) {
                // Earned (label + value)
                HStack(spacing: 4) {
                    Text("EARNED")
                        .font(AppFont.label(9))
                        .tracking(1)
                        .foregroundStyle(AppColor.textTertiary)
                    Text("+\(todayStats.earned)")
                        .font(AppFont.mono(12))
                        .foregroundStyle(accentColor)
                }

                // Spent (label + value)
                HStack(spacing: 4) {
                    Text("SPENT")
                        .font(AppFont.label(9))
                        .tracking(1)
                        .foregroundStyle(AppColor.textTertiary)
                    Text("\(todayStats.spent)")
                        .font(AppFont.mono(12))
                        .foregroundStyle(AppColor.textSecondary)
                }

                // Net (label + value)
                HStack(spacing: 4) {
                    Text("NET")
                        .font(AppFont.label(9))
                        .tracking(1)
                        .foregroundStyle(AppColor.textTertiary)
                    Text(netValueText)
                        .font(AppFont.mono(12))
                        .foregroundStyle(netColor)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var netValueText: String {
        let net = todayStats.net
        let prefix = net >= 0 ? "+" : ""
        return "\(prefix)\(net)"
    }

    private var netColor: Color {
        todayStats.net > 0 ? accentColor : AppColor.textSecondary
    }

    private var accessibilityLabel: String {
        let stats = todayStats
        return "Today: earned \(stats.earned) minutes, spent \(stats.spent) minutes, net \(stats.net) minutes"
    }
}

#Preview {
    TodaySummary(
        transactions: Transaction.mock,
        accentColor: AppColor.hard
    )
    .padding(.horizontal, 24)
    .padding(.vertical, 16)
    .background(Color.black)
}

#Preview("No Activity Today") {
    TodaySummary(
        transactions: [],
        accentColor: AppColor.medium
    )
    .padding(.horizontal, 24)
    .padding(.vertical, 16)
    .background(Color.black)
}

#Preview("Only Earned") {
    TodaySummary(
        transactions: [
            Transaction(id: UUID(), amount: 30, source: "Run", timestamp: Date()),
            Transaction(id: UUID(), amount: 15, source: "HIIT", timestamp: Date())
        ],
        accentColor: AppColor.easy
    )
    .padding(.horizontal, 24)
    .padding(.vertical, 16)
    .background(Color.black)
}

#Preview("Only Spent") {
    TodaySummary(
        transactions: [
            Transaction(id: UUID(), amount: -20, source: "TikTok", timestamp: Date()),
            Transaction(id: UUID(), amount: -15, source: "Instagram", timestamp: Date())
        ],
        accentColor: AppColor.extreme
    )
    .padding(.horizontal, 24)
    .padding(.vertical, 16)
    .background(Color.black)
}
