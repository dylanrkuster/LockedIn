//
//  LockedInApp.swift
//  LockedIn
//

import SwiftUI

@main
struct LockedInApp: App {
    @State private var bankState = BankState()
    @State private var familyControlsManager = FamilyControlsManager()
    @State private var blockingManager = BlockingManager()

    var body: some Scene {
        WindowGroup {
            DashboardView(bankState: bankState, familyControlsManager: familyControlsManager)
                .onAppear {
                    setupBlocking()
                }
                .onChange(of: familyControlsManager.selection) { _, _ in
                    updateBlocking()
                }
                .onChange(of: bankState.balance) { _, _ in
                    updateBlocking()
                }
        }
    }

    // MARK: - Blocking Setup

    private func setupBlocking() {
        // Only start monitoring if authorized and apps are selected
        guard familyControlsManager.isAuthorized,
              familyControlsManager.hasBlockedApps
        else { return }

        // Sync shield state based on current balance
        blockingManager.syncShieldState(
            balance: bankState.balance,
            selection: familyControlsManager.selection
        )

        // Start monitoring for usage
        do {
            try blockingManager.startMonitoring(
                selection: familyControlsManager.selection,
                balance: bankState.balance
            )
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }

    private func updateBlocking() {
        guard familyControlsManager.isAuthorized else { return }

        // Update monitoring threshold and shield state
        do {
            try blockingManager.updateMonitoring(
                balance: bankState.balance,
                selection: familyControlsManager.selection
            )
        } catch {
            print("Failed to update monitoring: \(error)")
        }
    }
}
