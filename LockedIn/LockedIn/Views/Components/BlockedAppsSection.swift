//
//  BlockedAppsSection.swift
//  LockedIn
//
//  Shows blocked apps with FamilyActivityPicker integration.
//

import FamilyControls
import SwiftUI

struct BlockedAppsSection: View {
    @Bindable var manager: FamilyControlsManager
    @State private var showPicker = false
    @State private var showDeniedAlert = false
    @State private var isRequestingAuth = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header with EDIT action
            HStack(alignment: .center) {
                Text("BLOCKED")
                    .font(AppFont.label(11))
                    .tracking(3)
                    .foregroundStyle(AppColor.textSecondary)

                Spacer()

                Button(action: handleEditTap) {
                    HStack(spacing: AppSpacing.xs) {
                        if isRequestingAuth {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(AppColor.textTertiary)
                        }
                        Text("EDIT")
                            .font(AppFont.label(10))
                            .tracking(2)
                            .foregroundStyle(AppColor.textTertiary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isRequestingAuth)
            }

            // App list or empty state (always visible)
            if manager.hasBlockedApps {
                appList
            } else {
                Text("None")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textTertiary)
            }
        }
        .familyActivityPicker(
            isPresented: $showPicker,
            selection: $manager.selection
        )
        .alert("Screen Time Access Required", isPresented: $showDeniedAlert) {
            Button("Open Settings") {
                openSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable Screen Time access in Settings to block apps.")
        }
    }

    // MARK: - App List

    private var appList: some View {
        let categories = Array(manager.selection.categoryTokens)
        let apps = Array(manager.selection.applicationTokens)
        let maxVisible = 8
        let totalCount = categories.count + apps.count

        // Show categories first, then apps, up to maxVisible total
        let visibleCategories = Array(categories.prefix(maxVisible))
        let remainingSlots = max(0, maxVisible - visibleCategories.count)
        let visibleApps = Array(apps.prefix(remainingSlots))
        let remaining = totalCount - visibleCategories.count - visibleApps.count

        return HStack(spacing: AppSpacing.xs) {
            // Category icons first (Apple's Label ignores font, so scale down)
            ForEach(visibleCategories, id: \.self) { token in
                Label(token)
                    .labelStyle(.iconOnly)
                    .scaleEffect(0.7)
                    .frame(width: 28, height: 28)
            }

            // Then individual app icons
            ForEach(visibleApps, id: \.self) { token in
                Label(token)
                    .labelStyle(.iconOnly)
                    .frame(width: 28, height: 28)
            }

            if remaining > 0 {
                Text("+\(remaining)")
                    .font(AppFont.mono(12))
                    .foregroundStyle(AppColor.textTertiary)
            }
        }
    }

    // MARK: - Actions

    private func handleEditTap() {
        Task {
            isRequestingAuth = true
            let authorized = await manager.requestAuthorizationIfNeeded()
            isRequestingAuth = false

            if authorized {
                showPicker = true
            } else if manager.wasDenied {
                showDeniedAlert = true
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Preview

#Preview {
    BlockedAppsSectionPreview()
}

private struct BlockedAppsSectionPreview: View {
    @State private var manager = FamilyControlsManager()

    var body: some View {
        BlockedAppsSection(manager: manager)
            .padding(24)
            .background(Color.black)
    }
}
