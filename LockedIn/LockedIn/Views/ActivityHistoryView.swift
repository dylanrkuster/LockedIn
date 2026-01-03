//
//  ActivityHistoryView.swift
//  LockedIn
//
//  The Ledger. Every minute, accounted for.
//

import SwiftUI

struct ActivityHistoryView: View {
    let transactions: [Transaction]
    let accentColor: Color
    let currentBalance: Int
    @Environment(\.dismiss) private var dismiss

    /// All consolidated transactions, grouped by date with running balance
    private var groupedLedger: [DayLedgerGroup] {
        let allItems = consolidateTransactions(transactions, limit: nil)
        let ledgerItems = calculateRunningBalance(items: allItems, currentBalance: currentBalance)
        return groupByDate(ledgerItems)
    }

    var body: some View {
        ZStack {
            AppColor.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.md)

                // Content
                if groupedLedger.isEmpty {
                    emptyState
                } else {
                    ledger
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .background(SwipeBackGestureEnabler())
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            // Centered title
            Text("ACTIVITY")
                .font(AppFont.label(12))
                .tracking(4)
                .foregroundStyle(AppColor.textPrimary)

            // Back button aligned left
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppColor.textTertiary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            VStack(spacing: AppSpacing.sm) {
                Text("NO ACTIVITY")
                    .font(AppFont.label(11))
                    .tracking(3)
                    .foregroundStyle(AppColor.textTertiary)

                Text("Transactions will appear here\nas you earn and spend minutes")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textTertiary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
    }

    // MARK: - Ledger

    private var ledger: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(groupedLedger.enumerated()), id: \.element.id) { index, group in
                    daySection(group, isFirst: index == 0)
                }

                // Bottom padding
                Spacer()
                    .frame(height: AppSpacing.xl)
            }
        }
    }

    private func daySection(_ group: DayLedgerGroup, isFirst: Bool) -> some View {
        VStack(spacing: 0) {
            // Day header with net
            dayHeader(group, isFirst: isFirst)

            // Transactions using unified LedgerRow
            VStack(spacing: AppSpacing.xs + 2) {
                ForEach(group.items) { item in
                    LedgerRow(item: item, accentColor: accentColor)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.md)
        }
    }

    private func dayHeader(_ group: DayLedgerGroup, isFirst: Bool) -> some View {
        VStack(spacing: 0) {
            // Divider (except for first section)
            if !isFirst {
                Rectangle()
                    .fill(AppColor.border)
                    .frame(height: 1)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.md)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(group.header)
                    .font(AppFont.label(11))
                    .tracking(2)
                    .foregroundStyle(AppColor.textSecondary)

                Spacer()

                // Daily net
                Text(formatNet(group.net))
                    .font(AppFont.mono(12))
                    .foregroundStyle(group.net >= 0 ? accentColor : AppColor.textTertiary)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, isFirst ? AppSpacing.sm : 0)
            .padding(.bottom, AppSpacing.sm)
        }
    }

    // MARK: - Formatting

    private func formatNet(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }

    // MARK: - Grouping

    private func groupByDate(_ items: [LedgerItem]) -> [DayLedgerGroup] {
        let calendar = Calendar.current

        var groups: [String: [LedgerItem]] = [:]
        var order: [String] = []

        for item in items {
            let key = dateKey(for: item.timestamp, calendar: calendar)
            if groups[key] == nil {
                order.append(key)
                groups[key] = []
            }
            groups[key]?.append(item)
        }

        return order.map { key in
            let items = groups[key] ?? []
            let net = items.reduce(0) { $0 + $1.amount }
            return DayLedgerGroup(header: key, items: items, net: net)
        }
    }

    private func dateKey(for date: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(date) {
            return "TODAY"
        } else if calendar.isDateInYesterday(date) {
            return "YESTERDAY"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date).uppercased()
        }
    }
}

// MARK: - Day Ledger Group

private struct DayLedgerGroup: Identifiable {
    let id = UUID()
    let header: String
    let items: [LedgerItem]
    let net: Int
}

// MARK: - Swipe Back Gesture Enabler

/// UIKit bridge to enable the native swipe-to-go-back gesture
/// when the navigation bar back button is hidden
struct SwipeBackGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        SwipeBackController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    private class SwipeBackController: UIViewController {
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            // Enable the interactive pop gesture
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}

// MARK: - Previews

#Preview("The Ledger") {
    NavigationStack {
        ActivityHistoryView(
            transactions: Transaction.designReviewMock,
            accentColor: AppColor.hard,
            currentBalance: 110
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        ActivityHistoryView(
            transactions: [],
            accentColor: AppColor.medium,
            currentBalance: 60
        )
    }
}

#Preview("Single Day") {
    NavigationStack {
        ActivityHistoryView(
            transactions: [
                Transaction(id: UUID(), amount: 30, source: "Run", timestamp: Date()),
                Transaction(id: UUID(), amount: -12, source: "TikTok", timestamp: Date().addingTimeInterval(-3600)),
            ],
            accentColor: AppColor.easy,
            currentBalance: 78
        )
    }
}
