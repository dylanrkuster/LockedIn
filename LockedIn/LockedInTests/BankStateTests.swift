//
//  BankStateTests.swift
//  LockedInTests
//
//  Unit tests for BankState model.
//

import XCTest
@testable import LockedIn

final class BankStateTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset SharedState before each test
        SharedState.balance = 0
        SharedState.difficultyRaw = "MEDIUM"
        SharedState.synchronize()
    }

    override func tearDown() {
        SharedState.balance = 0
        SharedState.difficultyRaw = "MEDIUM"
        SharedState.synchronize()
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitWithExplicitValues() {
        let state = BankState(balance: 50, difficulty: .hard)

        XCTAssertEqual(state.balance, 50)
        XCTAssertEqual(state.difficulty, .hard)
        XCTAssertEqual(state.maxBalance, 120)
    }

    func testInitClampsBalanceToMax() {
        // Easy has maxBalance of 240, so 300 should clamp to 240
        let state = BankState(balance: 300, difficulty: .easy)

        XCTAssertEqual(state.balance, 240)
    }

    func testInitClampsNegativeBalanceToZero() {
        let state = BankState(balance: -10, difficulty: .medium)

        XCTAssertEqual(state.balance, 0)
    }

    func testInitWithTransactions() {
        let transactions = [
            Transaction(id: UUID(), amount: 10, source: "Test", timestamp: Date())
        ]
        let state = BankState(balance: 50, difficulty: .medium, transactions: transactions)

        XCTAssertEqual(state.transactions.count, 1)
    }

    // MARK: - Progress Calculation

    func testProgressAtZero() {
        let state = BankState(balance: 0, difficulty: .medium)

        XCTAssertEqual(state.progress, 0.0)
    }

    func testProgressAtMax() {
        let state = BankState(balance: 180, difficulty: .medium)

        XCTAssertEqual(state.progress, 1.0)
    }

    func testProgressAtHalf() {
        let state = BankState(balance: 90, difficulty: .medium)

        XCTAssertEqual(state.progress, 0.5, accuracy: 0.001)
    }

    func testProgressClampedToOne() {
        // Even if somehow balance exceeds max, progress should be 1.0
        let state = BankState(balance: 180, difficulty: .medium)
        XCTAssertEqual(state.progress, 1.0)
    }

    // MARK: - isLocked Tests

    func testIsLockedWhenZero() {
        let state = BankState(balance: 0, difficulty: .medium)

        XCTAssertTrue(state.isLocked)
    }

    func testIsNotLockedWhenPositive() {
        let state = BankState(balance: 1, difficulty: .medium)

        XCTAssertFalse(state.isLocked)
    }

    func testIsNotLockedWithHighBalance() {
        let state = BankState(balance: 100, difficulty: .medium)

        XCTAssertFalse(state.isLocked)
    }

    // MARK: - Earn Tests

    func testEarnAddsToBalance() {
        let state = BankState(balance: 50, difficulty: .medium)

        state.earn(workoutMinutes: 30, source: "Run")

        // Medium difficulty: 1:1 ratio, so 30 workout = 30 screen
        XCTAssertEqual(state.balance, 80)
    }

    func testEarnWithEasyDifficulty() {
        let state = BankState(balance: 50, difficulty: .easy)

        state.earn(workoutMinutes: 30, source: "Run")

        // Easy difficulty: 1:2 ratio, so 30 workout = 60 screen
        XCTAssertEqual(state.balance, 110)
    }

    func testEarnWithHardDifficulty() {
        let state = BankState(balance: 50, difficulty: .hard)

        state.earn(workoutMinutes: 30, source: "Run")

        // Hard difficulty: 2:1 ratio, so 30 workout = 15 screen
        XCTAssertEqual(state.balance, 65)
    }

    func testEarnWithExtremeDifficulty() {
        let state = BankState(balance: 30, difficulty: .extreme)

        state.earn(workoutMinutes: 30, source: "Run")

        // Extreme difficulty: 3:1 ratio, so 30 workout = 10 screen
        XCTAssertEqual(state.balance, 40)
    }

    func testEarnCappedAtMax() {
        let state = BankState(balance: 170, difficulty: .medium)

        state.earn(workoutMinutes: 30, source: "Run")

        // Would be 200, but capped at 180
        XCTAssertEqual(state.balance, 180)
    }

    func testEarnCreatesTransaction() {
        let state = BankState(balance: 50, difficulty: .medium)
        let initialCount = state.transactions.count

        state.earn(workoutMinutes: 30, source: "Run")

        XCTAssertEqual(state.transactions.count, initialCount + 1)
        XCTAssertEqual(state.transactions.last?.source, "Run")
        XCTAssertTrue(state.transactions.last?.amount ?? 0 > 0)
    }

    func testEarnDoesNothingWhenAlreadyAtMax() {
        let state = BankState(balance: 180, difficulty: .medium)
        let initialCount = state.transactions.count

        state.earn(workoutMinutes: 30, source: "Run")

        // Balance should stay at max, no transaction added
        XCTAssertEqual(state.balance, 180)
        XCTAssertEqual(state.transactions.count, initialCount)
    }

    // MARK: - Spend Tests

    func testSpendDeductsFromBalance() {
        let state = BankState(balance: 50, difficulty: .medium)

        state.spend(20, source: "Instagram")

        XCTAssertEqual(state.balance, 30)
    }

    func testSpendCantGoNegative() {
        let state = BankState(balance: 10, difficulty: .medium)

        state.spend(50, source: "TikTok")

        XCTAssertEqual(state.balance, 0)
    }

    func testSpendCreatesTransaction() {
        let state = BankState(balance: 50, difficulty: .medium)
        let initialCount = state.transactions.count

        state.spend(20, source: "Instagram")

        XCTAssertEqual(state.transactions.count, initialCount + 1)
        XCTAssertEqual(state.transactions.last?.source, "Instagram")
        XCTAssertEqual(state.transactions.last?.amount, -20)
    }

    func testSpendDoesNothingWhenAlreadyZero() {
        let state = BankState(balance: 0, difficulty: .medium)
        let initialCount = state.transactions.count

        state.spend(10, source: "Test")

        XCTAssertEqual(state.balance, 0)
        XCTAssertEqual(state.transactions.count, initialCount)
    }

    func testSpendWithZeroMinutes() {
        let state = BankState(balance: 50, difficulty: .medium)
        let initialCount = state.transactions.count

        state.spend(0, source: "Test")

        XCTAssertEqual(state.balance, 50)
        XCTAssertEqual(state.transactions.count, initialCount)
    }

    // MARK: - Recent Transactions

    func testRecentTransactionsSortedByTimestamp() {
        let now = Date()
        let older = now.addingTimeInterval(-3600)
        let oldest = now.addingTimeInterval(-7200)

        let state = BankState(
            balance: 50,
            difficulty: .medium,
            transactions: [
                Transaction(id: UUID(), amount: 10, source: "First", timestamp: oldest),
                Transaction(id: UUID(), amount: 20, source: "Second", timestamp: now),
                Transaction(id: UUID(), amount: 15, source: "Third", timestamp: older)
            ]
        )

        let recent = state.recentTransactions

        XCTAssertEqual(recent[0].source, "Second")  // Most recent
        XCTAssertEqual(recent[1].source, "Third")
        XCTAssertEqual(recent[2].source, "First")   // Oldest
    }

    // MARK: - Max Balance

    func testMaxBalanceMatchesDifficulty() {
        let easyState = BankState(balance: 0, difficulty: .easy)
        let mediumState = BankState(balance: 0, difficulty: .medium)
        let hardState = BankState(balance: 0, difficulty: .hard)
        let extremeState = BankState(balance: 0, difficulty: .extreme)

        XCTAssertEqual(easyState.maxBalance, 240)
        XCTAssertEqual(mediumState.maxBalance, 180)
        XCTAssertEqual(hardState.maxBalance, 120)
        XCTAssertEqual(extremeState.maxBalance, 60)
    }

    // MARK: - Difficulty Change

    func testChangingDifficultyReclampsBalance() {
        let state = BankState(balance: 180, difficulty: .medium)
        XCTAssertEqual(state.balance, 180)

        // Change to hard (max 120)
        state.difficulty = .hard

        // Balance should be clamped to new max
        XCTAssertEqual(state.balance, 120)
    }

    func testChangingToHigherMaxPreservesBalance() {
        // Hard (max 120) to Easy (max 240)
        let state = BankState(balance: 100, difficulty: .hard)
        XCTAssertEqual(state.balance, 100)

        state.difficulty = .easy

        // Balance unchanged since under new max
        XCTAssertEqual(state.balance, 100)
        XCTAssertEqual(state.maxBalance, 240)
    }

    func testChangingToLowerMaxWithBalanceUnderNewMax() {
        // Easy (max 240) with 50 min to Extreme (max 60)
        let state = BankState(balance: 50, difficulty: .easy)
        XCTAssertEqual(state.balance, 50)

        state.difficulty = .extreme

        // Balance unchanged since under new max
        XCTAssertEqual(state.balance, 50)
        XCTAssertEqual(state.maxBalance, 60)
    }

    func testChangingToLowerMaxWithBalanceOverNewMax() {
        // Easy (max 240) with 200 min to Hard (max 120)
        let state = BankState(balance: 200, difficulty: .easy)
        XCTAssertEqual(state.balance, 200)

        state.difficulty = .hard

        // Balance clamped to new max
        XCTAssertEqual(state.balance, 120)
        XCTAssertEqual(state.maxBalance, 120)
    }

    func testChangingToSameDifficultyNoOp() {
        let state = BankState(balance: 100, difficulty: .medium)

        state.difficulty = .medium

        // No change
        XCTAssertEqual(state.balance, 100)
        XCTAssertEqual(state.difficulty, .medium)
    }

    func testChangingDifficultyFromExtremeToEasy() {
        // Extreme (max 60) to Easy (max 240) - balance should stay same
        let state = BankState(balance: 60, difficulty: .extreme)
        XCTAssertEqual(state.balance, 60)

        state.difficulty = .easy

        XCTAssertEqual(state.balance, 60)
        XCTAssertEqual(state.maxBalance, 240)
    }

    func testChangingDifficultyFromEasyToExtreme() {
        // Easy (max 240) with 200 min to Extreme (max 60)
        let state = BankState(balance: 200, difficulty: .easy)

        state.difficulty = .extreme

        // Balance clamped to 60
        XCTAssertEqual(state.balance, 60)
    }
}
