//
//  SharedStateTests.swift
//  LockedInTests
//
//  Unit tests for SharedState.
//  Note: In tests, SharedState falls back to UserDefaults.standard
//  since App Groups aren't available in the test environment.
//

import XCTest
@testable import LockedIn

final class SharedStateTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset relevant keys before each test
        clearTestState()
    }

    override func tearDown() {
        // Clean up after each test
        clearTestState()
        super.tearDown()
    }

    private func clearTestState() {
        SharedState.balance = 0
        SharedState.difficultyRaw = "MEDIUM"
        SharedState.usedMinutesToday = 0
        SharedState.isMonitoring = false
        SharedState.extensionHeartbeat = nil
        SharedState.debugExtensionRunCount = 0
        SharedState.debugExtensionMessage = ""
        SharedState.synchronize()
    }

    // MARK: - Balance Tests

    func testBalanceGetSet() {
        SharedState.balance = 100
        XCTAssertEqual(SharedState.balance, 100)

        SharedState.balance = 0
        XCTAssertEqual(SharedState.balance, 0)

        SharedState.balance = 240
        XCTAssertEqual(SharedState.balance, 240)
    }

    func testBalanceDefaultsToZero() {
        clearTestState()
        // After clearing, balance should be 0
        XCTAssertEqual(SharedState.balance, 0)
    }

    // MARK: - Difficulty Tests

    func testDifficultyRawGetSet() {
        SharedState.difficultyRaw = "EASY"
        XCTAssertEqual(SharedState.difficultyRaw, "EASY")

        SharedState.difficultyRaw = "EXTREME"
        XCTAssertEqual(SharedState.difficultyRaw, "EXTREME")
    }

    func testMaxBalanceByDifficulty() {
        SharedState.difficultyRaw = "EASY"
        XCTAssertEqual(SharedState.maxBalance, 240)

        SharedState.difficultyRaw = "MEDIUM"
        XCTAssertEqual(SharedState.maxBalance, 180)

        SharedState.difficultyRaw = "HARD"
        XCTAssertEqual(SharedState.maxBalance, 120)

        SharedState.difficultyRaw = "EXTREME"
        XCTAssertEqual(SharedState.maxBalance, 60)
    }

    func testMaxBalanceDefaultsForInvalidDifficulty() {
        SharedState.difficultyRaw = "INVALID"
        // Should default to MEDIUM's max balance
        XCTAssertEqual(SharedState.maxBalance, 180)
    }

    // MARK: - Monitoring State Tests

    func testIsMonitoringGetSet() {
        SharedState.isMonitoring = true
        XCTAssertTrue(SharedState.isMonitoring)

        SharedState.isMonitoring = false
        XCTAssertFalse(SharedState.isMonitoring)
    }

    // MARK: - Heartbeat Tests

    func testHeartbeatGetSet() {
        let now = Date()
        SharedState.extensionHeartbeat = now

        XCTAssertNotNil(SharedState.extensionHeartbeat)
        XCTAssertEqual(
            SharedState.extensionHeartbeat!.timeIntervalSince1970,
            now.timeIntervalSince1970,
            accuracy: 1.0
        )
    }

    func testHeartbeatUpdateMethod() {
        let before = Date()
        SharedState.updateHeartbeat()
        let after = Date()

        XCTAssertNotNil(SharedState.extensionHeartbeat)
        XCTAssertGreaterThanOrEqual(SharedState.extensionHeartbeat!, before)
        XCTAssertLessThanOrEqual(SharedState.extensionHeartbeat!, after)
    }

    func testHeartbeatNotStaleWhenRecent() {
        SharedState.isMonitoring = true
        SharedState.updateHeartbeat()

        XCTAssertFalse(SharedState.isExtensionHeartbeatStale)
    }

    func testHeartbeatStaleWhenOld() {
        SharedState.isMonitoring = true
        // Set heartbeat to 3 minutes ago (stale threshold is 2 minutes)
        SharedState.extensionHeartbeat = Date().addingTimeInterval(-180)

        XCTAssertTrue(SharedState.isExtensionHeartbeatStale)
    }

    func testHeartbeatNotStaleWhenNotMonitoring() {
        SharedState.isMonitoring = false
        SharedState.extensionHeartbeat = Date().addingTimeInterval(-180)

        // Not stale because we're not monitoring
        XCTAssertFalse(SharedState.isExtensionHeartbeatStale)
    }

    func testHeartbeatStaleWhenNilAndMonitoring() {
        SharedState.isMonitoring = true
        SharedState.extensionHeartbeat = nil

        XCTAssertTrue(SharedState.isExtensionHeartbeatStale)
    }

    // MARK: - Debug Tests

    func testDebugRunCountGetSet() {
        SharedState.debugExtensionRunCount = 0
        XCTAssertEqual(SharedState.debugExtensionRunCount, 0)

        SharedState.debugExtensionRunCount = 42
        XCTAssertEqual(SharedState.debugExtensionRunCount, 42)
    }

    func testDebugMessageGetSet() {
        SharedState.debugExtensionMessage = "test message"
        XCTAssertEqual(SharedState.debugExtensionMessage, "test message")
    }

    // MARK: - Default Starting Balance

    func testDefaultStartingBalance() {
        // Verify the constant exists and is reasonable
        XCTAssertGreaterThan(SharedState.defaultStartingBalance, 0)
    }

    // MARK: - Synchronize

    func testSynchronizeDoesNotCrash() {
        SharedState.balance = 50
        SharedState.synchronize()
        // Just verify it doesn't crash
        XCTAssertEqual(SharedState.balance, 50)
    }
}
