import Foundation
import SwiftData

/// A recorded breathing session with HRV measurements
@Model
final class SessionRecord {
    /// Unique identifier
    var id: UUID

    /// When the session started
    var startDate: Date

    /// When the session ended
    var endDate: Date

    /// Number of breathing cycles completed
    var cyclesCompleted: Int

    /// Total duration in seconds
    var duration: TimeInterval

    /// HRV (SDNN in milliseconds) measured before session (if available)
    var hrvBefore: Double?

    /// HRV (SDNN in milliseconds) measured after session (if available)
    var hrvAfter: Double?

    /// Average heart rate during session (if available)
    var averageHeartRate: Double?

    /// Whether the session was synced to HealthKit
    var syncedToHealthKit: Bool

    /// Source device (watch/phone)
    var sourceDevice: String?

    init(
        startDate: Date,
        endDate: Date,
        cyclesCompleted: Int,
        duration: TimeInterval,
        hrvBefore: Double? = nil,
        hrvAfter: Double? = nil,
        averageHeartRate: Double? = nil,
        syncedToHealthKit: Bool = false,
        sourceDevice: String? = nil
    ) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.cyclesCompleted = cyclesCompleted
        self.duration = duration
        self.hrvBefore = hrvBefore
        self.hrvAfter = hrvAfter
        self.averageHeartRate = averageHeartRate
        self.syncedToHealthKit = syncedToHealthKit
        self.sourceDevice = sourceDevice
    }

    // MARK: - Computed Properties

    /// HRV improvement percentage (positive = improvement)
    var hrvImprovement: Double? {
        guard let before = hrvBefore, let after = hrvAfter, before > 0 else {
            return nil
        }
        return ((after - before) / before) * 100
    }

    /// Formatted duration string (e.g., "1:16")
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Day of session for grouping
    var dayOfSession: Date {
        Calendar.current.startOfDay(for: startDate)
    }
}

// MARK: - Statistics Helper

extension Array where Element == SessionRecord {
    /// Total practice time in seconds
    var totalDuration: TimeInterval {
        reduce(0) { $0 + $1.duration }
    }

    /// Total cycles completed
    var totalCycles: Int {
        reduce(0) { $0 + $1.cyclesCompleted }
    }

    /// Average HRV improvement across sessions with data
    var averageHRVImprovement: Double? {
        let improvements = compactMap { $0.hrvImprovement }
        guard !improvements.isEmpty else { return nil }
        return improvements.reduce(0, +) / Double(improvements.count)
    }

    /// Sessions grouped by day
    var groupedByDay: [Date: [SessionRecord]] {
        Dictionary(grouping: self) { $0.dayOfSession }
    }

    /// Current streak (consecutive days with practice)
    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let uniqueDays = Set(map { calendar.startOfDay(for: $0.startDate) }).sorted(by: >)

        guard !uniqueDays.isEmpty else { return 0 }

        var streak = 0
        var expectedDate = today

        // Check if practiced today or yesterday
        if let firstDay = uniqueDays.first {
            let daysDiff = calendar.dateComponents([.day], from: firstDay, to: today).day ?? 0
            if daysDiff > 1 {
                return 0 // Streak broken
            }
            expectedDate = firstDay
        }

        for day in uniqueDays {
            if day == expectedDate {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
            } else {
                break
            }
        }

        return streak
    }

    /// Sessions from the last 7 days
    var lastWeek: [SessionRecord] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return filter { $0.startDate >= weekAgo }
    }

    /// Sessions from the last 30 days
    var lastMonth: [SessionRecord] {
        let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return filter { $0.startDate >= monthAgo }
    }

    /// Average heart rate across sessions with data
    var averageHeartRateValue: Double? {
        let values = compactMap { $0.averageHeartRate }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}
