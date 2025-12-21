import Foundation
import HealthKit

/// Manages HealthKit integration for HRV reading and mindful minutes
@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    @Published var latestHRV: Double?
    @Published var authorizationError: String?

    // MARK: - HealthKit Types

    private let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession)!

    private var typesToRead: Set<HKSampleType> {
        [hrvType, heartRateType]
    }

    private var typesToWrite: Set<HKSampleType> {
        [mindfulType]
    }

    private init() {}

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
    func fetchAverageHeartRate(from startDate: Date, to endDate: Date) async -> Double? {
        guard isHealthKitAvailable else { return nil }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
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
