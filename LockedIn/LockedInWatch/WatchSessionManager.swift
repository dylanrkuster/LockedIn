//
//  WatchSessionManager.swift
//  LockedInWatch
//
//  Receives balance updates from iPhone via Watch Connectivity.
//

import Foundation
import WatchConnectivity

/// Singleton manager for Watch Connectivity on watchOS side.
/// Receives balance updates from the paired iPhone.
final class WatchSessionManager: NSObject {
    static let shared = WatchSessionManager()

    private var session: WCSession?

    private override init() {
        super.init()
        setupSession()
    }

    // MARK: - Setup

    private func setupSession() {
        guard WCSession.isSupported() else {
            print("[WatchSession] Not supported")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Request Balance

    /// Load balance from cached application context (immediate, no network required)
    func loadCachedBalance() {
        guard let session = session,
              session.activationState == .activated else {
            return
        }

        let context = session.receivedApplicationContext
        if !context.isEmpty {
            handleBalanceUpdate(context)
        }
    }

    /// Request current balance from iPhone (for manual refresh)
    func requestBalance() {
        // Always load cached context first (immediate)
        loadCachedBalance()

        // Then try to get fresh data if iPhone is reachable
        guard let session = session,
              session.activationState == .activated,
              session.isReachable else {
            return
        }

        session.sendMessage(["requestBalance": true]) { response in
            self.handleBalanceUpdate(response)
        } errorHandler: { error in
            print("[WatchSession] Request failed: \(error)")
        }
    }

    // MARK: - Handle Updates

    private func handleBalanceUpdate(_ data: [String: Any]) {
        guard let balance = data["balance"] as? Int,
              let maxBalance = data["maxBalance"] as? Int,
              let difficulty = data["difficulty"] as? String else {
            return
        }

        DispatchQueue.main.async {
            WatchState.shared.update(
                balance: balance,
                maxBalance: maxBalance,
                difficulty: difficulty
            )
        }

        print("[WatchSession] Updated: balance=\(balance), max=\(maxBalance), difficulty=\(difficulty)")
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("[WatchSession] Activation failed: \(error)")
            return
        }

        print("[WatchSession] Activated: \(activationState.rawValue)")

        // Check for any pending application context
        if activationState == .activated {
            let context = session.receivedApplicationContext
            if !context.isEmpty {
                handleBalanceUpdate(context)
            }
        }
    }

    // Receive application context (guaranteed delivery)
    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        handleBalanceUpdate(applicationContext)
    }

    // Receive immediate messages (when app is active)
    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        handleBalanceUpdate(message)
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        handleBalanceUpdate(message)
        replyHandler(["received": true])
    }
}
