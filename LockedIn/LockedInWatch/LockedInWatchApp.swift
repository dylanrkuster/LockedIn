//
//  LockedInWatchApp.swift
//  LockedInWatch
//
//  Apple Watch companion app for LockedIn.
//  Displays current balance synced from iPhone.
//

import SwiftUI
import WidgetKit
import WatchConnectivity

@main
struct LockedInWatchApp: App {
    @State private var watchState = WatchState.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Initialize Watch Connectivity session
        _ = WatchSessionManager.shared

        // Schedule initial background refresh
        Self.scheduleBackgroundRefresh()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(watchState)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                // Schedule background refresh when app goes to background
                Self.scheduleBackgroundRefresh()
            } else if newPhase == .active {
                // Sync immediately when app becomes active
                WatchSessionManager.shared.requestBalance()
            }
        }
        .backgroundTask(.appRefresh("com.lockedin.sync")) {
            await Self.handleBackgroundRefresh()
        }
    }

    // MARK: - Background Refresh

    private static func scheduleBackgroundRefresh() {
        // Schedule refresh for 5 minutes from now
        // System may delay based on battery, usage patterns, etc.
        let preferredDate = Date(timeIntervalSinceNow: 5 * 60)
        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: preferredDate,
            userInfo: "sync" as NSSecureCoding & NSObjectProtocol
        ) { error in
            if let error = error {
                print("[Watch] Failed to schedule refresh: \(error)")
            } else {
                print("[Watch] Scheduled refresh for \(preferredDate)")
            }
        }
    }

    private static func handleBackgroundRefresh() async {
        print("[Watch] Background refresh triggered")

        // Read from WatchConnectivity application context
        if WCSession.default.activationState == .activated {
            let context = WCSession.default.receivedApplicationContext

            if let balance = context["balance"] as? Int,
               let maxBalance = context["maxBalance"] as? Int,
               let difficulty = context["difficulty"] as? String {
                // Update state (writes to UserDefaults)
                await MainActor.run {
                    WatchState.shared.update(
                        balance: balance,
                        maxBalance: maxBalance,
                        difficulty: difficulty
                    )
                }
                print("[Watch] Background sync: balance=\(balance)")
            }
        }

        // Refresh the widget
        WidgetCenter.shared.reloadTimelines(ofKind: "LockedInWatchWidget")

        // Schedule next refresh
        Self.scheduleBackgroundRefresh()
    }
}
