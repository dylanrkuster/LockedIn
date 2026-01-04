//
//  DebugLogView.swift
//  LockedIn
//
//  Debug view for viewing extension logs and heartbeat status.
//  Used to diagnose tracking issues.
//

import SwiftUI

struct DebugLogView: View {
    @State private var logs: [ExtensionLogger.LogEntry] = []
    @State private var heartbeat: Date?
    @State private var runCount: Int = 0
    @State private var lastMessage: String = ""
    @State private var isMonitoring: Bool = false
    @State private var usedMinutesToday: Int = 0
    @State private var balance: Int = 0

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, HH:mm:ss"
        return f
    }()

    var body: some View {
        ZStack {
            AppColor.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    // Status Section
                    statusSection

                    // Heartbeat Section
                    heartbeatSection

                    // Logs Section
                    logsSection
                }
                .padding(AppSpacing.md)
            }
        }
        .navigationTitle("Debug Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Refresh") {
                    refreshData()
                }
                .foregroundColor(AppColor.textSecondary)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear") {
                    ExtensionLogger.clearLogs()
                    refreshData()
                }
                .foregroundColor(.red)
            }
        }
        .onAppear {
            refreshData()
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("STATUS")

            VStack(spacing: 0) {
                statusRow("Monitoring", isMonitoring ? "Active" : "Inactive")
                Divider().background(AppColor.border)
                statusRow("Balance", "\(balance) min")
                Divider().background(AppColor.border)
                statusRow("Used Today", "\(usedMinutesToday) min")
                Divider().background(AppColor.border)
                statusRow("Run Count", "\(runCount)")
                Divider().background(AppColor.border)
                statusRow("Last Msg", lastMessage)
            }
            .background(AppColor.surface)
            .cornerRadius(8)
        }
    }

    // MARK: - Heartbeat Section

    private var heartbeatSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("HEARTBEAT")

            VStack(spacing: 0) {
                HStack {
                    Text("Last Activity")
                        .font(AppFont.body)
                        .foregroundColor(AppColor.textSecondary)

                    Spacer()

                    if let hb = heartbeat {
                        Text(heartbeatText(hb))
                            .font(AppFont.mono(14))
                            .foregroundColor(heartbeatColor(hb))
                    } else {
                        Text("Never")
                            .font(AppFont.mono(14))
                            .foregroundColor(.red)
                    }
                }
                .padding(AppSpacing.sm)

                if SharedState.isExtensionHeartbeatStale {
                    Divider().background(AppColor.border)
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Extension may have stopped responding")
                            .font(AppFont.body)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(AppSpacing.sm)
                }
            }
            .background(AppColor.surface)
            .cornerRadius(8)
        }
    }

    // MARK: - Logs Section

    private var logsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                sectionHeader("LOGS (\(logs.count))")
                Spacer()
                Text("\(ExtensionLogger.logFileSize) bytes")
                    .font(AppFont.mono(11))
                    .foregroundColor(AppColor.textTertiary)
            }

            if logs.isEmpty {
                Text("No logs yet. Use a blocked app to generate logs.")
                    .font(AppFont.body)
                    .foregroundColor(AppColor.textTertiary)
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity)
                    .background(AppColor.surface)
                    .cornerRadius(8)
            } else {
                LazyVStack(spacing: 1) {
                    ForEach(logs.indices, id: \.self) { index in
                        logRow(logs[index])
                    }
                }
                .background(AppColor.surface)
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Components

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .tracking(2)
            .foregroundColor(AppColor.textTertiary)
    }

    private func statusRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(AppFont.body)
                .foregroundColor(AppColor.textSecondary)
            Spacer()
            Text(value)
                .font(AppFont.mono(14))
                .foregroundColor(AppColor.textPrimary)
                .lineLimit(1)
        }
        .padding(AppSpacing.sm)
    }

    private func logRow(_ entry: ExtensionLogger.LogEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(Self.dateFormatter.string(from: entry.timestamp))
                    .font(AppFont.mono(11))
                    .foregroundColor(AppColor.textTertiary)

                Text(entry.event.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(eventColor(entry.event))

                Spacer()

                if let minute = entry.minute {
                    Text("min \(minute)")
                        .font(AppFont.mono(11))
                        .foregroundColor(AppColor.textSecondary)
                }
            }

            if entry.event == "threshold" {
                HStack(spacing: AppSpacing.sm) {
                    if let prev = entry.previousUsed {
                        Text("prev:\(prev)")
                            .font(AppFont.mono(10))
                            .foregroundColor(AppColor.textTertiary)
                    }
                    if let bal = entry.currentBalance {
                        Text("bal:\(bal)")
                            .font(AppFont.mono(10))
                            .foregroundColor(AppColor.textTertiary)
                    }
                    if let deducted = entry.deducted {
                        Text("-\(deducted)")
                            .font(AppFont.mono(10))
                            .foregroundColor(.red)
                    }
                    if let newBal = entry.newBalance {
                        Text("→\(newBal)")
                            .font(AppFont.mono(10))
                            .foregroundColor(AppColor.easy)
                    }
                }
            }

            if let message = entry.message, !message.isEmpty {
                Text(message)
                    .font(AppFont.mono(10))
                    .foregroundColor(AppColor.textTertiary)
            }

            if let error = entry.error, !error.isEmpty {
                Text("ERROR: \(error)")
                    .font(AppFont.mono(10))
                    .foregroundColor(.red)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.background)
    }

    // MARK: - Helpers

    private func eventColor(_ event: String) -> Color {
        switch event {
        case "threshold": return AppColor.easy
        case "skip": return .orange
        case "error": return .red
        case "intervalDidStart", "intervalDidEnd": return .blue
        case "shield_applied": return .purple
        default: return AppColor.textSecondary
        }
    }

    private func heartbeatText(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 {
            return "\(seconds)s ago"
        } else if seconds < 3600 {
            return "\(seconds / 60)m ago"
        } else {
            return Self.fullDateFormatter.string(from: date)
        }
    }

    private func heartbeatColor(_ date: Date) -> Color {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 {
            return AppColor.easy
        } else if seconds < 120 {
            return .orange
        } else {
            return .red
        }
    }

    private func refreshData() {
        logs = ExtensionLogger.readRecentLogs(limit: 100)
        heartbeat = SharedState.extensionHeartbeat
        runCount = SharedState.debugExtensionRunCount
        lastMessage = SharedState.debugExtensionMessage
        isMonitoring = SharedState.isMonitoring
        usedMinutesToday = SharedState.usedMinutesToday
        balance = SharedState.balance
    }
}

#Preview {
    NavigationStack {
        DebugLogView()
    }
    .preferredColorScheme(.dark)
}
