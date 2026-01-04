//
//  TrackingLogicTests.swift
//  LockedInTests
//
//  Unit tests for TrackingLogic pure functions.
//

import XCTest
@testable import LockedIn

final class TrackingLogicTests: XCTestCase {

    // MARK: - parseMinute Tests

    func testParseMinuteValid() {
        XCTAssertEqual(TrackingLogic.parseMinute(from: "minute_5"), 5)
        XCTAssertEqual(TrackingLogic.parseMinute(from: "minute_0"), 0)
        XCTAssertEqual(TrackingLogic.parseMinute(from: "minute_100"), 100)
        XCTAssertEqual(TrackingLogic.parseMinute(from: "minute_1"), 1)
    }

    func testParseMinuteInvalidPrefix() {
        XCTAssertNil(TrackingLogic.parseMinute(from: "invalid_5"))
        XCTAssertNil(TrackingLogic.parseMinute(from: "min_5"))
        XCTAssertNil(TrackingLogic.parseMinute(from: "MINUTE_5"))
    }

    func testParseMinuteNoPrefix() {
        XCTAssertNil(TrackingLogic.parseMinute(from: "5"))
        XCTAssertNil(TrackingLogic.parseMinute(from: ""))
    }

    func testParseMinuteInvalidNumber() {
        XCTAssertNil(TrackingLogic.parseMinute(from: "minute_abc"))
        XCTAssertNil(TrackingLogic.parseMinute(from: "minute_"))
        XCTAssertNil(TrackingLogic.parseMinute(from: "minute_5.5"))
    }

    // MARK: - calculateDeduction Tests

    func testCalculateDeductionNormal() {
        // Minute 3, previously used 2, balance 10 → deduct 1
        let result = TrackingLogic.calculateDeduction(
            minute: 3,
            previousUsed: 2,
            currentBalance: 10
        )

        XCTAssertEqual(result.toDeduct, 1)
        XCTAssertEqual(result.newBalance, 9)
        XCTAssertFalse(result.shouldSkip)
        XCTAssertEqual(result.newMinutesUsed, 1)
    }

    func testCalculateDeductionMultipleMinutes() {
        // Minute 5, previously used 2, balance 10 → deduct 3
        let result = TrackingLogic.calculateDeduction(
            minute: 5,
            previousUsed: 2,
            currentBalance: 10
        )

        XCTAssertEqual(result.toDeduct, 3)
        XCTAssertEqual(result.newBalance, 7)
        XCTAssertFalse(result.shouldSkip)
        XCTAssertEqual(result.newMinutesUsed, 3)
    }

    func testCalculateDeductionSkipWhenEqual() {
        // Minute 3, previously used 3 → skip
        let result = TrackingLogic.calculateDeduction(
            minute: 3,
            previousUsed: 3,
            currentBalance: 10
        )

        XCTAssertTrue(result.shouldSkip)
        XCTAssertEqual(result.toDeduct, 0)
        XCTAssertEqual(result.newBalance, 10)
        XCTAssertEqual(result.newMinutesUsed, 0)
    }

    func testCalculateDeductionSkipWhenLess() {
        // Minute 2, previously used 5 → skip (out of order event)
        let result = TrackingLogic.calculateDeduction(
            minute: 2,
            previousUsed: 5,
            currentBalance: 10
        )

        XCTAssertTrue(result.shouldSkip)
        XCTAssertEqual(result.toDeduct, 0)
        XCTAssertEqual(result.newBalance, 10)
    }

    func testCalculateDeductionExhaustsBalance() {
        // Minute 10, previously used 0, balance 5 → deduct 5 (limited by balance)
        let result = TrackingLogic.calculateDeduction(
            minute: 10,
            previousUsed: 0,
            currentBalance: 5
        )

        XCTAssertEqual(result.toDeduct, 5)
        XCTAssertEqual(result.newBalance, 0)
        XCTAssertFalse(result.shouldSkip)
        XCTAssertEqual(result.newMinutesUsed, 10)
    }

    func testCalculateDeductionZeroBalance() {
        // Minute 5, previously used 0, balance 0 → deduct 0
        let result = TrackingLogic.calculateDeduction(
            minute: 5,
            previousUsed: 0,
            currentBalance: 0
        )

        XCTAssertEqual(result.toDeduct, 0)
        XCTAssertEqual(result.newBalance, 0)
        XCTAssertFalse(result.shouldSkip)
        XCTAssertEqual(result.newMinutesUsed, 5)
    }

    func testCalculateDeductionFirstMinute() {
        // Minute 1, previously used 0, balance 60 → deduct 1
        let result = TrackingLogic.calculateDeduction(
            minute: 1,
            previousUsed: 0,
            currentBalance: 60
        )

        XCTAssertEqual(result.toDeduct, 1)
        XCTAssertEqual(result.newBalance, 59)
        XCTAssertFalse(result.shouldSkip)
        XCTAssertEqual(result.newMinutesUsed, 1)
    }

    // MARK: - shouldApplyShield Tests

    func testShouldApplyShieldWhenZero() {
        XCTAssertTrue(TrackingLogic.shouldApplyShield(balance: 0))
    }

    func testShouldApplyShieldWhenNegative() {
        XCTAssertTrue(TrackingLogic.shouldApplyShield(balance: -1))
    }

    func testShouldNotApplyShieldWhenPositive() {
        XCTAssertFalse(TrackingLogic.shouldApplyShield(balance: 1))
        XCTAssertFalse(TrackingLogic.shouldApplyShield(balance: 60))
    }

    // MARK: - DeductionResult Equatable

    func testDeductionResultEquatable() {
        let result1 = TrackingLogic.DeductionResult(toDeduct: 1, newBalance: 9, shouldSkip: false, newMinutesUsed: 1)
        let result2 = TrackingLogic.DeductionResult(toDeduct: 1, newBalance: 9, shouldSkip: false, newMinutesUsed: 1)
        let result3 = TrackingLogic.DeductionResult(toDeduct: 2, newBalance: 9, shouldSkip: false, newMinutesUsed: 1)

        XCTAssertEqual(result1, result2)
        XCTAssertNotEqual(result1, result3)
    }
}
