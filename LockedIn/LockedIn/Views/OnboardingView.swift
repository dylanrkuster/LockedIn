//
//  OnboardingView.swift
//  LockedIn
//
//  First-time user experience. A commitment ceremony, not a tutorial.
//

import FamilyControls
import HealthKit
import SwiftUI
import UserNotifications

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable, Hashable {
    case welcome
    case appSelection
    case difficulty
    case permissions
    case widgets
    case activation
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @Bindable var familyControlsManager: FamilyControlsManager
    let healthKitManager: HealthKitManager
    let onComplete: (Difficulty) -> Void

    @State private var navigationPath: [OnboardingStep] = []
    @State private var selectedDifficulty: Difficulty = .medium
    @State private var hasGrantedScreenTime: Bool
    @State private var hasRequestedHealth = false
    @State private var hasGrantedNotifications = false
    @State private var showScreenTimeDeniedAlert = false

    init(
        familyControlsManager: FamilyControlsManager,
        healthKitManager: HealthKitManager,
        onComplete: @escaping (Difficulty) -> Void
    ) {
        self._familyControlsManager = Bindable(wrappedValue: familyControlsManager)
        self.healthKitManager = healthKitManager
        self.onComplete = onComplete
        // Initialize permission state from actual system state
        self._hasGrantedScreenTime = State(initialValue: familyControlsManager.isAuthorized)
    }

    // Step number for display (excludes welcome screen, so 1-5)
    private func stepNumber(for step: OnboardingStep) -> Int {
        step.rawValue  // welcome=0, appSelection=1, difficulty=2, permissions=3, widgets=4, activation=5
    }

    private let totalSteps = 5

    var body: some View {
        NavigationStack(path: $navigationPath) {
            // Welcome screen (root)
            welcomeScreenView
                .navigationDestination(for: OnboardingStep.self) { step in
                    screenView(for: step)
                }
        }
        .preferredColorScheme(.dark)
        .alert("Screen Time Required", isPresented: $showScreenTimeDeniedAlert) {
            Button("Open Settings") {
                openSettings()
            }
            Button("Try Again") {
                Task {
                    await requestScreenTimeAccess()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("LockedIn needs Screen Time access to block apps. Please enable it in Settings.")
        }
        .onAppear {
            // Sync authorization state in case it was granted in a previous session
            familyControlsManager.refreshStatus()
            hasGrantedScreenTime = familyControlsManager.isAuthorized
        }
    }

    // MARK: - Screen Views

    private var welcomeScreenView: some View {
        ZStack {
            AppColor.background
                .ignoresSafeArea()

            WelcomeScreen(onContinue: {
                AnalyticsManager.track(.onboardingStarted)
                navigationPath.append(.appSelection)
            })
        }
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private func screenView(for step: OnboardingStep) -> some View {
        ZStack {
            AppColor.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Step indicator and back button row
                HStack {
                    // Back button - hidden on activation
                    if step != .activation {
                        Button {
                            HapticManager.impact()
                            navigationPath.removeLast()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(AppColor.textTertiary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        Spacer()
                            .frame(width: 44)
                    }

                    Spacer()

                    // Step indicator
                    Text("\(stepNumber(for: step)) OF \(totalSteps)")
                        .font(AppFont.mono(12))
                        .tracking(2)
                        .foregroundStyle(AppColor.textTertiary)

                    Spacer()

                    // Placeholder for symmetry
                    Spacer()
                        .frame(width: 44)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)

                // Screen content
                screenContent(for: step)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .background(SwipeBackGestureEnabler())
    }

    // MARK: - Screen Content

    @ViewBuilder
    private func screenContent(for step: OnboardingStep) -> some View {
        switch step {
        case .welcome:
            WelcomeScreen(onContinue: {
                AnalyticsManager.track(.onboardingStarted)
                navigationPath.append(.appSelection)
            })
        case .appSelection:
            AppSelectionScreen(
                manager: familyControlsManager,
                onContinue: {
                    AnalyticsManager.track(.onboardingAppsSelected(count: familyControlsManager.blockedAppCount))
                    navigationPath.append(.difficulty)
                },
                onAuthorizationChanged: { authorized in
                    hasGrantedScreenTime = authorized
                }
            )
        case .difficulty:
            DifficultyScreen(
                selectedDifficulty: $selectedDifficulty,
                onContinue: {
                    AnalyticsManager.track(.onboardingDifficultySelected(difficulty: selectedDifficulty.rawValue))
                    // Update app icon when leaving difficulty selection
                    AppIconManager.updateIcon(for: selectedDifficulty)
                    navigationPath.append(.permissions)
                }
            )
        case .permissions:
            PermissionsScreen(
                hasGrantedScreenTime: hasGrantedScreenTime,
                hasRequestedHealth: hasRequestedHealth,
                hasGrantedNotifications: hasGrantedNotifications,
                onRequestScreenTime: { await requestScreenTimeAccess() },
                onRequestHealth: { await requestHealthAccess() },
                onRequestNotifications: { await requestNotificationAccess() },
                onContinue: {
                    AnalyticsManager.track(.onboardingPermissionsGranted(
                        screenTime: hasGrantedScreenTime,
                        health: hasRequestedHealth,
                        notifications: hasGrantedNotifications
                    ))
                    navigationPath.append(.widgets)
                }
            )
        case .widgets:
            WidgetsScreen(
                difficulty: selectedDifficulty,
                onContinue: {
                    navigationPath.append(.activation)
                }
            )
        case .activation:
            ActivationScreen(
                difficulty: selectedDifficulty,
                blockedAppCount: familyControlsManager.blockedAppCount,
                onComplete: completeOnboarding
            )
        }
    }

    // MARK: - Permission Requests

    @MainActor
    private func requestScreenTimeAccess() async {
        let authorized = await familyControlsManager.requestAuthorizationIfNeeded()
        hasGrantedScreenTime = authorized

        if familyControlsManager.wasDenied {
            showScreenTimeDeniedAlert = true
        }
    }

    @MainActor
    private func requestHealthAccess() async {
        // Note: HealthKit's privacy model doesn't reveal if user granted read permission.
        // We request authorization and mark as "requested" - actual permission status is unknown.
        // If denied, workout queries will simply return empty results.
        do {
            try await healthKitManager.requestAuthorization()
        } catch {
            // Only throws if HealthKit is unavailable on device
        }
        hasRequestedHealth = true
    }

    @MainActor
    private func requestNotificationAccess() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            hasGrantedNotifications = granted
        } catch {
            // Notification permission failed, but it's optional
            hasGrantedNotifications = false
        }
    }

    // MARK: - Completion

    private func completeOnboarding() {
        // Notify parent to set difficulty + balance, then mark onboarding complete
        // Note: hasCompletedOnboarding is set in LockedInApp.onComplete AFTER
        // difficulty/balance to ensure atomic state if app is killed mid-completion
        onComplete(selectedDifficulty)
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Screen 1: Welcome

private struct WelcomeScreen: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo / Title
            Text("LOCKEDIN")
                .font(.system(size: 32, weight: .bold, design: .default))
                .tracking(8)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()
                .frame(height: AppSpacing.xl)

            // Tagline
            Text("Exercise to earn screen time.")
                .font(AppFont.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColor.textSecondary)

            Spacer()

            // CTA
            OnboardingButton(title: "GET STARTED", action: onContinue)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
        }
    }
}

// MARK: - Screen 2: App Selection

private struct AppSelectionScreen: View {
    @Bindable var manager: FamilyControlsManager
    let onContinue: () -> Void
    let onAuthorizationChanged: (Bool) -> Void

    @State private var showPicker = false
    @State private var showDeniedAlert = false
    @State private var isRequestingAuthorization = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: AppSpacing.xxl)

            // Header
            Text("SELECT DISTRACTIONS")
                .font(.system(size: 24, weight: .bold, design: .default))
                .tracking(4)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()
                .frame(height: AppSpacing.md)

            // Subtext
            Text("Using these apps costs screen time. When your bank hits zero, they're blocked.")
                .font(AppFont.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColor.textSecondary)
                .padding(.horizontal, AppSpacing.xl)

            Spacer()

            // Choose apps button
            Button {
                HapticManager.impact()
                Task {
                    await requestAuthorizationAndShowPicker()
                }
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    if isRequestingAuthorization {
                        ProgressView()
                            .tint(AppColor.textPrimary)
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "apps.iphone")
                            .font(.system(size: 18))
                    }
                    Text(isRequestingAuthorization ? "LOADING..." : "CHOOSE APPS")
                        .font(AppFont.label(13))
                        .tracking(2)
                }
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .contentShape(Rectangle())
                .overlay(
                    Rectangle()
                        .stroke(AppColor.textPrimary, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isRequestingAuthorization)
            .padding(.horizontal, AppSpacing.lg)

            Spacer()
                .frame(height: AppSpacing.lg)

            // Selected apps display
            if manager.hasBlockedApps {
                selectedAppsView
            } else {
                Text("No apps selected")
                    .font(AppFont.mono(14))
                    .foregroundStyle(AppColor.textTertiary)
            }

            Spacer()

            // Continue button
            OnboardingButton(
                title: "CONTINUE",
                isEnabled: manager.hasBlockedApps,
                action: onContinue
            )
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xxl)
        }
        .familyActivityPicker(
            isPresented: $showPicker,
            selection: $manager.selection
        )
        .alert("Screen Time Required", isPresented: $showDeniedAlert) {
            Button("Open Settings") {
                openSettings()
            }
            Button("Try Again") {
                Task {
                    await requestAuthorizationAndShowPicker()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("LockedIn needs Screen Time access to block apps. Please enable it in Settings.")
        }
    }

    @MainActor
    private func requestAuthorizationAndShowPicker() async {
        // Already authorized - show picker directly
        if manager.isAuthorized {
            showPicker = true
            return
        }

        // Show loading state immediately
        isRequestingAuthorization = true
        defer { isRequestingAuthorization = false }

        // Request authorization
        let authorized = await manager.requestAuthorizationIfNeeded()
        onAuthorizationChanged(authorized)

        if authorized {
            showPicker = true
        } else if manager.wasDenied {
            showDeniedAlert = true
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private var selectedAppsView: some View {
        let categories = Array(manager.selection.categoryTokens)
        let apps = Array(manager.selection.applicationTokens)
        let maxVisible = 8
        let totalCount = categories.count + apps.count

        let visibleCategories = Array(categories.prefix(maxVisible))
        let remainingSlots = max(0, maxVisible - visibleCategories.count)
        let visibleApps = Array(apps.prefix(remainingSlots))
        let remaining = totalCount - visibleCategories.count - visibleApps.count

        return HStack(spacing: AppSpacing.sm) {
            ForEach(visibleCategories, id: \.self) { token in
                Label(token)
                    .labelStyle(.iconOnly)
                    .scaleEffect(0.8)
                    .frame(width: 32, height: 32)
            }

            ForEach(visibleApps, id: \.self) { token in
                Label(token)
                    .labelStyle(.iconOnly)
                    .frame(width: 32, height: 32)
            }

            if remaining > 0 {
                Text("+\(remaining)")
                    .font(AppFont.mono(14))
                    .foregroundStyle(AppColor.textTertiary)
            }
        }
    }
}

// MARK: - Screen 3: Difficulty Selection

private struct DifficultyScreen: View {
    @Binding var selectedDifficulty: Difficulty
    let onContinue: () -> Void

    @State private var showExtremeConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: AppSpacing.xxl)

            // Header
            Text("HOW LOCKED IN ARE YOU?")
                .font(.system(size: 20, weight: .bold, design: .default))
                .tracking(3)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()
                .frame(height: AppSpacing.md)

            // Explanation
            Text("Earn screen time by logging workouts in Apple Health (Apple Watch, Oura Ring, ...etc, or manually). Higher difficulty means more exercise per minute unlocked.")
                .font(AppFont.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColor.textSecondary)
                .padding(.horizontal, AppSpacing.xl)

            Spacer()
                .frame(height: AppSpacing.lg)

            // Difficulty cards
            VStack(spacing: AppSpacing.sm) {
                ForEach(Difficulty.allCases) { difficulty in
                    DifficultyCard(
                        difficulty: difficulty,
                        isSelected: difficulty == selectedDifficulty
                    )
                    .onTapGesture {
                        HapticManager.selection()
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedDifficulty = difficulty
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)

            Spacer()

            // Continue button - show confirmation for EXTREME
            OnboardingButton(title: "CONTINUE") {
                if selectedDifficulty == .extreme {
                    showExtremeConfirmation = true
                } else {
                    onContinue()
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xxl)
        }
        .alert("Start at Zero?", isPresented: $showExtremeConfirmation) {
            Button("Choose Different", role: .cancel) {
                // User wants to reconsider
            }
            Button("I'm Ready", role: .destructive) {
                onContinue()
            }
        } message: {
            Text("EXTREME starts with 0 minutes. Your blocked apps will be locked immediately until you complete a workout. Are you sure?")
        }
    }
}

// MARK: - Difficulty Card

private struct DifficultyCard: View {
    let difficulty: Difficulty
    let isSelected: Bool

    private let totalBars = 4
    private let barWidth: CGFloat = 4
    private let barHeight: CGFloat = 18
    private let barSpacing: CGFloat = 3

    private var ratioExplanation: String {
        switch difficulty {
        case .easy: "1 min exercise = 2 min screen"
        case .medium: "1 min exercise = 1 min screen"
        case .hard: "2 min exercise = 1 min screen"
        case .extreme: "3 min exercise = 1 min screen"
        }
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Rank bars
            HStack(spacing: barSpacing) {
                ForEach(0..<totalBars, id: \.self) { index in
                    Rectangle()
                        .fill(index < difficulty.barCount ? difficulty.color : AppColor.border)
                        .frame(width: barWidth, height: barHeight)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(difficulty.rawValue)
                    .font(AppFont.label(14))
                    .tracking(2)
                    .foregroundStyle(difficulty.color)

                Text(ratioExplanation)
                    .font(AppFont.mono(11))
                    .foregroundStyle(AppColor.textSecondary)

                HStack(spacing: AppSpacing.xs) {
                    Text("Start: \(difficulty.startingBalance)m")
                        .font(AppFont.mono(10))
                        .foregroundStyle(AppColor.textTertiary)

                    Text("·")
                        .font(AppFont.mono(10))
                        .foregroundStyle(AppColor.textTertiary)

                    Text("Max: \(difficulty.maxBalance)m")
                        .font(AppFont.mono(10))
                        .foregroundStyle(AppColor.textTertiary)
                }
            }

            Spacer()

            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(difficulty.color)
            }
        }
        .padding(AppSpacing.md)
        .background(isSelected ? AppColor.surface : Color.clear)
        .overlay(
            Rectangle()
                .stroke(isSelected ? difficulty.color : AppColor.border, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Screen 4: Permissions

private struct PermissionsScreen: View {
    let hasGrantedScreenTime: Bool
    let hasRequestedHealth: Bool  // Note: Can't detect actual grant status due to HealthKit privacy
    let hasGrantedNotifications: Bool
    let onRequestScreenTime: () async -> Void
    let onRequestHealth: () async -> Void
    let onRequestNotifications: () async -> Void
    let onContinue: () -> Void

    @State private var isLoadingScreenTime = false
    @State private var isLoadingHealth = false
    @State private var isLoadingNotifications = false

    private var canContinue: Bool {
        hasGrantedScreenTime && hasRequestedHealth
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: AppSpacing.xl)

            // Header
            Text("PERMISSIONS")
                .font(.system(size: 24, weight: .bold, design: .default))
                .tracking(4)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()
                .frame(height: AppSpacing.xl)

            // Screen Time permission (required)
            PermissionBlock(
                title: "SCREEN TIME ACCESS",
                subtitle: "Required to block apps.",
                isGranted: hasGrantedScreenTime,
                grantedLabel: "GRANTED",
                isRequired: true,
                isLoading: isLoadingScreenTime,
                onRequest: {
                    Task {
                        isLoadingScreenTime = true
                        await onRequestScreenTime()
                        isLoadingScreenTime = false
                    }
                }
            )
            .padding(.horizontal, AppSpacing.lg)

            Spacer()
                .frame(height: AppSpacing.md)

            // Health permission (required, but can't verify grant status due to privacy)
            PermissionBlock(
                title: "APPLE HEALTH ACCESS",
                subtitle: "Required to track workouts. If workouts don't sync, verify in Settings > Privacy > Health.",
                isGranted: hasRequestedHealth,
                grantedLabel: "GRANTED",  // Optimistic - can't actually verify due to HealthKit privacy
                isRequired: true,
                isLoading: isLoadingHealth,
                onRequest: {
                    Task {
                        isLoadingHealth = true
                        await onRequestHealth()
                        isLoadingHealth = false
                    }
                }
            )
            .padding(.horizontal, AppSpacing.lg)

            Spacer()
                .frame(height: AppSpacing.md)

            // Notifications permission (optional)
            PermissionBlock(
                title: "NOTIFICATIONS",
                subtitle: "Get useful reminders.",
                isGranted: hasGrantedNotifications,
                grantedLabel: "GRANTED",
                isRequired: false,
                isLoading: isLoadingNotifications,
                onRequest: {
                    Task {
                        isLoadingNotifications = true
                        await onRequestNotifications()
                        isLoadingNotifications = false
                    }
                }
            )
            .padding(.horizontal, AppSpacing.lg)

            Spacer()

            // Continue button (requires Screen Time AND Health)
            OnboardingButton(
                title: "CONTINUE",
                isEnabled: canContinue,
                action: onContinue
            )
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xxl)
        }
    }
}

// MARK: - Permission Block

private struct PermissionBlock: View {
    let title: String
    let subtitle: String
    let isGranted: Bool
    let grantedLabel: String  // "GRANTED" or "REQUESTED" depending on verifiability
    let isRequired: Bool
    let isLoading: Bool
    let onRequest: () -> Void

    /// Color for the granted state - green for verified, yellow for unverified
    private var grantedColor: Color {
        grantedLabel == "GRANTED" ? AppColor.easy : AppColor.medium
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header with optional badge
            HStack(spacing: AppSpacing.sm) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .tracking(2)
                    .foregroundStyle(AppColor.textPrimary)

                if !isRequired {
                    Text("OPTIONAL")
                        .font(AppFont.mono(9))
                        .foregroundStyle(AppColor.textTertiary)
                }
            }

            // Subtitle
            Text(subtitle)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)

            // Grant button or status
            if isGranted {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: grantedLabel == "GRANTED" ? "checkmark.circle.fill" : "questionmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(grantedColor)
                    Text(grantedLabel)
                        .font(AppFont.label(13))
                        .tracking(2)
                        .foregroundStyle(grantedColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            } else {
                Button {
                    HapticManager.impact()
                    onRequest()
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        if isLoading {
                            ProgressView()
                                .tint(AppColor.textPrimary)
                                .scaleEffect(0.8)
                        }
                        Text(isLoading ? "REQUESTING..." : "GRANT ACCESS")
                            .font(AppFont.label(13))
                            .tracking(2)
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .contentShape(Rectangle())
                    .overlay(
                        Rectangle()
                            .stroke(AppColor.textPrimary, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
        }
        .padding(AppSpacing.lg)
        .overlay(
            Rectangle()
                .stroke(AppColor.border, lineWidth: 1)
        )
    }
}

// MARK: - Screen 5: Widgets

private struct WidgetsScreen: View {
    let difficulty: Difficulty
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: AppSpacing.lg)

            // Header
            Text("ADD A WIDGET")
                .font(.system(size: 24, weight: .bold, design: .default))
                .tracking(4)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()
                .frame(height: AppSpacing.sm)

            // Subtext - punchy
            Text("Never miss your balance.")
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)

            Spacer()
                .frame(height: AppSpacing.xl)

            // Widget showcase - vertical stack
            VStack(spacing: AppSpacing.lg) {
                // Lock screen widget
                WidgetShowcase(
                    title: "LOCK SCREEN",
                    subtitle: "Glanceable circular gauge"
                ) {
                    LockScreenWidgetPreview(
                        balance: difficulty.startingBalance,
                        maxBalance: difficulty.maxBalance,
                        difficulty: difficulty
                    )
                }

                // Home screen widget
                WidgetShowcase(
                    title: "HOME SCREEN",
                    subtitle: "Full balance with progress"
                ) {
                    HomeScreenWidgetPreview(
                        balance: difficulty.startingBalance,
                        maxBalance: difficulty.maxBalance,
                        difficulty: difficulty
                    )
                }
            }
            .padding(.horizontal, AppSpacing.lg)

            Spacer()
                .frame(height: AppSpacing.xl)

            // Instructions - compact, integrated
            VStack(spacing: AppSpacing.md) {
                // Divider
                Rectangle()
                    .fill(AppColor.border)
                    .frame(height: 1)
                    .padding(.horizontal, AppSpacing.lg)

                HStack(spacing: AppSpacing.xl) {
                    InstructionStep(number: "1", text: "Long press\nyour screen")
                    InstructionStep(number: "2", text: "Tap the\n+ button")
                    InstructionStep(number: "3", text: "Search\n\"LOCKEDIN\"")
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)

                // Divider
                Rectangle()
                    .fill(AppColor.border)
                    .frame(height: 1)
                    .padding(.horizontal, AppSpacing.lg)
            }

            Spacer()

            // Continue button
            OnboardingButton(title: "CONTINUE", action: onContinue)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
        }
    }
}

// MARK: - Widget Showcase

private struct WidgetShowcase<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            // Widget preview
            content

            // Description
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFont.label(12))
                    .tracking(2)
                    .foregroundStyle(AppColor.textPrimary)

                Text(subtitle)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textTertiary)
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .overlay(
            Rectangle()
                .stroke(AppColor.border, lineWidth: 1)
        )
    }
}

