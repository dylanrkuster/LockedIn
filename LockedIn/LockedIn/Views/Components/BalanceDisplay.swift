//
//  BalanceDisplay.swift
//  LockedIn
//
//  The vault. Your earned minutes. Precious.
//

import SwiftUI

struct BalanceDisplay: View {
    let balance: Int
    let difficulty: Difficulty

    private var displayBalance: Int {
        max(0, balance)
    }

    private var accessibilityText: String {
        "\(displayBalance) minutes remaining. Difficulty: \(difficulty.rawValue)"
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // THE NUMBER - massive, commanding
            Text("\(displayBalance)")
                .font(AppFont.balance)
                .foregroundStyle(AppColor.textPrimary)
                .monospacedDigit()
                .accessibilityLabel(accessibilityText)

            // Label
            Text("REMAINING")
                .font(AppFont.label(12))
                .tracking(6)
                .foregroundStyle(AppColor.textSecondary)
                .accessibilityHidden(true)

            Spacer()
                .frame(height: AppSpacing.lg)

            // Difficulty rank
            DifficultyBadge(difficulty: difficulty)
        }
    }
}

#Preview {
    BalanceDisplay(balance: 47, difficulty: .hard)
        .padding()
        .background(Color.black)
}

#Preview("Zero") {
    BalanceDisplay(balance: 0, difficulty: .extreme)
        .padding()
        .background(Color.black)
}

#Preview("High Balance") {
    BalanceDisplay(balance: 187, difficulty: .easy)
        .padding()
        .background(Color.black)
}
