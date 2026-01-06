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

    /// Low balance threshold for warning state (matches 5-min notification)
    private static let lowBalanceThreshold = 5

    /// Animation state for low balance pulse
    @State private var isPulsing = false

    private var displayBalance: Int {
        max(0, balance)
    }

    private var isLowBalance: Bool {
        displayBalance <= Self.lowBalanceThreshold
    }

    private var accessibilityText: String {
        "\(displayBalance) minutes remaining. Difficulty: \(difficulty.rawValue)"
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // THE NUMBER - massive, commanding
            // Pulses slowly when balance is critically low
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(displayBalance)")
                    .font(AppFont.balance)
                    .foregroundStyle(AppColor.textPrimary)
                    .monospacedDigit()
                    .opacity(isPulsing && isLowBalance ? 0.6 : 1.0)
                    .animation(
                        isLowBalance
                            ? .easeInOut(duration: 1.25).repeatForever(autoreverses: true)
                            : .default,
                        value: isPulsing
                    )

                Text("min")
                    .font(AppFont.mono(24))
                    .foregroundStyle(AppColor.textPrimary)
                    .opacity(isPulsing && isLowBalance ? 0.6 : 1.0)
                    .animation(
                        isLowBalance
                            ? .easeInOut(duration: 1.25).repeatForever(autoreverses: true)
                            : .default,
                        value: isPulsing
                    )
            }
            .accessibilityLabel(accessibilityText)
            .onAppear {
                if isLowBalance {
                    isPulsing = true
                }
            }
            .onChange(of: isLowBalance) { _, newValue in
                // Start or stop pulse when crossing threshold
                isPulsing = newValue
            }

            // Label
            Text("SCREEN TIME REMAINING")
                .font(AppFont.label(12))
                .tracking(6)
                .foregroundStyle(AppColor.textSecondary)
                .accessibilityHidden(true)

            Spacer()
                .frame(height: AppSpacing.lg)

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

#Preview("Low Balance (5 min)") {
    BalanceDisplay(balance: 5, difficulty: .hard)
        .padding()
        .background(Color.black)
}

#Preview("Just Above Threshold (6 min)") {
    BalanceDisplay(balance: 6, difficulty: .hard)
        .padding()
        .background(Color.black)
}

#Preview("High Balance") {
    BalanceDisplay(balance: 187, difficulty: .easy)
        .padding()
        .background(Color.black)
}
