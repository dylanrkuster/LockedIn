//
//  TrackingLogic.swift
//  LockedIn (Shared)
//
//  Pure functions for activity tracking logic.
//  Extracted from DeviceActivityMonitorExtension for testability.
//

import Foundation

/// Pure functions for activity tracking calculations.
/// These have no side effects and don't depend on SharedState.
enum TrackingLogic {

    /// Result of balance deduction calculation
    struct DeductionResult: Equatable {
        let toDeduct: Int
        let newBalance: Int
        let shouldSkip: Bool
        let newMinutesUsed: Int
    }

    /// Parse minute value from event name like "minute_5"
    /// - Parameter eventName: The raw event name string (e.g., "minute_5")
    /// - Returns: The minute value if parsing succeeds, nil otherwise
    static func parseMinute(from eventName: String) -> Int? {
        guard eventName.hasPrefix("minute_"),
              let minute = Int(eventName.dropFirst(7))
        else { return nil }
        return minute
    }

    /// Calculate balance deduction for a threshold event.
    /// - Parameters:
    ///   - minute: The minute value from the event (e.g., 5 for "minute_5")
    ///   - previousUsed: Previously tracked minutes used today
    ///   - currentBalance: Current bank balance
    /// - Returns: Deduction result with amounts and skip flag
    static func calculateDeduction(
        minute: Int,
        previousUsed: Int,
        currentBalance: Int
    ) -> DeductionResult {
        // Skip if not a new minute (avoid re-processing)
        guard minute > previousUsed else {
            return DeductionResult(
                toDeduct: 0,
                newBalance: currentBalance,
                shouldSkip: true,
                newMinutesUsed: 0
            )
        }

        // Calculate new usage since last processed event (usually 1 minute)
        let newMinutesUsed = minute - previousUsed

        // Deduct from balance (can't go below 0)
        let toDeduct = min(newMinutesUsed, currentBalance)
        let newBalance = max(0, currentBalance - toDeduct)

        return DeductionResult(
            toDeduct: toDeduct,
            newBalance: newBalance,
            shouldSkip: false,
            newMinutesUsed: newMinutesUsed
        )
    }

    /// Check if balance is exhausted and shield should be applied
    static func shouldApplyShield(balance: Int) -> Bool {
        balance <= 0
    }
}
