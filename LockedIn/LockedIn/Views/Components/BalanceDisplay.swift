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
    var onDifficultyTap: (() -> Void)?

    private var displayBalance: Int {
        max(0, balance)
    }

    private var accessibilityText: String {
        "\(displayBalance) minutes remaining. Difficulty: \(difficulty.rawValue)"
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // THE NUMBER - massive, commanding
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(displayBalance)")
                    .font(AppFont.balance)
                    .foregroundStyle(AppColor.textPrimary)
                    .monospacedDigit()

                Text("min")
                    .font(AppFont.mono(24))
                    .foregroundStyle(AppColor.textPrimary)
            }
            .accessibilityLabel(accessibilityText)

            // Label
            Text("SCREEN TIME REMAINING")
                .font(AppFont.label(12))
                .tracking(6)
                .foregroundStyle(AppColor.textSecondary)
                .accessibilityHidden(true)

            Spacer()
                .frame(height: AppSpacing.md)

            // Difficulty rank (tappable)
            DifficultyBadge(difficulty: difficulty, onTap: onDifficultyTap)
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
