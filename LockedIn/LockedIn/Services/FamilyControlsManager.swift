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

    var isAuthorized: Bool { authorizationStatus == .approved }
    var needsAuthorization: Bool { authorizationStatus == .notDetermined }
    var wasDenied: Bool { authorizationStatus == .denied }

    // MARK: - App Selection

    var selection = FamilyActivitySelection() {
        didSet { saveSelection() }
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

    /// Request authorization if not already granted or denied.
    /// - Returns: true if authorized (either already or newly granted)
    @MainActor
    func requestAuthorizationIfNeeded() async -> Bool {
        refreshStatus()

        if isAuthorized { return true }
        if wasDenied { return false }

        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            refreshStatus()
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
        guard let data = SharedState.selectionData else { return }
        do {
            selection = try PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
        } catch {
            print("Failed to load selection: \(error)")
        }
    }
}