// MARK: - Lock Screen Widget Preview (Circular Gauge)

private struct LockScreenWidgetPreview: View {
    let balance: Int
    let maxBalance: Int
    let difficulty: Difficulty

    private var progress: Double {
        guard maxBalance > 0 else { return 0 }
        return Double(balance) / Double(maxBalance)
    }

    var body: some View {
        ZStack {
            // Background circle (track)
            Circle()
                .stroke(AppColor.border, lineWidth: 5)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(difficulty.color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Balance number
            Text("\(balance)")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(AppColor.textPrimary)
        }
        .frame(width: 70, height: 70)
    }
}

// MARK: - Home Screen Widget Preview (Small)

private struct HomeScreenWidgetPreview: View {
    let balance: Int
    let maxBalance: Int
    let difficulty: Difficulty

    private var progress: Double {
        guard maxBalance > 0 else { return 0 }
        return Double(balance) / Double(maxBalance)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Balance number
            Text("\(balance)")
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(AppColor.textPrimary)
                .padding(.top, 8)

            Text("MIN")
                .font(.system(size: 7, weight: .semibold))
                .tracking(1)
                .foregroundStyle(AppColor.textSecondary)
                .padding(.top, 1)

            Spacer(minLength: 0)

            // Progress bar
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(AppColor.border)
                    .frame(height: 2)
                Rectangle()
                    .fill(difficulty.color)
                    .frame(width: 58 * progress, height: 2)
            }
            .frame(width: 58)
            .padding(.bottom, 4)

