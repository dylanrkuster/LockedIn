//
//  SettingsView.swift
//  LockedIn
//
//  Settings screen with notification toggles. Brutalist. Functional.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    let accentColor: Color
    @Environment(\.dismiss) private var dismiss

    // Notification settings bound to SharedState
    @State private var notify5Min = SharedState.notify5MinWarning
    @State private var notify15Min = SharedState.notify15MinWarning
    @State private var notifyWorkout = SharedState.notifyWorkoutSync

    // Notification permission state
    @State private var notificationsAuthorized = true  // Assume true until checked

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

                    if notificationsAuthorized {
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
                    } else {
                        notificationsDeniedView
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                // About section
                VStack(spacing: 0) {
                    sectionHeader("ABOUT")

                    aboutRow(appVersion)

                    Button {
                        HapticManager.impact()
                        openFeedbackEmail()
                    } label: {
                        HStack {
                            Text("Send Feedback")
                                .font(AppFont.body)
                                .foregroundStyle(accentColor)
                                .underline()
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, AppSpacing.sm)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.xl)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .background(SwipeBackGestureEnabler())
        .task {
            await checkNotificationAuthorization()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await checkNotificationAuthorization()
            }
        }
    }

    // MARK: - Notification Authorization

    private func checkNotificationAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationsAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Notifications Denied View

    private var notificationsDeniedView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Notifications are disabled.")
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)

            Button {
                openNotificationSettings()
            } label: {
                Text("Enable in Settings")
                    .font(AppFont.body)
                    .foregroundStyle(accentColor)
                    .underline()
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppSpacing.sm)
    }

    private func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - About Section

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    private func aboutRow(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)
            Spacer()
        }
        .padding(.vertical, AppSpacing.sm)
    }

    private func openFeedbackEmail() {
        guard let url = URL(string: "mailto:feedback@lockedin.app?subject=LockedIn%20Feedback") else { return }
        UIApplication.shared.open(url)
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
