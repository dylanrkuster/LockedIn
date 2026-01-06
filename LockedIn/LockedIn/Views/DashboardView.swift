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
    var onRefresh: (() async -> Void)?
    @State private var showActivityHistory = false
    @State private var showDebugLogs = false
    @State private var showDifficultyPicker = false
    @State private var showSettings = false
    @State private var isRefreshing = false

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
                        maxBalance: bankState.maxBalance,
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

                    // Today's summary stats
                    TodaySummary(
                        transactions: bankState.recentTransactions,
                        accentColor: bankState.difficulty.color
                    )
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.md)

                    // Footer sections
                    VStack(spacing: 0) {
                        // Divider
                        divider

                        // Activity (transaction history)
                        ActivitySection(
                            transactions: bankState.recentTransactions,
                            accentColor: bankState.difficulty.color,
                            currentBalance: bankState.balance,
                            onSeeAll: {
                                AnalyticsManager.track(.activityHistoryViewed)
                                showActivityHistory = true
                            }
                        )
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)

                        // Divider
                        divider

                        // Blocked apps
                        BlockedAppsSection(manager: familyControlsManager, accentColor: bankState.difficulty.color)
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

            // Sync workouts button
            Button {
                guard !isRefreshing else { return }
                HapticManager.impact()
                Task {
                    isRefreshing = true
                    await onRefresh?()
                    isRefreshing = false
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColor.textSecondary)
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(
                        isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                        value: isRefreshing
                    )
            }
            .disabled(isRefreshing)
            .padding(.trailing, AppSpacing.md)

            Button {
                AnalyticsManager.track(.settingsOpened)
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
    DashboardView(bankState: .mock, familyControlsManager: FamilyControlsManager(), onRefresh: nil)
}

#Preview("Low Balance - Extreme (12 min threshold)") {
    // Extreme: max 60, 20% = 12 min threshold
    DashboardView(
        bankState: BankState(
            balance: 12,
            difficulty: .extreme,
            transactions: [
                Transaction(id: UUID(), amount: -15, source: "TikTok", timestamp: Date().addingTimeInterval(-300))
            ]
        ),
        familyControlsManager: FamilyControlsManager(),
        onRefresh: nil
    )
}

#Preview("Full Balance") {
    DashboardView(
        bankState: BankState(
            balance: 240,
            difficulty: .easy,
            transactions: Transaction.mock
        ),
        familyControlsManager: FamilyControlsManager(),
        onRefresh: nil
    )
}
