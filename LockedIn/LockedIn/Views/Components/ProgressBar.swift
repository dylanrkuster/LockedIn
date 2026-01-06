//
//  ProgressBar.swift
//  LockedIn
//
//  Thin. Sharp. Precise. No rounded corners.
//

import SwiftUI

struct ProgressBar: View {
    let current: Int
    let max: Int
    let accentColor: Color

    private var clampedCurrent: Int {
        Swift.max(0, current)
    }

    private var progress: Double {
        guard max > 0 else { return 0 }
        return min(1, Double(clampedCurrent) / Double(max))
    }

    private var percentageText: String {
        "\(Int(progress * 100)) percent"
    }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // The bar - razor thin, sharp edges
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    Rectangle()
                        .fill(AppColor.border)

                    // Fill
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: geometry.size.width * min(progress, 1.0))
                        .animation(.easeInOut(duration: 0.4), value: progress)
                }
            }
            .frame(height: 4)
            .accessibilityLabel("Balance")
            .accessibilityValue(percentageText)

            // Min/Max labels
            HStack {
                Text("0")
                    .font(AppFont.mono(10))
                    .foregroundStyle(AppColor.textTertiary)

                Spacer()

                Text("\(clampedCurrent) / \(max)")
                    .font(AppFont.mono(10))
                    .foregroundStyle(AppColor.textTertiary)

                Spacer()

                Text("\(max)")
                    .font(AppFont.mono(10))
                    .foregroundStyle(AppColor.textTertiary)
            }
            .accessibilityHidden(true)
        }
    }
}

#Preview {
    ProgressBar(current: 47, max: 120, accentColor: AppColor.hard)
        .padding(.horizontal, 48)
        .padding(.vertical, 24)
        .background(Color.black)
}

#Preview("Empty") {
    ProgressBar(current: 0, max: 120, accentColor: AppColor.extreme)
        .padding(.horizontal, 48)
        .padding(.vertical, 24)
        .background(Color.black)
}

#Preview("Full") {
    ProgressBar(current: 120, max: 120, accentColor: AppColor.easy)
        .padding(.horizontal, 48)
        .padding(.vertical, 24)
        .background(Color.black)
}