            // Difficulty bars
            HStack(spacing: 1) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(index < difficulty.barCount ? difficulty.color : AppColor.border)
                        .frame(width: 2, height: 6)
                }
            }
            .padding(.bottom, 6)
        }
        .frame(width: 70, height: 70)
        .background(AppColor.surface)
        .overlay(
            Rectangle()
                .stroke(AppColor.border, lineWidth: 1)
        )
    }
}

// MARK: - Instruction Step

private struct InstructionStep: View {
    let number: String
    let text: String

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            // Number in circle
            Text(number)
                .font(AppFont.mono(14))
                .foregroundStyle(AppColor.textPrimary)
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .stroke(AppColor.border, lineWidth: 1)
                )

            // Text
            Text(text)
                .font(AppFont.mono(11))
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Screen 6: Activation

private struct ActivationScreen: View {
    let difficulty: Difficulty
    let blockedAppCount: Int
    let onComplete: () -> Void

    private let totalBars = 4
    private let barWidth: CGFloat = 4
    private let barHeight: CGFloat = 18
    private let barSpacing: CGFloat = 3

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            Text("YOU'RE LOCKED IN")
                .font(.system(size: 24, weight: .bold, design: .default))
                .tracking(4)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()
                .frame(height: AppSpacing.xl)

            // Starting balance
            VStack(spacing: AppSpacing.sm) {
                Text("Starting Bank")
                    .font(AppFont.label(11))
                    .tracking(2)
                    .foregroundStyle(AppColor.textSecondary)

                Text("\(difficulty.startingBalance)")
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppColor.textPrimary)

