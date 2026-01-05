//
//  LockedInApp.swift
//  LockedIn
//

import HealthKit
import StoreKit
import SwiftUI

@main
struct LockedInApp: App {
    @State private var bankState = BankState()
    @State private var familyControlsManager = FamilyControlsManager()
    @State private var blockingManager = BlockingManager()
    @State private var healthKitManager = HealthKitManager()
    @State private var showOnboarding = !SharedState.hasCompletedOnboarding

    var body: some Scene {
        WindowGroup {
            SplashView {
                if showOnboarding {
                    OnboardingView(
                        familyControlsManager: familyControlsManager,
                        healthKitManager: healthKitManager,
                        onComplete: { difficulty in
                            // Apply the selected difficulty and starting balance
                            bankState.difficulty = difficulty
                            bankState.balance = difficulty.startingBalance
                            // Mark onboarding complete AFTER state is set
                            // (ensures consistent state if app killed mid-completion)
                            SharedState.hasCompletedOnboarding = true
                            SharedState.synchronize()
                            // Transition to dashboard
                            withAnimation {
                                showOnboarding = false
                            }
                            // Setup blocking and health after onboarding
                            setupBlocking()
                            setupHealthKit()
                        }
                    )
                } else {
                    dashboardContent
                }
            }
        }
    }

    private var dashboardContent: some View {
        DashboardView(bankState: bankState, familyControlsManager: familyControlsManager)
            .onAppear {
                    // Merge any pending transactions from extensions
                    SharedState.mergePendingTransactions()

                    // Write marker for extension cross-process test
                    SharedState.debugMainAppMarker = "app_\(Date().timeIntervalSince1970)"
                    SharedState.synchronize()

                    setupBlocking()
                    setupHealthKit()
                }
                .onChange(of: familyControlsManager.selection) { _, _ in
                    // Selection changed - must restart monitoring with new app tokens
                    updateBlockingForSelectionChange()
                }
                .onChange(of: bankState.balance) { _, newBalance in
                    // Balance changed - only update shield state, don't restart monitoring
                    // (Restarting would reset the device's usage counter!)
                    blockingManager.syncShieldState(
                        balance: newBalance,
                        selection: familyControlsManager.selection
                    )
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Reload state when app returns to foreground
                    reloadStateFromShared()
                }
    }

    // MARK: - HealthKit Setup

    private func setupHealthKit() {
        // Set up workout detection callback
        healthKitManager.onWorkoutsDetected = { workouts in
            processNewWorkouts(workouts)
        }

        // Request authorization and start observing
        // Note: For read-only access, we can't reliably check if user granted permission.
        // We optimistically attempt queries after requesting authorization.
        Task {
            do {
                try await healthKitManager.requestAuthorization()

                // Fetch any workouts we missed while app was closed
                // If user denied access, queries will return empty results (no error)
                await syncWorkouts()

                // Start background observation
                healthKitManager.startObserving()
            } catch {
                print("HealthKit authorization failed: \(error)")
            }
        }
    }

    private func syncWorkouts() async {
        do {
            let processedIDs = SharedState.processedWorkoutIDs
            let newWorkouts = try await healthKitManager.fetchNewWorkouts(excludingIDs: processedIDs)

            if !newWorkouts.isEmpty {
                await MainActor.run {
                    processNewWorkouts(newWorkouts)
                }
            }

            SharedState.lastHealthKitSync = Date()
            SharedState.synchronize()
        } catch {
            print("Failed to sync workouts: \(error)")
        }
    }

    private func processNewWorkouts(_ workouts: [HKWorkout]) {
        for workout in workouts {
            let workoutID = workout.uuid.uuidString

            // Skip if already processed
            guard !SharedState.processedWorkoutIDs.contains(workoutID) else { continue }

            // Calculate earned minutes
            let durationMinutes = Int(workout.duration / 60)
            guard durationMinutes > 0 else { continue }

            // Calculate potential earned (before cap)
            let potentialEarned = Int(Double(durationMinutes) * bankState.difficulty.screenMinutesPerWorkoutMinute)
            let balanceBefore = bankState.balance

            // Get workout type display name
            let source = HealthKitManager.displayName(for: workout.workoutActivityType)

            // Add to balance
            bankState.earn(
                workoutMinutes: durationMinutes,
                source: source,
                timestamp: workout.endDate
            )

            // Calculate actual earned (may be capped)
            let actualEarned = bankState.balance - balanceBefore

            // Post notification if enabled
            if SharedState.notifyWorkoutSync && actualEarned > 0 {
                if actualEarned < potentialEarned {
                    // Some earnings were lost to cap
                    NotificationManager.postWorkoutSyncedCapped(
                        earnedMinutes: actualEarned,
                        workoutMinutes: potentialEarned
                    )
                } else {
                    NotificationManager.postWorkoutSynced(
                        earnedMinutes: actualEarned,
                        newBalance: bankState.balance,
                        maxBalance: bankState.maxBalance
                    )
                }
            }

            // Reset notification flags if balance now above thresholds
            SharedState.resetNotificationFlags(for: bankState.balance)

            // Mark as processed and increment workout count
            SharedState.markWorkoutProcessed(workoutID)
            SharedState.workoutCount += 1
        }
    }

    // MARK: - State Reload

    private func reloadStateFromShared() {
        // Merge any pending transactions from extensions before reading state
        SharedState.mergePendingTransactions()

        // Reload balance from SharedState (may have changed by DeviceActivityMonitor extension)
        bankState.syncFromSharedState()

        // Sync shield state based on current balance (doesn't restart monitoring)
        blockingManager.syncShieldState(
            balance: bankState.balance,
            selection: familyControlsManager.selection
        )

        // Start monitoring only if it's not already running
        // (Don't restart if running - that would reset the device's usage counter!)
        if familyControlsManager.isAuthorized && familyControlsManager.hasBlockedApps {
            do {
                try blockingManager.startMonitoringIfNeeded(
                    selection: familyControlsManager.selection,
                    balance: bankState.balance
                )
            } catch {
                print("Failed to start monitoring: \(error)")
            }
        }

        // Check for new workouts
        Task {
            await syncWorkouts()
        }

        // Prompt for App Store review after 10th workout
        if SharedState.workoutCount >= 10 && !SharedState.hasPromptedReview {
            requestAppStoreReview()
        }
    }

    // MARK: - App Store Review

    private func requestAppStoreReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }

        SKStoreReviewController.requestReview(in: scene)
        SharedState.hasPromptedReview = true
        SharedState.synchronize()
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

        // Start monitoring for usage (only if not already running)
        do {
            try blockingManager.startMonitoringIfNeeded(
                selection: familyControlsManager.selection,
                balance: bankState.balance
            )
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }

    /// Called when the user changes their blocked app selection.
    /// This MUST restart monitoring to register the new app tokens.
    private func updateBlockingForSelectionChange() {
        guard familyControlsManager.isAuthorized else { return }

        // Force restart monitoring with new selection
        do {
            try blockingManager.updateMonitoring(
                balance: bankState.balance,
                selection: familyControlsManager.selection,
                forceRestart: true  // Selection changed, must restart
            )
        } catch {
            print("Failed to update monitoring: \(error)")
        }
    }
}
