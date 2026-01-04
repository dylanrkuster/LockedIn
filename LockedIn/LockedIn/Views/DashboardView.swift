//
//  DashboardView.swift
//  LockedIn
//
//  The vault. Brutalist. Functional. Beautiful through restraint.
//

import SwiftUI

struct DashboardView: View {
    let bankState: BankState
    @Bindable var familyControlsManager: FamilyControlsManager
    @State private var showActivityHistory = false
    @State private var showDebugLogs = false
    @State private var showDifficultyPicker = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
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
                        difficulty: bankState.difficulty,
                        onDifficultyTap: { showDifficultyPicker = true }
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
                            accentColor: bankState.difficulty.color,
                            currentBalance: bankState.balance,
                            onSeeAll: { showActivityHistory = true }
                        )
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)

                        // Divider
                        divider

                        // Blocked apps
                        BlockedAppsSection(manager: familyControlsManager)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.md)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showActivityHistory) {
                ActivityHistoryView(
                    transactions: bankState.recentTransactions,
                    accentColor: bankState.difficulty.color,
                    currentBalance: bankState.balance
                )
            }
            .navigationDestination(isPresented: $showDebugLogs) {
                DebugLogView()
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView(accentColor: bankState.difficulty.color)
            }
            .sheet(isPresented: $showDifficultyPicker) {
                DifficultyPickerSheet(
                    currentDifficulty: bankState.difficulty,
                    currentBalance: bankState.balance,
                    onSelect: { newDifficulty in
                        bankState.difficulty = newDifficulty
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
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
                .onLongPressGesture(minimumDuration: 3.0) {
                    showDebugLogs = true
                }

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColor.textSecondary)
            }
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
    DashboardView(bankState: .mock, familyControlsManager: FamilyControlsManager())
}

#Preview("Low Balance") {
    DashboardView(
        bankState: BankState(
            balance: 5,
            difficulty: .extreme,
            transactions: [
                Transaction(id: UUID(), amount: -15, source: "TikTok", timestamp: Date().addingTimeInterval(-300))
            ]
        ),
        familyControlsManager: FamilyControlsManager()
    )
}

#Preview("Full Balance") {
    DashboardView(
        bankState: BankState(
            balance: 240,
            difficulty: .easy,
            transactions: Transaction.mock
        ),
        familyControlsManager: FamilyControlsManager()
    )
}
