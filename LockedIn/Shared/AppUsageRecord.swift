//
//  AppUsageRecord.swift
//  LockedIn
//
//  Per-app usage record extracted from DeviceActivityReport.
//  Stored in SharedState for cross-process access.
//

import Foundation

/// Per-app usage data extracted from DeviceActivity reports
struct AppUsageRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let appName: String
    let tokenKey: String      // Base64-encoded ApplicationToken for mapping
    let durationMinutes: Int  // Total usage duration in minutes
    let date: Date            // When this usage was recorded

    init(
        id: UUID = UUID(),
        appName: String,
        tokenKey: String,
        durationMinutes: Int,
        date: Date
    ) {
        self.id = id
        self.appName = appName
        self.tokenKey = tokenKey
        self.durationMinutes = durationMinutes
        self.date = date
    }
}
