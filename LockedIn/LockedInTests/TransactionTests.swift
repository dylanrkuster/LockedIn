//
//  TransactionTests.swift
//  LockedInTests
//
//  Unit tests for Transaction and TransactionRecord.
//

import XCTest
@testable import LockedIn

final class TransactionTests: XCTestCase {

    // MARK: - Transaction isEarned

    func testIsEarnedPositive() {
        let transaction = Transaction(
            id: UUID(),
            amount: 15,
            source: "Workout",
            timestamp: Date()
        )

        XCTAssertTrue(transaction.isEarned)
    }

    func testIsEarnedNegative() {
        let transaction = Transaction(
            id: UUID(),
            amount: -10,
            source: "Instagram",
            timestamp: Date()
        )

        XCTAssertFalse(transaction.isEarned)
    }

    func testIsEarnedZero() {
        let transaction = Transaction(
            id: UUID(),
            amount: 0,
            source: "Test",
            timestamp: Date()
        )

        XCTAssertFalse(transaction.isEarned)
    }

    // MARK: - Formatted Amount

    func testFormattedAmountPositive() {
        let transaction = Transaction(
            id: UUID(),
            amount: 15,
            source: "Workout",
            timestamp: Date()
        )

        XCTAssertEqual(transaction.formattedAmount, "+15")
    }

    func testFormattedAmountNegative() {
        let transaction = Transaction(
            id: UUID(),
            amount: -25,
            source: "TikTok",
            timestamp: Date()
        )

        XCTAssertEqual(transaction.formattedAmount, "-25")
    }

    func testFormattedAmountZero() {
        let transaction = Transaction(
            id: UUID(),
            amount: 0,
            source: "Test",
            timestamp: Date()
        )

        XCTAssertEqual(transaction.formattedAmount, "+0")
    }

    // MARK: - Formatted Timestamp

    func testFormattedTimestampToday() {
        let calendar = Calendar.current
        let today = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: Date())!

        let transaction = Transaction(
            id: UUID(),
            amount: 10,
            source: "Test",
            timestamp: today
        )

        // Should be "2:30pm" format (no date prefix for today)
        XCTAssertTrue(transaction.formattedTimestamp.contains(":"))
        XCTAssertTrue(
            transaction.formattedTimestamp.contains("pm") || transaction.formattedTimestamp.contains("am")
        )
        XCTAssertFalse(transaction.formattedTimestamp.contains("/"))
    }

    func testFormattedTimestampYesterday() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayTime = calendar.date(bySettingHour: 19, minute: 45, second: 0, of: yesterday)!

        let transaction = Transaction(
            id: UUID(),
            amount: -5,
            source: "Test",
            timestamp: yesterdayTime
        )

        // Should be "M/d h:mma" format (with date prefix)
        XCTAssertTrue(transaction.formattedTimestamp.contains("/"))
    }

    // MARK: - TransactionRecord

    func testTransactionRecordInit() {
        let id = UUID()
        let record = TransactionRecord(
            id: id,
            amount: -10,
            source: "Instagram",
            timestamp: Date()
        )

        XCTAssertEqual(record.id, id)
        XCTAssertEqual(record.amount, -10)
        XCTAssertEqual(record.source, "Instagram")
    }

    func testTransactionRecordEquatable() {
        let id = UUID()
        let timestamp = Date()

        let record1 = TransactionRecord(id: id, amount: 10, source: "Test", timestamp: timestamp)
        let record2 = TransactionRecord(id: id, amount: 10, source: "Test", timestamp: timestamp)
        let record3 = TransactionRecord(id: UUID(), amount: 10, source: "Test", timestamp: timestamp)

        XCTAssertEqual(record1, record2)
        XCTAssertNotEqual(record1, record3)
    }

    func testTransactionRecordCodable() throws {
        let original = TransactionRecord(
            id: UUID(),
            amount: -15,
            source: "TikTok",
            timestamp: Date()
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TransactionRecord.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.amount, original.amount)
        XCTAssertEqual(decoded.source, original.source)
        XCTAssertEqual(
            decoded.timestamp.timeIntervalSince1970,
            original.timestamp.timeIntervalSince1970,
            accuracy: 0.001
        )
    }
}
