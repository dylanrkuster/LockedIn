//
//  DashboardView.swift
//  LockedIn
//
//  The vault. Brutalist. Functional. Beautiful through restraint.
//

import SwiftUI

struct DashboardView: View {
    let bankState: BankState

    var body: some View {
        ZStack {
            // Pure black canvas
            AppColor.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.md)

                Spacer()

                // The Vault - center of attention
                BalanceDisplay(
                    balance: bankState.balance,
                    difficulty: bankState.difficulty
                )

                Spacer()

                // Progress gauge
                ProgressBar(
                    current: bankState.balance,
                    max: bankState.maxBalance,
                    accentColor: bankState.difficulty.color
                )
                .padding(.horizontal, AppSpacing.xxl)

                Spacer()
                    .frame(height: AppSpacing.xl)

                // Footer sections
                VStack(spacing: 0) {
                    // Divider
                    divider

                    // Activity (transaction history)
                    ActivitySection(
                        transactions: bankState.recentTransactions,
                        accentColor: bankState.difficulty.color
                    )
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.md)

                    // Divider
                    divider

                    // Blocked apps
                    BlockedAppsSection(apps: bankState.blockedApps) {
                        // TODO: Present FamilyActivityPicker when FamilyControls is integrated
                        print("Edit blocked apps tapped")
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.md)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("LOCKEDIN")
                .font(.system(size: 13, weight: .bold, design: .default))
                .tracking(4)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            Button {
                // Settings - not implemented
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(AppColor.textTertiary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Settings")
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(AppColor.border)
            .frame(height: 1)
            .padding(.horizontal, AppSpacing.lg)
    }
}

#Preview {
    DashboardView(bankState: .mock)
}

#Preview("Low Balance") {
    DashboardView(bankState: BankState(
        balance: 5,
        difficulty: .extreme,
        blockedApps: ["Instagram", "TikTok"],
        transactions: [
            Transaction(id: UUID(), amount: -15, source: "TikTok", timestamp: Date().addingTimeInterval(-300))
        ]
    ))
}

#Preview("Full Balance") {
    DashboardView(bankState: BankState(
        balance: 240,
        difficulty: .easy,
        blockedApps: ["Instagram"],
        transactions: Transaction.mock
    ))
}
