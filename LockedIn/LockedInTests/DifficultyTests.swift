//
//  DifficultyTests.swift
//  LockedInTests
//
//  Unit tests for the Difficulty enum.
//

import XCTest
@testable import LockedIn

final class DifficultyTests: XCTestCase {

    // MARK: - Conversion Rates

    func testEasyConversionRate() {
        XCTAssertEqual(Difficulty.easy.workoutMinutesPerScreenMinute, 0.5)
    }

    func testMediumConversionRate() {
        XCTAssertEqual(Difficulty.medium.workoutMinutesPerScreenMinute, 1.0)
    }

    func testHardConversionRate() {
        XCTAssertEqual(Difficulty.hard.workoutMinutesPerScreenMinute, 2.0)
    }

    func testExtremeConversionRate() {
        XCTAssertEqual(Difficulty.extreme.workoutMinutesPerScreenMinute, 3.0)
    }

    // MARK: - Screen Minutes Per Workout (Inverse)

    func testEasyScreenMinutesPerWorkout() {
        // 1 workout minute = 2 screen minutes
        XCTAssertEqual(Difficulty.easy.screenMinutesPerWorkoutMinute, 2.0)
    }

    func testMediumScreenMinutesPerWorkout() {
        // 1 workout minute = 1 screen minute
        XCTAssertEqual(Difficulty.medium.screenMinutesPerWorkoutMinute, 1.0)
    }

    func testHardScreenMinutesPerWorkout() {
        // 1 workout minute = 0.5 screen minutes
        XCTAssertEqual(Difficulty.hard.screenMinutesPerWorkoutMinute, 0.5)
    }

    func testExtremeScreenMinutesPerWorkout() {
        // 1 workout minute = 0.33 screen minutes
        XCTAssertEqual(Difficulty.extreme.screenMinutesPerWorkoutMinute, 1.0 / 3.0, accuracy: 0.001)
    }

    func testScreenMinutesIsInverseOfWorkoutMinutes() {
        for difficulty in Difficulty.allCases {
            let product = difficulty.workoutMinutesPerScreenMinute * difficulty.screenMinutesPerWorkoutMinute
            XCTAssertEqual(product, 1.0, accuracy: 0.001, "Inverse relationship broken for \(difficulty)")
        }
    }

    // MARK: - Max Balance

    func testEasyMaxBalance() {
        XCTAssertEqual(Difficulty.easy.maxBalance, 240)
    }

    func testMediumMaxBalance() {
        XCTAssertEqual(Difficulty.medium.maxBalance, 180)
    }

    func testHardMaxBalance() {
        XCTAssertEqual(Difficulty.hard.maxBalance, 120)
    }

    func testExtremeMaxBalance() {
        XCTAssertEqual(Difficulty.extreme.maxBalance, 60)
    }

    // MARK: - Ratio Display

    func testEasyRatioDisplay() {
        XCTAssertEqual(Difficulty.easy.ratioDisplay, "1:2")
    }

    func testMediumRatioDisplay() {
        XCTAssertEqual(Difficulty.medium.ratioDisplay, "1:1")
    }

    func testHardRatioDisplay() {
        XCTAssertEqual(Difficulty.hard.ratioDisplay, "2:1")
    }

    func testExtremeRatioDisplay() {
        XCTAssertEqual(Difficulty.extreme.ratioDisplay, "3:1")
    }

    // MARK: - Taglines

    func testAllDifficultiesHaveTaglines() {
        for difficulty in Difficulty.allCases {
            XCTAssertFalse(difficulty.tagline.isEmpty, "\(difficulty) should have a tagline")
        }
    }

    // MARK: - Raw Values

    func testRawValuesAreUppercase() {
        XCTAssertEqual(Difficulty.easy.rawValue, "EASY")
        XCTAssertEqual(Difficulty.medium.rawValue, "MEDIUM")
        XCTAssertEqual(Difficulty.hard.rawValue, "HARD")
        XCTAssertEqual(Difficulty.extreme.rawValue, "EXTREME")
    }

    func testInitFromRawValue() {
        XCTAssertEqual(Difficulty(rawValue: "EASY"), .easy)
        XCTAssertEqual(Difficulty(rawValue: "MEDIUM"), .medium)
        XCTAssertEqual(Difficulty(rawValue: "HARD"), .hard)
        XCTAssertEqual(Difficulty(rawValue: "EXTREME"), .extreme)
        XCTAssertNil(Difficulty(rawValue: "invalid"))
    }
}
