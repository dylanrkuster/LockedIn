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
    @State private var isExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let maxVisible = 8

    private var visibleTransactions: [Transaction] {
        Array(transactions.prefix(maxVisible))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header - full row is tappable
            Button {
                if reduceMotion {
                    isExpanded.toggle()
                } else {
                    withAnimation(.easeOut(duration: 0.15)) {
                        isExpanded.toggle()
                    }
                }
            } label: {
                HStack(alignment: .center) {
                    Text("ACTIVITY")
                        .font(AppFont.label(11))
                        .tracking(3)
                        .foregroundStyle(AppColor.textSecondary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppColor.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(isExpanded ? "Collapse" : "Expand")

            // Transaction list
            if isExpanded {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    if transactions.isEmpty {
                        Text("No activity yet")
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.textTertiary)
                    } else {
                        ForEach(visibleTransactions) { transaction in
                            TransactionRow(
                                transaction: transaction,
                                accentColor: accentColor
                            )
                        }
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: Transaction
    let accentColor: Color

    private var amountColor: Color {
        transaction.isEarned ? accentColor : AppColor.textTertiary
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            // Amount
            Text(transaction.formattedAmount)
                .font(AppFont.mono(13))
                .foregroundStyle(amountColor)
                .frame(width: 44, alignment: .leading)

            // Source
            Text(transaction.source)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)

            Spacer()

            // Timestamp
            Text(transaction.formattedTimestamp)
                .font(AppFont.mono(11))
                .foregroundStyle(AppColor.textTertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(transaction.isEarned ? "Earned" : "Spent") \(abs(transaction.amount)) minutes on \(transaction.source), at \(transaction.formattedTimestamp)")
    }
}

// MARK: - Previews

#Preview {
    ActivitySection(
        transactions: Transaction.mock,
        accentColor: AppColor.hard
    )
    .padding(24)
    .background(Color.black)
}

#Preview("Empty") {
    ActivitySection(
        transactions: [],
        accentColor: AppColor.medium
    )
    .padding(24)
    .background(Color.black)
}

#Preview("Single Transaction") {
    TransactionRow(
        transaction: Transaction(
            id: UUID(),
            amount: 15,
            source: "Workout",
            timestamp: Date().addingTimeInterval(-3600)
        ),
        accentColor: AppColor.hard
    )
    .padding(24)
    .background(Color.black)
}
