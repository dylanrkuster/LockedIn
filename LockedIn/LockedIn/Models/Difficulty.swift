//
//  Difficulty.swift
//  LockedIn
//

import Foundation

enum Difficulty: String, CaseIterable, Identifiable {
    case easy = "EASY"
    case medium = "MEDIUM"
    case hard = "HARD"
    case extreme = "EXTREME"

    var id: String { rawValue }

    /// Workout minutes required per 1 screen time minute
    var workoutMinutesPerScreenMinute: Double {
        switch self {
        case .easy: 0.5      // 1 workout = 2 screen
        case .medium: 1.0    // 1 workout = 1 screen
        case .hard: 2.0      // 2 workout = 1 screen
        case .extreme: 3.0   // 3 workout = 1 screen
        }
    }

    /// Screen time minutes earned per 1 workout minute
    var screenMinutesPerWorkoutMinute: Double {
        1.0 / workoutMinutesPerScreenMinute
    }

    /// Maximum bank balance in minutes
    var maxBalance: Int {
        switch self {
        case .easy: 240      // 4 hours
        case .medium: 180    // 3 hours
        case .hard: 120      // 2 hours
        case .extreme: 60    // 1 hour
        }
    }

    var tagline: String {
        switch self {
        case .easy: "I'm just getting started"
        case .medium: "Fair trade"
        case .hard: "I'm serious about this"
        case .extreme: "No excuses. No mercy."
        }
    }

    /// Starting balance for new users at this difficulty
    var startingBalance: Int {
        switch self {
        case .easy: 90
        case .medium: 60
        case .hard: 30
        case .extreme: 0
        }
    }

    /// Display string for the conversion ratio (workout:screen)
    /// e.g., "2:1" means 2 workout minutes = 1 screen minute
    var ratioDisplay: String {
        switch self {
        case .easy: "1:2"      // 1 workout = 2 screen
        case .medium: "1:1"    // 1 workout = 1 screen
        case .hard: "2:1"      // 2 workout = 1 screen
        case .extreme: "3:1"   // 3 workout = 1 screen
        }
    }
}
