//
//  FamilyControlsManager.swift
//  LockedIn
//
//  Manages FamilyControls authorization and app selection.
//  Futureproof: works for both EDIT button (now) and onboarding (later).
//

import FamilyControls
import Foundation

@Observable
final class FamilyControlsManager {
    // MARK: - Authorization State

    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined

    /// Runtime check - may be unreliable at app launch
    var isAuthorized: Bool { authorizationStatus == .approved }
    var needsAuthorization: Bool { authorizationStatus == .notDetermined }
    var wasDenied: Bool { authorizationStatus == .denied }

    /// Persisted flag - reliable even at app launch.
    /// Set to true when authorization is successfully granted.
    /// This survives app relaunches and doesn't depend on system timing.
    var hasEverBeenAuthorized: Bool {
        get { SharedState.hasEverBeenAuthorized }
        set {
            SharedState.hasEverBeenAuthorized = newValue
            SharedState.synchronize()
        }
    }

    // MARK: - App Selection

    private var hasLoadedInitialSelection = false

    var selection = FamilyActivitySelection() {
        didSet {
            // Only track user-initiated changes, not initial load from persistence
            if hasLoadedInitialSelection {
                AnalyticsManager.track(.blockedAppsModified(
                    appCount: selection.applicationTokens.count,
                    categoryCount: selection.categoryTokens.count
                ))
                AnalyticsManager.setBlockedAppCount(blockedAppCount)
            }
            saveSelection()
        }
    }

    var blockedAppCount: Int {
        selection.applicationTokens.count + selection.categoryTokens.count
    }

    var hasBlockedApps: Bool {
        !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
    }

    var hasCategorySelections: Bool {
        !selection.categoryTokens.isEmpty
    }

    // MARK: - Init

    init() {
        loadSelection()
        refreshStatus()
    }

    // MARK: - Authorization

    /// Refresh authorization status from the system
    func refreshStatus() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }

    /// Check for authorization revocation and update persisted state.
    /// Call this on app foreground to detect if user revoked permission in Settings.
    /// - Returns: true if authorization was revoked
    func checkForRevocation() -> Bool {
        refreshStatus()

        // If we previously had authorization but now don't, user revoked it
        if hasEverBeenAuthorized && !isAuthorized {
            // Clear persisted flag since authorization was explicitly revoked
            hasEverBeenAuthorized = false
            return true
        }
        return false
    }

    /// Request authorization if not already granted or denied.
    /// - Returns: true if authorized (either already or newly granted)
    @MainActor
    func requestAuthorizationIfNeeded() async -> Bool {
        refreshStatus()

        if isAuthorized {
            hasEverBeenAuthorized = true
            return true
        }
        if wasDenied { return false }

        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            refreshStatus()
            if isAuthorized {
                hasEverBeenAuthorized = true
            }
            return isAuthorized
        } catch {
            refreshStatus()
            return false
        }
    }

    // MARK: - Persistence

    private func saveSelection() {
        do {
            let data = try PropertyListEncoder().encode(selection)
            // Save to SharedState for extension access
            SharedState.selectionData = data
            SharedState.synchronize()
        } catch {
            print("Failed to save selection: \(error)")
        }
    }

    private func loadSelection() {
        defer { hasLoadedInitialSelection = true }
        guard let data = SharedState.selectionData else { return }
        do {
            selection = try PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
        } catch {
            print("Failed to load selection: \(error)")
        }
    }
}
