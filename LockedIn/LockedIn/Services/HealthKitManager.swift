//
//  HealthKitManager.swift
//  LockedIn
//
//  Manages HealthKit authorization, workout queries, and background observation.
//  Converts workout duration to earned screen time based on difficulty.
//

import Foundation
import HealthKit

@Observable
final class HealthKitManager {
    // MARK: - Properties

    private let healthStore = HKHealthStore()
    private var observerQuery: HKObserverQuery?

    /// Whether HealthKit authorization has been requested (not denied)
    /// Note: For read-only access, we can't reliably check status due to privacy.
    /// We optimistically attempt queries after requesting authorization.
    private(set) var authorizationRequested = false

    /// Callback invoked when new workouts are detected
    var onWorkoutsDetected: (([HKWorkout]) -> Void)?

    // MARK: - Init

    init() {
        // Authorization status for read-only access cannot be reliably checked
        // We'll optimistically attempt queries after requesting authorization

        // CRITICAL: Start observing immediately if user has completed onboarding.
        // This ensures workout detection works during background launches.
        // Without this, HealthKit wakes the app but the observer isn't ready.
        if SharedState.hasCompletedOnboarding {
            startObserving()
        }
    }

    deinit {
        stopObserving()
    }

    // MARK: - Authorization

    /// Request authorization to read workout data from HealthKit
    /// Note: For read-only access, HealthKit doesn't reveal whether user granted permission.
    /// We optimistically attempt queries after requesting authorization.
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let workoutType = HKObjectType.workoutType()

        try await healthStore.requestAuthorization(toShare: [], read: [workoutType])

