//
//  BalanceWidget.swift
//  LockedInWidget
//
//  Your balance. At a glance. No bullshit.
//

import SwiftUI
import WidgetKit

// MARK: - Timeline Entry

struct BalanceEntry: TimelineEntry {
    let date: Date
    let balance: Int
    let maxBalance: Int
    let difficulty: String

    var progress: Double {
        guard maxBalance > 0 else { return 0 }
        return min(1, Double(max(0, balance)) / Double(maxBalance))
    }

    static var placeholder: BalanceEntry {
        BalanceEntry(date: Date(), balance: 47, maxBalance: 120, difficulty: "HARD")
    }
}

// MARK: - Timeline Provider

struct BalanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> BalanceEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (BalanceEntry) -> Void) {
        let entry = BalanceEntry(
            date: Date(),
            balance: SharedState.balance,
            maxBalance: SharedState.maxBalance,
            difficulty: SharedState.difficultyRaw
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceEntry>) -> Void) {
        let entry = BalanceEntry(
            date: Date(),
            balance: SharedState.balance,
            maxBalance: SharedState.maxBalance,
            difficulty: SharedState.difficultyRaw
        )

        // Refresh every minute as fallback (primary refresh via WidgetCenter.reloadTimelines from extensions)
        // Frequent polling ensures balance stays in sync even if explicit refresh is throttled
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Definition

struct BalanceWidget: Widget {
    let kind = "BalanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BalanceProvider()) { entry in
            BalanceWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
                .invalidatableContent()  // Marks content as frequently changing for more responsive updates
        }
        .configurationDisplayName("Balance")
        .description("Your remaining screen time.")
        .supportedFamilies([
            // Lock Screen
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            // Home Screen
            .systemSmall
        ])
    }
}

// MARK: - Previews

#Preview("Circular", as: .accessoryCircular) {
    BalanceWidget()
} timeline: {
    BalanceEntry(date: Date(), balance: 47, maxBalance: 120, difficulty: "HARD")
    BalanceEntry(date: Date(), balance: 12, maxBalance: 120, difficulty: "HARD")
}

#Preview("Rectangular", as: .accessoryRectangular) {
    BalanceWidget()
} timeline: {
    BalanceEntry(date: Date(), balance: 47, maxBalance: 120, difficulty: "HARD")
}

#Preview("Inline", as: .accessoryInline) {
    BalanceWidget()
} timeline: {
    BalanceEntry(date: Date(), balance: 47, maxBalance: 120, difficulty: "HARD")
}

#Preview("Small", as: .systemSmall) {
    BalanceWidget()
} timeline: {
    BalanceEntry(date: Date(), balance: 47, maxBalance: 120, difficulty: "HARD")
    BalanceEntry(date: Date(), balance: 187, maxBalance: 240, difficulty: "EASY")
    BalanceEntry(date: Date(), balance: 5, maxBalance: 60, difficulty: "EXTREME")
}
