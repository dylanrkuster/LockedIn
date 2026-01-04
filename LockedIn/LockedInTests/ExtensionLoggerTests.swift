//
//  ExtensionLoggerTests.swift
//  LockedInTests
//
//  Unit tests for ExtensionLogger.LogEntry creation.
//

import XCTest
@testable import LockedIn

final class ExtensionLoggerTests: XCTestCase {

    // MARK: - LogEntry Creation

    func testLogEntryCreationWithAllFields() {
        let entry = ExtensionLogger.LogEntry(
            event: "threshold",
            minute: 5,
            previousUsed: 4,
            currentBalance: 50,
            newBalance: 49,
            deducted: 1,
            message: "test message",
            error: nil
        )

        XCTAssertEqual(entry.event, "threshold")
        XCTAssertEqual(entry.minute, 5)
        XCTAssertEqual(entry.previousUsed, 4)
        XCTAssertEqual(entry.currentBalance, 50)
        XCTAssertEqual(entry.newBalance, 49)
        XCTAssertEqual(entry.deducted, 1)
        XCTAssertEqual(entry.message, "test message")
        XCTAssertNil(entry.error)
    }

    func testLogEntryCreationMinimalFields() {
        let entry = ExtensionLogger.LogEntry(event: "test")

        XCTAssertEqual(entry.event, "test")
        XCTAssertNil(entry.minute)
        XCTAssertNil(entry.previousUsed)
        XCTAssertNil(entry.currentBalance)
        XCTAssertNil(entry.newBalance)
        XCTAssertNil(entry.deducted)
        XCTAssertNil(entry.message)
        XCTAssertNil(entry.error)
    }

    func testLogEntryTimestampIsRecent() {
        let before = Date()
        let entry = ExtensionLogger.LogEntry(event: "test")
        let after = Date()

        XCTAssertGreaterThanOrEqual(entry.timestamp, before)
        XCTAssertLessThanOrEqual(entry.timestamp, after)
    }

    func testLogEntryWithError() {
        let entry = ExtensionLogger.LogEntry(
            event: "error",
            message: "context info",
            error: "Something went wrong"
        )

        XCTAssertEqual(entry.event, "error")
        XCTAssertEqual(entry.message, "context info")
        XCTAssertEqual(entry.error, "Something went wrong")
    }

    // MARK: - LogEntry Codable

    func testLogEntryCodable() throws {
        let original = ExtensionLogger.LogEntry(
            event: "threshold",
            minute: 10,
            previousUsed: 9,
            currentBalance: 100,
            newBalance: 99,
            deducted: 1,
            message: "test",
            error: nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ExtensionLogger.LogEntry.self, from: data)

        XCTAssertEqual(decoded.event, original.event)
        XCTAssertEqual(decoded.minute, original.minute)
        XCTAssertEqual(decoded.previousUsed, original.previousUsed)
        XCTAssertEqual(decoded.currentBalance, original.currentBalance)
        XCTAssertEqual(decoded.newBalance, original.newBalance)
        XCTAssertEqual(decoded.deducted, original.deducted)
        XCTAssertEqual(decoded.message, original.message)
        XCTAssertEqual(decoded.error, original.error)
        // Timestamps may differ slightly due to encoding precision
        XCTAssertEqual(
            decoded.timestamp.timeIntervalSince1970,
            original.timestamp.timeIntervalSince1970,
            accuracy: 1.0
        )
    }

    // MARK: - Event Types

    func testThresholdEventCreation() {
        let entry = ExtensionLogger.LogEntry(
            event: "threshold",
            minute: 5,
            previousUsed: 4,
            currentBalance: 50,
            newBalance: 49,
            deducted: 1
        )

        XCTAssertEqual(entry.event, "threshold")
        XCTAssertNotNil(entry.minute)
        XCTAssertNotNil(entry.deducted)
    }

    func testSkipEventCreation() {
        let entry = ExtensionLogger.LogEntry(
            event: "skip",
            minute: 3,
            previousUsed: 5,
            message: "minute <= previousUsed"
        )

        XCTAssertEqual(entry.event, "skip")
        XCTAssertEqual(entry.minute, 3)
        XCTAssertEqual(entry.previousUsed, 5)
        XCTAssertEqual(entry.message, "minute <= previousUsed")
    }

    func testIntervalEventCreation() {
        let entry = ExtensionLogger.LogEntry(
            event: "intervalDidStart",
            message: "activity=dailyMonitor"
        )

        XCTAssertEqual(entry.event, "intervalDidStart")
        XCTAssertEqual(entry.message, "activity=dailyMonitor")
        XCTAssertNil(entry.minute)
    }
}