        await MainActor.run {
            authorizationRequested = true
        }
    }

    // MARK: - Workout Queries

    /// Fetch workouts from the last 4 hours that haven't been processed yet
    func fetchNewWorkouts(excludingIDs processedIDs: Set<String>) async throws -> [HKWorkout] {
        let workoutType = HKObjectType.workoutType()
        let fourHoursAgo = Date().addingTimeInterval(-4 * 60 * 60)

        let predicate = HKQuery.predicateForSamples(
            withStart: fourHoursAgo,
            end: Date(),
            options: .strictEndDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = (samples as? [HKWorkout]) ?? []
                let newWorkouts = workouts.filter { workout in
                    !processedIDs.contains(workout.uuid.uuidString)
                }

                continuation.resume(returning: newWorkouts)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Background Observation

    /// Start observing for new workout data in background.
    /// IMPORTANT: This should be called as early as possible in the app lifecycle
    /// (ideally in App.init) to handle background launches from HealthKit.
    func startObserving() {
        guard observerQuery == nil else { return }

        let workoutType = HKObjectType.workoutType()

        observerQuery = HKObserverQuery(
            sampleType: workoutType,
            predicate: nil
        ) { [weak self] _, completionHandler, error in
            guard error == nil else {
                completionHandler()
                return
            }

            // Fetch and process new workouts
            // This runs even during background launches when UI isn't visible
            Task { [weak self] in
                guard let self else {
                    completionHandler()
                    return
                }

                do {
                    let processedIDs = SharedState.processedWorkoutIDs
                    let newWorkouts = try await self.fetchNewWorkouts(excludingIDs: processedIDs)

                    if !newWorkouts.isEmpty {
                        // Process workouts directly to SharedState (works in background)
                        Self.processWorkoutsToSharedState(newWorkouts)

                        // Also notify UI callback if set (for foreground updates)
                        await MainActor.run {
                            self.onWorkoutsDetected?(newWorkouts)
                        }
                    }
                } catch {
                    print("HealthKit observer query failed: \(error)")
                }

                completionHandler()
            }
        }

        if let query = observerQuery {
            healthStore.execute(query)

            // Enable background delivery
            healthStore.enableBackgroundDelivery(
                for: workoutType,
                frequency: .immediate
            ) { success, error in
                if let error {
                    print("Failed to enable HealthKit background delivery: \(error)")
                }
            }
        }
    }

    // MARK: - Background Processing

    /// Process workouts directly to SharedState without requiring BankState.
    /// This enables workout processing during background launches when the UI isn't loaded.
    private static func processWorkoutsToSharedState(_ workouts: [HKWorkout]) {
        let difficulty = Difficulty(rawValue: SharedState.difficultyRaw) ?? .medium
        let maxBalance = difficulty.maxBalance

        for workout in workouts {
            let workoutID = workout.uuid.uuidString

            // Skip if already processed
            guard !SharedState.processedWorkoutIDs.contains(workoutID) else { continue }

            let durationMinutes = Int(workout.duration / 60)
            guard durationMinutes > 0 else { continue }

            // Calculate earned minutes
            let earnedMinutes = Int(Double(durationMinutes) * difficulty.screenMinutesPerWorkoutMinute)
            let balanceBefore = SharedState.balance
            let newBalance = SharedState.atomicBalanceAdd(earnedMinutes, maxBalance: maxBalance)
            let actualEarned = newBalance - balanceBefore

            guard actualEarned > 0 else {
                // Still mark as processed even if bank was full
                SharedState.markWorkoutProcessed(workoutID)
                continue
            }

            // Create and persist transaction
            let source = displayName(for: workout.workoutActivityType)
            let transaction = TransactionRecord(
                amount: actualEarned,
                source: source,
                timestamp: workout.endDate
            )
            SharedState.appendTransaction(transaction)

            // Post notification if enabled
            if SharedState.notifyWorkoutSync {
                let potentialEarned = earnedMinutes
                if actualEarned < potentialEarned {
                    NotificationManager.postWorkoutSyncedCapped(earnedMinutes: actualEarned)
                } else {
                    NotificationManager.postWorkoutSynced(earnedMinutes: actualEarned)
                }
            }

            // Reset low-balance notification flags if balance now above thresholds
            SharedState.resetNotificationFlags(for: newBalance)

            // Mark as processed and increment count
            SharedState.markWorkoutProcessed(workoutID)
            SharedState.workoutCount += 1

            // Update last sync time
            SharedState.lastHealthKitSync = Date()
            SharedState.synchronize()
        }
    }

    /// Stop observing workout data
    func stopObserving() {
        if let query = observerQuery {
            healthStore.stop(query)
            observerQuery = nil
        }
    }

    // MARK: - Earning Calculation

    /// Calculate earned screen time minutes from a workout
    static func calculateEarnedMinutes(
        workout: HKWorkout,
        difficulty: Difficulty
    ) -> Int {
        let durationMinutes = workout.duration / 60.0
        guard durationMinutes > 0 else { return 0 }

        let earned = durationMinutes * difficulty.screenMinutesPerWorkoutMinute
        return Int(earned.rounded(.down))
    }

    /// Get display name for workout type
    static func displayName(for workoutType: HKWorkoutActivityType) -> String {
        switch workoutType {
        case .running:
            return "Run"
        case .walking:
            return "Walk"
        case .cycling:
            return "Cycling"
        case .functionalStrengthTraining, .traditionalStrengthTraining:
            return "Strength"
        case .highIntensityIntervalTraining:
            return "HIIT"
        case .yoga:
            return "Yoga"
        case .swimming:
            return "Swim"
        case .hiking:
            return "Hike"
        case .elliptical:
            return "Elliptical"
        case .rowing:
            return "Rowing"
        case .stairClimbing:
            return "Stairs"
        case .dance, .socialDance, .cardioDance:
            return "Dance"
        case .coreTraining:
            return "Core"
        case .flexibility:
            return "Stretch"
        case .pilates:
            return "Pilates"
        case .jumpRope:
            return "Jump Rope"
        case .kickboxing:
            return "Kickboxing"
        case .boxing:
            return "Boxing"
        case .martialArts:
            return "Martial Arts"
        default:
            return "Workout"
        }
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "HealthKit access not authorized"
        }
    }
}
