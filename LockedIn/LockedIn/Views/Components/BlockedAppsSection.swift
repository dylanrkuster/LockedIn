//
//  BlockedAppsSection.swift
//  LockedIn
//
//  Minimal. Factual. These are blocked.
//

import SwiftUI

struct BlockedAppsSection: View {
    let apps: [String]
    var onEdit: (() -> Void)?
    @State private var isExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var displayText: String {
        apps.isEmpty ? "None" : apps.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header row - full row is tappable
            Button {
                if reduceMotion {
                    isExpanded.toggle()
                } else {
                    withAnimation(.easeOut(duration: 0.15)) {
                        isExpanded.toggle()
                    }
                }
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

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(displayText)
                        .font(AppFont.body)
                        .foregroundStyle(apps.isEmpty ? AppColor.textTertiary : AppColor.textSecondary)

                    // Edit button - only visible when expanded
                    if let onEdit {
                        Button {
                            onEdit()
                        } label: {
                            Text("EDIT")
                                .font(AppFont.label(10))
                                .tracking(2)
                                .foregroundStyle(AppColor.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

#Preview {
    BlockedAppsSection(apps: ["Instagram", "TikTok", "X", "Snapchat"]) {
        print("Edit tapped")
    }
    .padding(24)
    .background(Color.black)
}

#Preview("Empty") {
    BlockedAppsSection(apps: []) {
        print("Edit tapped")
    }
    .padding(24)
    .background(Color.black)
}

#Preview("Many Apps") {
    BlockedAppsSection(apps: ["Instagram", "TikTok", "X", "Snapchat", "YouTube", "Reddit", "Facebook"]) {
        print("Edit tapped")
    }
    .padding(24)
    .background(Color.black)
}
