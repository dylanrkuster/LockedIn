//
//  DifficultyBadge.swift
//  LockedIn
//
//  Rank indicator using bars. Industrial. Earned.
//

import SwiftUI

struct DifficultyBadge: View {
    let difficulty: Difficulty

    private let totalBars = 4
    private let barWidth: CGFloat = 3
    private let barHeight: CGFloat = 14
    private let barSpacing: CGFloat = 3

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Rank bars
            HStack(spacing: barSpacing) {
                ForEach(0..<totalBars, id: \.self) { index in
                    Rectangle()
                        .fill(index < difficulty.barCount ? difficulty.color : AppColor.border)
                        .frame(width: barWidth, height: barHeight)
                }
            }

            // Difficulty label with ratio
            HStack(spacing: AppSpacing.xs) {
                Text(difficulty.rawValue)
                    .font(AppFont.label(10))
                    .tracking(2)
                    .foregroundStyle(difficulty.color)

                Text("·")
                    .font(AppFont.label(10))
                    .foregroundStyle(AppColor.textTertiary)

                Text(difficulty.ratioDisplay)
                    .font(AppFont.mono(10))
                    .foregroundStyle(AppColor.textTertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Difficulty \(difficulty.rawValue), ratio \(difficulty.ratioDisplay)")
    }
}

#Preview("Easy") {
    DifficultyBadge(difficulty: .easy)
        .padding()
        .background(Color.black)
}

#Preview("Medium") {
    DifficultyBadge(difficulty: .medium)
        .padding()
        .background(Color.black)
}

#Preview("Hard") {
    DifficultyBadge(difficulty: .hard)
        .padding()
        .background(Color.black)
}

#Preview("Extreme") {
    DifficultyBadge(difficulty: .extreme)
        .padding()
        .background(Color.black)
}
