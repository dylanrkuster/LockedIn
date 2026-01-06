//
//  LockedInApp.swift
//  LockedIn
//

import FirebaseCore
import HealthKit
import StoreKit
import SwiftUI
import UserNotifications

@main
struct LockedInApp: App {
    @State private var bankState = BankState()
    @State private var familyControlsManager = FamilyControlsManager()
    @State private var blockingManager = BlockingManager()
    @State private var healthKitManager = HealthKitManager()
    @State private var showOnboarding = !SharedState.hasCompletedOnboarding

    init() {
        FirebaseApp.configure()

        // Enable foreground notification display
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared

        // Set install date on first launch (for analytics)
        if SharedState.installDate == nil {
            SharedState.installDate = Date()
            SharedState.synchronize()
        }
    }

    // MARK: - TEMPORARY: Marketing Screenshot Mode
    // Set to true to capture App Store screenshots (use /screenshots command)
    private let marketingScreenshotMode = false
    @State private var currentScreenshot = 1
    @State private var showNavigationOverlay = false

    var body: some Scene {
        WindowGroup {
            if marketingScreenshotMode {
                marketingScreenshotView
            } else {
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

                                // Analytics: onboarding completed
                                AnalyticsManager.track(.onboardingCompleted(
                                    difficulty: difficulty.rawValue,
                                    appCount: familyControlsManager.blockedAppCount
                                ))
                                AnalyticsManager.setDifficulty(difficulty.rawValue)
                                AnalyticsManager.setBlockedAppCount(familyControlsManager.blockedAppCount)
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
    }

    // MARK: - Marketing Screenshot View

    private var marketingScreenshotView: some View {
        ZStack {
            // Current screenshot
            Group {
                switch currentScreenshot {
                case 1: Screenshot1_Hero()
                case 2: Screenshot2_Blocked()
                case 3: Screenshot3_Difficulty()
                case 4: Screenshot4_Activity()
                case 5: Screenshot5_BlockedApps()
                default: Screenshot1_Hero()
                }
            }

            // Navigation overlay - tap to show, auto-hides after 3s
            if showNavigationOverlay {
                VStack {
                    Spacer()
                    HStack(spacing: 40) {
                        Button("← Prev") {
                            if currentScreenshot > 1 { currentScreenshot -= 1 }
                            resetOverlayTimer()
                        }
                        .opacity(currentScreenshot > 1 ? 1 : 0.3)

                        Text("\(currentScreenshot) / 5")
                            .font(.headline)

                        Button("Next →") {
                            if currentScreenshot < 5 { currentScreenshot += 1 }
                            resetOverlayTimer()
                        }
                        .opacity(currentScreenshot < 5 ? 1 : 0.3)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(.black.opacity(0.7))
                    .cornerRadius(12)
                    .padding(.bottom, 50)
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onTapGesture {
            showNavigationOverlay = true
            resetOverlayTimer()
        }
    }

    private func resetOverlayTimer() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            withAnimation { showNavigationOverlay = false }
        }
    }

    private var dashboardContent: some View {
        DashboardView(bankState: bankState, familyControlsManager: familyControlsManager, onRefresh: syncWorkouts)
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
                .onChange(of: bankState.balance) { oldBalance, newBalance in
                    // Balance changed - sync shield state immediately
                    blockingManager.syncShieldState(
                        balance: newBalance,
                        selection: familyControlsManager.selection
                    )

                    // EDGE CASE: If balance was 0 and now positive, monitoring may not be active.
                    // We need to ensure monitoring is running so events will fire.
                    // Note: We create events for ALL 240 minutes upfront, so we don't need to
                    // restart monitoring when balance increases (events already exist).
                    // We only need to START monitoring if it wasn't running (balance was 0).
                    if oldBalance <= 0 && newBalance > 0 {
                        blockingManager.ensureMonitoringActive(
                            selection: familyControlsManager.selection,
                            balance: newBalance,
                            forceRestart: false  // Don't force restart, just ensure it's running
                        )
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Reload state when app returns to foreground
                    reloadStateFromShared()

                    // Ensure monitoring is still active (self-healing)
                    // This catches cases where monitoring was orphaned or stopped unexpectedly
                    if familyControlsManager.hasEverBeenAuthorized && familyControlsManager.hasBlockedApps {
                        blockingManager.ensureMonitoringActive(
                            selection: familyControlsManager.selection,
                            balance: bankState.balance,
                            forceRestart: false  // Don't force restart on every foreground, just verify
                        )
                    }
                }
    }

    // MARK: - HealthKit Setup

    private func setupHealthKit() {
        // Set up workout detection callback for UI updates.
        // Note: Background processing happens directly in HealthKitManager via SharedState,
        // so this callback is only for refreshing the UI when app is in foreground.
        healthKitManager.onWorkoutsDetected = { [weak bankState] _ in
            // Sync UI state from SharedState (workouts already processed in background)
            bankState?.syncFromSharedState()
        }

        // Request authorization if not already done
        // Note: For read-only access, we can't reliably check if user granted permission.
        // We optimistically attempt queries after requesting authorization.
        Task {
            do {
                try await healthKitManager.requestAuthorization()

                // Fetch any workouts we missed while app was closed
                // If user denied access, queries will return empty results (no error)
                await syncWorkouts()

                // Observation auto-starts in HealthKitManager.init() if onboarding complete,
                // but call it here too in case this is first launch after onboarding
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
        // Note: We no longer call syncFromSharedState() here because earn() now uses
        // atomic operations that read the latest SharedState balance. This prevents
        // race conditions where extension deductions could be overwritten.

        for workout in workouts {
            let workoutID = workout.uuid.uuidString

            // Skip if already processed
            guard !SharedState.processedWorkoutIDs.contains(workoutID) else { continue }

            // Calculate earned minutes
            let durationMinutes = Int(workout.duration / 60)
            guard durationMinutes > 0 else { continue }

            // Calculate potential earned (before cap)
            let potentialEarned = Int(Double(durationMinutes) * bankState.difficulty.screenMinutesPerWorkoutMinute)

            // Get workout type display name
            let source = HealthKitManager.displayName(for: workout.workoutActivityType)

            // Add to balance - earn() uses atomic operations to prevent race conditions
            let actualEarned = bankState.earn(
                workoutMinutes: durationMinutes,
                source: source,
                timestamp: workout.endDate
            )

            // Post notification if enabled
            if SharedState.notifyWorkoutSync && actualEarned > 0 {
                if actualEarned < potentialEarned {
                    // Some earnings were lost to cap
                    NotificationManager.postWorkoutSyncedCapped(earnedMinutes: actualEarned)
                } else {
                    NotificationManager.postWorkoutSynced(earnedMinutes: actualEarned)
                }
            }

            // Reset notification flags if balance now above thresholds
            SharedState.resetNotificationFlags(for: bankState.balance)

            // Track first workout milestone
            let isFirstWorkout = SharedState.workoutCount == 0

            // Mark as processed and increment workout count
            SharedState.markWorkoutProcessed(workoutID)
            SharedState.workoutCount += 1

            // Analytics: workout synced
            AnalyticsManager.track(.workoutSynced(
                minutesEarned: actualEarned,
                workoutType: source,
                balanceAfter: bankState.balance
            ))

            if isFirstWorkout {
                AnalyticsManager.track(.firstWorkoutSynced(minutesEarned: actualEarned))
            }
        }
    }

    // MARK: - State Reload

    private func reloadStateFromShared() {
        // Analytics: app foregrounded
        AnalyticsManager.track(.appForegrounded(
            balance: SharedState.balance,
            difficulty: SharedState.difficultyRaw
        ))

        // Check for authorization revocation (user disabled in Settings)
        if familyControlsManager.checkForRevocation() {
            // Authorization was revoked - stop monitoring and remove shields
            blockingManager.stopMonitoring()
            blockingManager.removeShield()
            print("[LockedInApp] FamilyControls authorization revoked by user")
            return  // Don't proceed with monitoring setup
        }

        // Check if shield was displayed while app was in background
        let currentShieldCount = SharedState.shieldDisplayCount
        let lastKnownCount = SharedState.lastKnownShieldDisplayCount
        if currentShieldCount > lastKnownCount {
            AnalyticsManager.track(.shieldDisplayed(count: currentShieldCount - lastKnownCount))
            SharedState.lastKnownShieldDisplayCount = currentShieldCount
        }

        // Merge any pending transactions from extensions before reading state
        SharedState.mergePendingTransactions()

        // Reload balance from SharedState (may have changed by DeviceActivityMonitor extension)
        bankState.syncFromSharedState()

        // Sync shield state based on current balance (doesn't restart monitoring)
        blockingManager.syncShieldState(
            balance: bankState.balance,
            selection: familyControlsManager.selection
        )

        // Ensure monitoring is active. Check for build changes (belt-and-suspenders
        // with setupBlocking, but handles edge cases like background launch).
        // Use hasEverBeenAuthorized for reliability at app launch (isAuthorized may be stale)
        let hasAuthorization = familyControlsManager.hasEverBeenAuthorized ||
                               familyControlsManager.isAuthorized
        if hasAuthorization && familyControlsManager.hasBlockedApps {
            let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
            let buildChanged = currentBuild != SharedState.lastKnownBuildVersion

            if buildChanged {
                SharedState.lastKnownBuildVersion = currentBuild
                SharedState.synchronize()
            }

            do {
                try blockingManager.updateMonitoring(
                    balance: bankState.balance,
                    selection: familyControlsManager.selection,
                    forceRestart: buildChanged
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

        // Analytics: review prompt shown
        AnalyticsManager.track(.reviewPromptShown(workoutCount: SharedState.workoutCount))

        SharedState.hasPromptedReview = true
        SharedState.synchronize()
    }

    // MARK: - Blocking Setup

    private func setupBlocking() {
        // Use persisted authorization flag - more reliable than runtime check at launch.
        // The runtime check (isAuthorized) can return false briefly at app launch
        // before the system loads the actual authorization status.
        let hasAuthorization = familyControlsManager.hasEverBeenAuthorized ||
                               familyControlsManager.isAuthorized

        // If we've completed onboarding, we must have been authorized at some point
        if SharedState.hasCompletedOnboarding && !familyControlsManager.hasEverBeenAuthorized {
            // Backfill the persisted flag for users who completed onboarding
            // before this flag existed
            familyControlsManager.hasEverBeenAuthorized = true
        }

        guard hasAuthorization, familyControlsManager.hasBlockedApps else {
            // Silently return if not set up - this is expected for new users
            return
        }

        // Detect if the app binary changed (rebuild, update, reinstall).
        // When this happens, DeviceActivity monitoring must be force-restarted
        // because the extension binary was replaced and the old schedule is orphaned.
        let executableURL = Bundle.main.executableURL
        let executableDate = (try? executableURL?.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
        let currentBuildTimestamp = executableDate.map { String($0.timeIntervalSince1970) } ?? "unknown"
        var forceRestart = currentBuildTimestamp != SharedState.lastKnownBuildVersion

        #if DEBUG
        // In debug builds, always force restart to handle Xcode rebuilds
        forceRestart = true
        #endif

        if forceRestart {
            SharedState.lastKnownBuildVersion = currentBuildTimestamp
            SharedState.synchronize()
        }

        // Use the self-healing monitoring system
        blockingManager.ensureMonitoringActive(
            selection: familyControlsManager.selection,
            balance: bankState.balance,
            forceRestart: forceRestart
        )
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
