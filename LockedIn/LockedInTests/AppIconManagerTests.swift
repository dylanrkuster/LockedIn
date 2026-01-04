//
//  AppIconManagerTests.swift
//  LockedInTests
//
//  Tests for AppIconManager icon name mapping.
//

import Testing
@testable import LockedIn

struct AppIconManagerTests {
    @Test func testIconNameForEasy() {
        #expect(AppIconManager.iconName(for: .easy) == "AppIcon-Easy")
    }

    @Test func testIconNameForMedium() {
        #expect(AppIconManager.iconName(for: .medium) == "AppIcon-Medium")
    }

    @Test func testIconNameForHard() {
        #expect(AppIconManager.iconName(for: .hard) == "AppIcon-Hard")
    }

    @Test func testIconNameForExtreme() {
        #expect(AppIconManager.iconName(for: .extreme) == "AppIcon-Extreme")
    }

    @Test func testAllDifficultiesHaveUniqueIconNames() {
        let iconNames = Difficulty.allCases.map { AppIconManager.iconName(for: $0) }
        let uniqueNames = Set(iconNames)
        #expect(iconNames.count == uniqueNames.count)
    }

    @Test func testIconNamesFollowNamingConvention() {
        for difficulty in Difficulty.allCases {
            let iconName = AppIconManager.iconName(for: difficulty)
            #expect(iconName.hasPrefix("AppIcon-"))
        }
    }
}