                Text("minutes")
                    .font(AppFont.mono(14))
                    .foregroundStyle(AppColor.textTertiary)
            }

            Spacer()
                .frame(height: AppSpacing.xl)

            // Difficulty + blocked count
            HStack(spacing: AppSpacing.lg) {
                // Difficulty badge
                HStack(spacing: AppSpacing.sm) {
                    HStack(spacing: barSpacing) {
                        ForEach(0..<totalBars, id: \.self) { index in
                            Rectangle()
                                .fill(index < difficulty.barCount ? difficulty.color : AppColor.border)
                                .frame(width: barWidth, height: barHeight)
                        }
                    }

                    Text(difficulty.rawValue)
                        .font(AppFont.label(12))
                        .tracking(2)
                        .foregroundStyle(difficulty.color)
                }

                // Blocked count
                Text("\(blockedAppCount) app\(blockedAppCount == 1 ? "" : "s") blocked")
                    .font(AppFont.mono(12))
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()
                .frame(height: AppSpacing.xl)

            // Tagline
            Text("Ready to earn your screen time?")
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)

            Spacer()

            // CTA
            OnboardingButton(title: "LET'S GO", action: onComplete)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
        }
    }
}

// MARK: - Onboarding Button

private struct OnboardingButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.impact()
            action()
        } label: {
            Text(title)
                .font(AppFont.label(13))
                .tracking(2)
                .foregroundStyle(isEnabled ? AppColor.textPrimary : AppColor.textTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .contentShape(Rectangle())
                .overlay(
                    Rectangle()
                        .stroke(isEnabled ? AppColor.textPrimary : AppColor.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// MARK: - Previews

#Preview("Welcome") {
    OnboardingView(
        familyControlsManager: FamilyControlsManager(),
        healthKitManager: HealthKitManager(),
        onComplete: { _ in }
    )
}
