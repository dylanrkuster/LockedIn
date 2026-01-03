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
    @State private var isExpanded = false
    @State private var showPicker = false
    @State private var showDeniedAlert = false
    @State private var isRequestingAuth = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header row - full row is tappable
            headerButton

            // Expanded content
            if isExpanded {
                expandedContent
                    .transition(.opacity)
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

    // MARK: - Header

    private var headerButton: some View {
        Button {
            toggleExpanded()
        } label: {
            HStack(alignment: .center) {
                Text("BLOCKED")
                    .font(AppFont.label(11))
                    .tracking(3)
                    .foregroundStyle(AppColor.textSecondary)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppColor.textTertiary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(isExpanded ? "Collapse" : "Expand")
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // App list or empty state
            if manager.hasBlockedApps {
                appList
            } else {
                Text("None")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textTertiary)
            }

            // Edit button
            editButton
        }
    }

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

    private var editButton: some View {
        Button {
            handleEditTap()
        } label: {
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
        .accessibilityLabel("Edit blocked apps")
    }

    // MARK: - Actions

    private func toggleExpanded() {
        if reduceMotion {
            isExpanded.toggle()
        } else {
            withAnimation(.easeOut(duration: 0.15)) {
                isExpanded.toggle()
            }
        }
    }

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
