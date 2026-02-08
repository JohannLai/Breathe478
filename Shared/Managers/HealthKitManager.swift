import Foundation
import HealthKit

/// Manages HealthKit integration for HRV reading and mindful minutes - shared across iOS and watchOS
@MainActor
final class HealthKitManager: NSObject, ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    @Published var latestHRV: Double?
    @Published var authorizationError: String?

    // MARK: - HealthKit Types

    private let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession)!

    // We only need read access for HRV/HR and write access for Mindful Minutes
    private var typesToRead: Set<HKSampleType> {
        [hrvType, heartRateType, mindfulType]
    }

    private var typesToWrite: Set<HKSampleType> {
        [mindfulType]
    }

    #if os(watchOS)
    private var workoutTypesToWrite: Set<HKSampleType> {
        [mindfulType, HKQuantityType.workoutType()]
    }
    #endif

    #if os(watchOS)
    // MARK: - Workout Session (watchOS only)

    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    @Published var isWorkoutActive = false

    /// Start a workout session to activate heart rate sensor
    func startWorkoutSession() async {
        guard isHealthKitAvailable else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody
        configuration.locationType = .indoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()

            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            self.workoutSession = session
            self.workoutBuilder = builder

            session.delegate = self
            builder.delegate = self

            session.startActivity(with: Date())
            try await builder.beginCollection(at: Date())

            isWorkoutActive = true
        } catch {
            print("Failed to start workout session: \(error)")
        }
    }

    /// End the workout session
    func endWorkoutSession() async {
        guard let session = workoutSession, let builder = workoutBuilder else { return }

        session.end()

        do {
            try await builder.endCollection(at: Date())
            try await builder.finishWorkout()
        } catch {
            print("Failed to end workout session: \(error)")
        }

        workoutSession = nil
        workoutBuilder = nil
        isWorkoutActive = false
    }
    #endif

    private override init() {
        super.init()
    }

    // MARK: - Authorization

    /// Check if HealthKit is available on this device
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Request authorization to read HRV and write mindful sessions
    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            authorizationError = "HealthKit not available"
            return
        }

        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            isAuthorized = true
            authorizationError = nil
        } catch {
            authorizationError = error.localizedDescription
            isAuthorized = false
        }
    }

    // MARK: - HRV Reading

    /// Fetch the most recent HRV value
    func fetchLatestHRV() async -> Double? {
        guard isHealthKitAvailable else { return nil }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .hour, value: -24, to: Date()),
            end: Date(),
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard error == nil,
                      let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let hrv = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                continuation.resume(returning: hrv)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch HRV values for a date range
    func fetchHRVData(from startDate: Date, to endDate: Date) async -> [(date: Date, value: Double)] {
        guard isHealthKitAvailable else { return [] }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard error == nil, let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let results = samples.map { sample in
                    (
                        date: sample.startDate,
                        value: sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                    )
                }
                continuation.resume(returning: results)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch average heart rate for a time period
    /// Extends the window slightly to capture heart rate samples around the session
    func fetchAverageHeartRate(from startDate: Date, to endDate: Date) async -> Double? {
        guard isHealthKitAvailable else { return nil }

        // Extend window by 1 minute before and 2 minutes after to capture nearby HR samples
        let adjustedStart = startDate.addingTimeInterval(-60)
        let adjustedEnd = endDate.addingTimeInterval(120)

        let predicate = HKQuery.predicateForSamples(
            withStart: adjustedStart,
            end: adjustedEnd,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, error in
                guard error == nil,
                      let avgQuantity = statistics?.averageQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }

                let bpm = avgQuantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: bpm)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Mindful Session Writing

    /// Save a mindful session to HealthKit
    func saveMindfulSession(startDate: Date, endDate: Date) async -> Bool {
        guard isHealthKitAvailable else { return false }

        let mindfulSample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate
        )

        do {
            try await healthStore.save(mindfulSample)
            return true
        } catch {
            print("Failed to save mindful session: \(error)")
            return false
        }
    }

    // MARK: - Statistics

    /// Get total mindful minutes for a date range
    func fetchMindfulMinutes(from startDate: Date, to endDate: Date) async -> TimeInterval {
        guard isHealthKitAvailable else { return 0 }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: mindfulType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard error == nil, let samples = samples else {
                    continuation.resume(returning: 0)
                    return
                }

                let totalSeconds = samples.reduce(0.0) { total, sample in
                    total + sample.endDate.timeIntervalSince(sample.startDate)
                }
                continuation.resume(returning: totalSeconds)
            }

            healthStore.execute(query)
        }
    }
}

// MARK: - HRV Analysis

extension HealthKitManager {
    /// HRV interpretation based on general guidelines
    /// Note: HRV varies greatly by individual, age, and fitness level
    struct HRVInterpretation {
        let level: Level
        let description: String

        enum Level: String {
            case low = "Low"
            case moderate = "Moderate"
            case good = "Good"
            case excellent = "Excellent"
        }
    }

    /// Interpret an HRV value (simplified, for educational purposes)
    /// Real interpretation should consider personal baseline
    func interpretHRV(_ hrv: Double) -> HRVInterpretation {
        switch hrv {
        case ..<20:
            return HRVInterpretation(
                level: .low,
                description: String(localized: "HRV is below average. Regular practice may help improve it.")
            )
        case 20..<40:
            return HRVInterpretation(
                level: .moderate,
                description: String(localized: "HRV is in the moderate range. Keep practicing!")
            )
        case 40..<60:
            return HRVInterpretation(
                level: .good,
                description: String(localized: "Good HRV indicating healthy autonomic balance.")
            )
        default:
            return HRVInterpretation(
                level: .excellent,
                description: String(localized: "Excellent HRV! Your nervous system is well-regulated.")
            )
        }
    }
}

// MARK: - Workout Session Delegates (watchOS only)

#if os(watchOS)
extension HealthKitManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        // State changes handled via isWorkoutActive
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error)")
    }
}

extension HealthKitManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Not needed for our use case
    }

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        // Heart rate data is being collected automatically
    }
}
#endif
