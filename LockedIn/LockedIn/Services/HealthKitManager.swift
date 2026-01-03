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

    /// Start observing for new workout data in background
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

            // Fetch new workouts and notify
            Task { @MainActor [weak self] in
                guard let self else {
                    completionHandler()
                    return
                }

                do {
                    let processedIDs = SharedState.processedWorkoutIDs
                    let newWorkouts = try await self.fetchNewWorkouts(excludingIDs: processedIDs)

                    if !newWorkouts.isEmpty {
                        self.onWorkoutsDetected?(newWorkouts)
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
            ) { _, _ in }
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
