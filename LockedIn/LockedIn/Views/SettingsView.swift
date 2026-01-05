//
//  SettingsView.swift
//  LockedIn
//
//  Settings screen with notification toggles. Brutalist. Functional.
//

import SwiftUI

struct SettingsView: View {
    let accentColor: Color
    @Environment(\.dismiss) private var dismiss

    // Notification settings bound to SharedState
    @State private var notify5Min = SharedState.notify5MinWarning
    @State private var notify15Min = SharedState.notify15MinWarning
    @State private var notifyWorkout = SharedState.notifyWorkoutSync

    var body: some View {
        ZStack {
            AppColor.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xl)

                // Content
                VStack(spacing: 0) {
                    sectionHeader("NOTIFICATIONS")

                    notificationToggle(
                        title: "5 min warning",
                        isOn: $notify5Min
                    ) {
                        SharedState.notify5MinWarning = $0
                    }

                    notificationToggle(
                        title: "15 min warning",
                        isOn: $notify15Min
                    ) {
                        SharedState.notify15MinWarning = $0
                    }

                    notificationToggle(
                        title: "Workout synced",
                        isOn: $notifyWorkout
                    ) {
                        SharedState.notifyWorkoutSync = $0
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .background(SwipeBackGestureEnabler())
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            // Centered title
            Text("SETTINGS")
                .font(AppFont.label(12))
                .tracking(4)
                .foregroundStyle(AppColor.textPrimary)

            // Back button aligned left
            HStack {
                Button {
                    HapticManager.impact()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppColor.textTertiary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(AppFont.label(11))
                .tracking(3)
                .foregroundStyle(AppColor.textSecondary)

            Spacer()
        }
        .padding(.bottom, AppSpacing.md)
    }

    // MARK: - Toggle Row

    private func notificationToggle(
        title: String,
        isOn: Binding<Bool>,
        onChange: @escaping (Bool) -> Void
    ) -> some View {
        HStack {
            Text(title)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(accentColor)
                .onChange(of: isOn.wrappedValue) { _, newValue in
                    HapticManager.selection()
                    onChange(newValue)
                    SharedState.synchronize()
                }
        }
        .padding(.vertical, AppSpacing.sm)
    }
}

#Preview {
    NavigationStack {
        SettingsView(accentColor: AppColor.hard)
    }
}
