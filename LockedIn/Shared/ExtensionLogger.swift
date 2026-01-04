//
//  ExtensionLogger.swift
//  LockedIn (Shared)
//
//  Persistent file-based logging for DeviceActivity extension diagnostics.
//  Logs are written to App Groups container and readable by main app.
//
//  Add this file to ALL targets that need logging (main app + extensions).
//

import Foundation

/// File-based logger for extension diagnostics.
/// Uses JSONL format (one JSON object per line) for efficient append operations.
enum ExtensionLogger {
    private static let suiteName = "group.usdk.LockedIn"
    private static let logFileName = "extension_log.jsonl"
    private static let maxEntries = 500

    // MARK: - Log Entry

    struct LogEntry: Codable {
        let timestamp: Date
        let event: String
        let minute: Int?
        let previousUsed: Int?
        let currentBalance: Int?
        let newBalance: Int?
        let deducted: Int?
        let message: String?
        let error: String?

        init(
            event: String,
            minute: Int? = nil,
            previousUsed: Int? = nil,
            currentBalance: Int? = nil,
            newBalance: Int? = nil,
            deducted: Int? = nil,
            message: String? = nil,
            error: String? = nil
        ) {
            self.timestamp = Date()
            self.event = event
            self.minute = minute
            self.previousUsed = previousUsed
            self.currentBalance = currentBalance
            self.newBalance = newBalance
            self.deducted = deducted
            self.message = message
            self.error = error
        }
    }

    // MARK: - File URL

    private static var logFileURL: URL? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: suiteName
        ) else {
            return nil
        }
        return containerURL.appendingPathComponent(logFileName)
    }

    // MARK: - Logging

    /// Log an entry to the persistent log file.
    /// Note: Not truly thread-safe across processes. Acceptable for diagnostic logging
    /// where occasional data loss is tolerable. Do not use for critical data.
    static func log(_ entry: LogEntry) {
        guard let fileURL = logFileURL else {
            // Fallback: write to UserDefaults debug field
            fallbackLog(entry)
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(entry)

            guard var jsonString = String(data: data, encoding: .utf8) else {
                return
            }
            jsonString += "\n"

            // Append to file (create if doesn't exist)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let handle = try FileHandle(forWritingTo: fileURL)
                try handle.seekToEnd()
                if let lineData = jsonString.data(using: .utf8) {
                    try handle.write(contentsOf: lineData)
                }
                try handle.close()
            } else {
                try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
            }

            // Rotate if needed (check periodically, not every write)
            rotateIfNeeded()
        } catch {
            fallbackLog(entry)
        }
    }

    /// Convenience method for logging threshold events
    static func logThreshold(
        minute: Int,
        previousUsed: Int,
        currentBalance: Int,
        newBalance: Int,
        deducted: Int
    ) {
        log(LogEntry(
            event: "threshold",
            minute: minute,
            previousUsed: previousUsed,
            currentBalance: currentBalance,
            newBalance: newBalance,
            deducted: deducted
        ))
    }

    /// Convenience method for logging skipped events
    static func logSkip(minute: Int, previousUsed: Int, reason: String) {
        log(LogEntry(
            event: "skip",
            minute: minute,
            previousUsed: previousUsed,
            message: reason
        ))
    }

    /// Convenience method for logging errors
    static func logError(_ error: String, context: String? = nil) {
        log(LogEntry(
            event: "error",
            message: context,
            error: error
        ))
    }

    /// Convenience method for logging interval events
    static func logInterval(_ event: String, message: String? = nil) {
        log(LogEntry(event: event, message: message))
    }

    // MARK: - Reading

    /// Read all log entries from file.
    /// Returns entries sorted by timestamp (newest first).
    static func readLogs() -> [LogEntry] {
        guard let fileURL = logFileURL,
              FileManager.default.fileExists(atPath: fileURL.path)
        else {
            return []
        }

        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let entries: [LogEntry] = lines.compactMap { line in
                guard let data = line.data(using: .utf8) else { return nil }
                return try? decoder.decode(LogEntry.self, from: data)
            }

            return entries.sorted { $0.timestamp > $1.timestamp }
        } catch {
            return []
        }
    }

    /// Read the most recent N entries
    static func readRecentLogs(limit: Int = 50) -> [LogEntry] {
        Array(readLogs().prefix(limit))
    }

    // MARK: - Maintenance

    /// Clear all logs
    static func clearLogs() {
        guard let fileURL = logFileURL else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// Get log file size in bytes
    static var logFileSize: Int {
        guard let fileURL = logFileURL,
              let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let size = attributes[.size] as? Int
        else {
            return 0
        }
        return size
    }

    /// Rotate log file if it exceeds max entries.
    /// Keeps the most recent entries.
    private static func rotateIfNeeded() {
        // Only check every ~50 writes to reduce overhead
        // Use a simple heuristic: check if file size suggests many entries
        let estimatedEntrySize = 200 // bytes per entry estimate
        let threshold = maxEntries * estimatedEntrySize

        guard logFileSize > threshold else { return }

        let entries = readLogs()
        guard entries.count > maxEntries else { return }

        // Keep most recent entries
        let toKeep = Array(entries.prefix(maxEntries))

        // Rewrite file
        guard let fileURL = logFileURL else { return }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601

            // Write oldest first so newest ends up at bottom
            let reversed = toKeep.reversed()
            var content = ""
            for entry in reversed {
                if let data = try? encoder.encode(entry),
                   let json = String(data: data, encoding: .utf8) {
                    content += json + "\n"
                }
            }

            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            // Rotation failed - not critical, will try again later
        }
    }

    // MARK: - Fallback

    /// Fallback logging to UserDefaults when file access fails
    private static func fallbackLog(_ entry: LogEntry) {
        // Write to SharedState debug field as fallback
        if let defaults = UserDefaults(suiteName: suiteName) {
            let message = "[\(entry.event)] min=\(entry.minute ?? -1) bal=\(entry.newBalance ?? -1)"
            defaults.set(message, forKey: "debugExtensionMessage")
            defaults.synchronize()
        }
    }
}
