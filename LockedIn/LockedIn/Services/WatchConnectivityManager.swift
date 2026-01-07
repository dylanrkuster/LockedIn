//
//  WatchConnectivityManager.swift
//  LockedIn
//
//  Manages Watch Connectivity session to sync balance with Apple Watch.
//  Sends balance updates to the paired watch for widget display.
//

import Foundation
import WatchConnectivity

/// Singleton manager for Watch Connectivity on iOS side.
/// Automatically syncs balance to paired Apple Watch when it changes.
final class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()

    private var session: WCSession?

    /// Whether the watch is paired and reachable
    var isWatchAvailable: Bool {
        session?.isPaired == true && session?.isWatchAppInstalled == true
    }

    private override init() {
        super.init()
        setupSession()
    }

    // MARK: - Setup

    private func setupSession() {
        guard WCSession.isSupported() else {
            print("[WatchConnectivity] Not supported on this device")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Sync Balance

    /// Send current balance to the watch. Call this whenever balance changes.
    func syncBalance(_ balance: Int, maxBalance: Int, difficulty: String) {
        guard let session = session,
              session.activationState == .activated,
              session.isPaired,
              session.isWatchAppInstalled else {
            return
        }

        let context: [String: Any] = [
            "balance": balance,
            "maxBalance": maxBalance,
            "difficulty": difficulty,
            "timestamp": Date().timeIntervalSince1970
        ]

        // Use application context for guaranteed delivery (even if watch app not running)
        // This overwrites the previous context - watch gets latest value when it wakes
        do {
            try session.updateApplicationContext(context)
            print("[WatchConnectivity] Synced balance: \(balance)")
        } catch {
            print("[WatchConnectivity] Failed to sync: \(error)")
        }

        // Also send immediately if watch is reachable (faster but not guaranteed)
        if session.isReachable {
            session.sendMessage(context, replyHandler: nil) { error in
                print("[WatchConnectivity] Message send failed: \(error)")
            }
        }
    }

    /// Convenience method to sync from SharedState
    func syncFromSharedState() {
        syncBalance(
            SharedState.balance,
            maxBalance: SharedState.maxBalance,
            difficulty: SharedState.difficultyRaw
        )
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("[WatchConnectivity] Activation failed: \(error)")
            return
        }

        print("[WatchConnectivity] Activated: \(activationState.rawValue)")

        // Sync current state when session activates
        if activationState == .activated {
            DispatchQueue.main.async {
                self.syncFromSharedState()
            }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("[WatchConnectivity] Session inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("[WatchConnectivity] Session deactivated")
        // Reactivate for switching watches
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("[WatchConnectivity] Reachability changed: \(session.isReachable)")
        // Sync when watch becomes reachable
        if session.isReachable {
            DispatchQueue.main.async {
                self.syncFromSharedState()
            }
        }
    }

    // Handle requests from watch (e.g., manual refresh)
    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        if message["requestBalance"] != nil {
            let response: [String: Any] = [
                "balance": SharedState.balance,
                "maxBalance": SharedState.maxBalance,
                "difficulty": SharedState.difficultyRaw,
                "timestamp": Date().timeIntervalSince1970
            ]
            replyHandler(response)
        }
    }
}
