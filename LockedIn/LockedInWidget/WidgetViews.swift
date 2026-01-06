//
//  WidgetViews.swift
//  LockedInWidget
//
//  Brutalist widget views. Every pixel earns its place.
//

import SwiftUI
import WidgetKit

// MARK: - Main Widget View

struct BalanceWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: BalanceEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularView(entry: entry)
        case .accessoryRectangular:
            RectangularView(entry: entry)
        case .accessoryInline:
            InlineView(entry: entry)
        case .systemSmall:
            SmallView(entry: entry)
        default:
            SmallView(entry: entry)
        }
    }
}

// MARK: - Lock Screen: Circular

/// Circular gauge with balance number in center
private struct CircularView: View {
    let entry: BalanceEntry

    var body: some View {
        Gauge(value: entry.progress) {
            Text("\(entry.balance)")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}

// MARK: - Lock Screen: Rectangular

/// Balance with label and difficulty indicator
private struct RectangularView: View {
    let entry: BalanceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Difficulty rank bars
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(index < barCount ? Color.primary : Color.primary.opacity(0.3))
                        .frame(width: 3, height: 10)
                }
                Spacer()
            }

            // Balance number
            Text("\(entry.balance)")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())

            // Label
            Text("MIN REMAINING")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var barCount: Int {
        switch entry.difficulty {
        case "EASY": return 1
        case "MEDIUM": return 2
        case "HARD": return 3
        case "EXTREME": return 4
        default: return 2
        }
    }
}

// MARK: - Lock Screen: Inline

/// Single line: "47 min remaining"
private struct InlineView: View {
    let entry: BalanceEntry

    var body: some View {
        Text("\(entry.balance) min remaining")
            .contentTransition(.numericText())
    }
}

// MARK: - Home Screen: Small

/// Full brutalist balance display with difficulty color
private struct SmallView: View {
    let entry: BalanceEntry

    var body: some View {
        VStack(spacing: 4) {
            Spacer()

            // The number - commanding
            Text("\(entry.balance)")
                .font(.system(size: 56, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())

            // Label
            Text("MIN")
                .font(.system(size: 11, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Color.white.opacity(0.6))

            Spacer()

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Rectangle()
                        .fill(Color.white.opacity(0.2))

                    // Fill
                    Rectangle()
                        .fill(difficultyColor)
                        .frame(width: geo.size.width * entry.progress)
                }
            }
            .frame(height: 4)

            // Difficulty badge
            HStack(spacing: 3) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(index < barCount ? difficultyColor : Color.white.opacity(0.2))
                        .frame(width: 3, height: 12)
                }

                Text(entry.difficulty)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(difficultyColor)
            }
            .padding(.top, 4)
        }
        .padding(12)
    }

    private var barCount: Int {
        switch entry.difficulty {
        case "EASY": return 1
        case "MEDIUM": return 2
        case "HARD": return 3
        case "EXTREME": return 4
        default: return 2
        }
    }

    private var difficultyColor: Color {
        switch entry.difficulty {
        case "EASY": return Color(red: 0.133, green: 0.773, blue: 0.369)      // #22C55E
        case "MEDIUM": return Color(red: 0.918, green: 0.702, blue: 0.031)    // #EAB308
        case "HARD": return Color(red: 0.976, green: 0.451, blue: 0.086)      // #F97316
        case "EXTREME": return Color(red: 0.863, green: 0.149, blue: 0.149)   // #DC2626
        default: return Color(red: 0.918, green: 0.702, blue: 0.031)
        }
    }
}
