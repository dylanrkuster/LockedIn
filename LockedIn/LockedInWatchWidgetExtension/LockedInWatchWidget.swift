//
//  LockedInWatchWidget.swift
//  LockedInWatchWidgetExtension
//
//  Apple Watch widget displaying current balance as a complication.
//  Supports all watchOS widget families.
//

import SwiftUI
import WatchConnectivity
import WidgetKit

// MARK: - Timeline Entry

struct WatchBalanceEntry: TimelineEntry {
    let date: Date
    let balance: Int
    let maxBalance: Int
    let difficulty: String

    var progress: Double {
        guard maxBalance > 0 else { return 0 }
        return min(1, Double(max(0, balance)) / Double(maxBalance))
    }

    static var placeholder: WatchBalanceEntry {
        WatchBalanceEntry(date: Date(), balance: 47, maxBalance: 120, difficulty: "HARD")
    }
}

// MARK: - Timeline Provider

struct WatchBalanceProvider: TimelineProvider {
    // Storage keys matching WatchState
    private enum Keys {
        static let balance = "watch_balance"
        static let maxBalance = "watch_maxBalance"
        static let difficulty = "watch_difficulty"
    }

    // Shared App Group for watch app + widget extension
    private static let appGroupID = "group.usdk.LockedIn.watchkit"

    private func readState() -> (balance: Int, maxBalance: Int, difficulty: String) {
        let defaults = UserDefaults(suiteName: Self.appGroupID) ?? UserDefaults.standard

        // First, try to read from WatchConnectivity application context
        // This is persisted by the system and may have data even before watch app runs
        if WCSession.isSupported() {
            let session = WCSession.default
            let context = session.receivedApplicationContext

            if let balance = context["balance"] as? Int,
               let maxBalance = context["maxBalance"] as? Int,
               let difficulty = context["difficulty"] as? String {
                // Write to UserDefaults so it's available for future reads
                defaults.set(balance, forKey: Keys.balance)
                defaults.set(maxBalance, forKey: Keys.maxBalance)
                defaults.set(difficulty, forKey: Keys.difficulty)
                return (balance, maxBalance, difficulty)
            }
        }

        // Fall back to UserDefaults
        let balance = defaults.integer(forKey: Keys.balance)
        let maxBalance = defaults.integer(forKey: Keys.maxBalance)
        let difficulty = defaults.string(forKey: Keys.difficulty) ?? "MEDIUM"
        return (balance, maxBalance > 0 ? maxBalance : 120, difficulty)
    }

    func placeholder(in context: Context) -> WatchBalanceEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchBalanceEntry) -> Void) {
        let state = readState()
        let entry = WatchBalanceEntry(
            date: Date(),
            balance: state.balance,
            maxBalance: state.maxBalance,
            difficulty: state.difficulty
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchBalanceEntry>) -> Void) {
        let state = readState()
        let entry = WatchBalanceEntry(
            date: Date(),
            balance: state.balance,
            maxBalance: state.maxBalance,
            difficulty: state.difficulty
        )

        // Refresh every minute as fallback
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Definition

struct LockedInWatchWidget: Widget {
    let kind = "LockedInWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchBalanceProvider()) { entry in
            WatchWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
                .invalidatableContent()
        }
        .configurationDisplayName("Balance")
        .description("Your remaining screen time.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ])
    }
}

// MARK: - Widget View

struct WatchWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: WatchBalanceEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularWatchView(entry: entry)
        case .accessoryRectangular:
            RectangularWatchView(entry: entry)
        case .accessoryInline:
            InlineWatchView(entry: entry)
        case .accessoryCorner:
            CornerWatchView(entry: entry)
        default:
            CircularWatchView(entry: entry)
        }
    }
}

// MARK: - Circular View

private struct CircularWatchView: View {
    let entry: WatchBalanceEntry

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

// MARK: - Rectangular View

private struct RectangularWatchView: View {
    let entry: WatchBalanceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Difficulty bars
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(index < barCount ? Color.primary : Color.primary.opacity(0.3))
                        .frame(width: 3, height: 10)
                }
                Spacer()
            }

            // Balance
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

// MARK: - Inline View

private struct InlineWatchView: View {
    let entry: WatchBalanceEntry

    var body: some View {
        Text("\(entry.balance) min remaining")
            .contentTransition(.numericText())
    }
}

// MARK: - Corner View

private struct CornerWatchView: View {
    let entry: WatchBalanceEntry

    var body: some View {
        Text("\(entry.balance)")
            .font(.system(size: 20, weight: .bold, design: .monospaced))
            .contentTransition(.numericText())
            .widgetCurvesContent()
            .widgetLabel {
                Text("MIN")
            }
    }
}

// MARK: - Previews

#Preview("Circular", as: .accessoryCircular) {
    LockedInWatchWidget()
} timeline: {
    WatchBalanceEntry(date: Date(), balance: 47, maxBalance: 120, difficulty: "HARD")
}

#Preview("Rectangular", as: .accessoryRectangular) {
    LockedInWatchWidget()
} timeline: {
    WatchBalanceEntry(date: Date(), balance: 47, maxBalance: 120, difficulty: "HARD")
}

#Preview("Corner", as: .accessoryCorner) {
    LockedInWatchWidget()
} timeline: {
    WatchBalanceEntry(date: Date(), balance: 47, maxBalance: 120, difficulty: "HARD")
}
