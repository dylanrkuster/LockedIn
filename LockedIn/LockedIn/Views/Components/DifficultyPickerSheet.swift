//
//  DifficultyPickerSheet.swift
//  LockedIn
//
//  Difficulty selection sheet. Change your commitment level.
//

import SwiftUI

struct DifficultyPickerSheet: View {
    let currentDifficulty: Difficulty
    let currentBalance: Int
    let onSelect: (Difficulty) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pendingDifficulty: Difficulty?

    private func minutesLost(for difficulty: Difficulty) -> Int {
        max(0, currentBalance - difficulty.maxBalance)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.md)

            // Difficulty options
            VStack(spacing: AppSpacing.sm) {
                ForEach(Difficulty.allCases) { difficulty in
                    DifficultyOptionRow(
                        difficulty: difficulty,
                        isSelected: difficulty == currentDifficulty,
                        willLoseMinutes: minutesLost(for: difficulty) > 0
                    )
                    .onTapGesture {
                        HapticManager.selection()
                        handleSelection(difficulty)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)

            Spacer()
        }
        .background(AppColor.background)
        .alert(
            "Change Difficulty?",
            isPresented: Binding(
                get: { pendingDifficulty != nil },
                set: { if !$0 { pendingDifficulty = nil } }
            ),
            presenting: pendingDifficulty
        ) { difficulty in
            Button("Cancel", role: .cancel) {
                pendingDifficulty = nil
            }
            Button("Change", role: .destructive) {
                HapticManager.notification(.warning)
                onSelect(difficulty)
                dismiss()
            }
        } message: { difficulty in
            let lost = minutesLost(for: difficulty)
            Text("Switching to \(difficulty.rawValue) caps your bank at \(difficulty.maxBalance) minutes. You'll lose \(lost) minutes.")
        }
    }

    private var header: some View {
        HStack {
            Text("DIFFICULTY")
                .font(AppFont.label(13))
                .tracking(4)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            Button {
                HapticManager.impact()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColor.textTertiary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Close")
        }
    }

    private func handleSelection(_ difficulty: Difficulty) {
        if difficulty == currentDifficulty {
            dismiss()
            return
        }

        let lost = minutesLost(for: difficulty)
        if lost > 0 {
            pendingDifficulty = difficulty
        } else {
            onSelect(difficulty)
            dismiss()
        }
    }
}

// MARK: - Difficulty Option Row

private struct DifficultyOptionRow: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let willLoseMinutes: Bool

    private let totalBars = 4
    private let barWidth: CGFloat = 3
    private let barHeight: CGFloat = 14
    private let barSpacing: CGFloat = 3

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Rank bars
            HStack(spacing: barSpacing) {
                ForEach(0..<totalBars, id: \.self) { index in
                    Rectangle()
                        .fill(index < difficulty.barCount ? difficulty.color : AppColor.border)
                        .frame(width: barWidth, height: barHeight)
                }
            }

            // Difficulty info
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.xs) {
                    Text(difficulty.rawValue)
                        .font(AppFont.label(14))
                        .tracking(2)
                        .foregroundStyle(difficulty.color)

                    // Warning indicator if will lose minutes
                    if willLoseMinutes && !isSelected {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(AppColor.hard)
                    }
                }

                Text(conversionText)
                    .font(AppFont.mono(11))
                    .foregroundStyle(AppColor.textSecondary)

                Text("Max bank: \(difficulty.maxBalance) min")
                    .font(AppFont.mono(11))
                    .foregroundStyle(AppColor.textTertiary)
            }

            Spacer()

            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(difficulty.color)
            }
        }
        .padding(AppSpacing.md)
        .background(
            Rectangle()
                .fill(isSelected ? AppColor.surface : Color.clear)
        )
        .overlay(
            Rectangle()
                .stroke(isSelected ? difficulty.color : AppColor.border, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private var accessibilityLabel: String {
        var label = "\(difficulty.rawValue), \(conversionText), max bank \(difficulty.maxBalance) minutes"
        if isSelected {
            label += ", currently selected"
        }
        if willLoseMinutes && !isSelected {
            label += ", warning: will reduce your balance"
        }
        return label
    }

    private var conversionText: String {
        switch difficulty {
        case .easy:
            return "1 min exercise = 2 min screen"
        case .medium:
            return "1 min exercise = 1 min screen"
        case .hard:
            return "2 min exercise = 1 min screen"
        case .extreme:
            return "3 min exercise = 1 min screen"
        }
    }
}

#Preview {
    DifficultyPickerSheet(
        currentDifficulty: .hard,
        currentBalance: 100,
        onSelect: { _ in }
    )
}

#Preview("Will Lose Minutes") {
    DifficultyPickerSheet(
        currentDifficulty: .easy,
        currentBalance: 200,
        onSelect: { _ in }
    )
}
