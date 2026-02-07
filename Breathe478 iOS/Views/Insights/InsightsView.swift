import SwiftUI
import SwiftData
import Charts

/// Main insights dashboard for iOS
struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SessionRecord.startDate, order: .reverse) private var sessions: [SessionRecord]

    @State private var selectedTimeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case all = "All Time"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .all: return 365 * 10
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Streak Card
                    StreakCard(sessions: sessions)

                    // Weekly Summary
                    WeeklySummaryCard(sessions: filteredSessions)

                    // HRV Trend Chart
                    NavigationLink(destination: HRVDetailView()) {
                        HRVTrendCard(sessions: filteredSessions, timeRange: selectedTimeRange)
                    }
                    .buttonStyle(.plain)

                    // Quick Stats
                    QuickStatsCard(sessions: sessions)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Theme.backgroundColor)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button(action: { selectedTimeRange = range }) {
                                HStack {
                                    Text(range.rawValue)
                                    if selectedTimeRange == range {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedTimeRange.rawValue)
                                .font(.system(.subheadline, design: .rounded))
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .foregroundColor(Theme.primaryMint)
                    }
                }
            }
        }
    }

    private var filteredSessions: [SessionRecord] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        return sessions.filter { $0.startDate >= cutoffDate }
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let sessions: [SessionRecord]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(Theme.textSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(currentStreak)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryMint)

                        Text(currentStreak == 1 ? "day" : "days")
                            .font(.system(.title3, design: .rounded))
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                Spacer()

                // Flame icon for streak
                if currentStreak > 0 {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                }
            }

            // Week view
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    let date = Calendar.current.date(byAdding: .day, value: -(6 - dayOffset), to: Date()) ?? Date()
                    let hasSession = hasSessionOn(date: date)

                    VStack(spacing: 4) {
                        Text(dayLabel(for: date))
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(Theme.textTertiary)

                        Circle()
                            .fill(hasSession ? Theme.primaryMint : Color.white.opacity(0.1))
                            .frame(width: 28, height: 28)
                            .overlay {
                                if hasSession {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.black)
                                }
                            }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var currentStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        var checkDate = Date()

        // Check if there's a session today first
        if !hasSessionOn(date: checkDate) {
            // If no session today, start checking from yesterday
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        while hasSessionOn(date: checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        return streak
    }

    private func hasSessionOn(date: Date) -> Bool {
        let calendar = Calendar.current
        return sessions.contains { calendar.isDate($0.startDate, inSameDayAs: date) }
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
}

// MARK: - HRV Trend Card

struct HRVTrendCard: View {
    let sessions: [SessionRecord]
    let timeRange: InsightsView.TimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HRV Trend")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(Theme.textPrimary)

                    if let avgHRV = averageHRV {
                        Text(String(format: "Avg: %.0f ms", avgHRV))
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.textTertiary)
            }

            if hrvData.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "applewatch")
                        .font(.system(size: 28))
                        .foregroundColor(Theme.textTertiary)
                    Text("Apple Watch Required")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                    Text("HRV data is measured by Apple Watch")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Theme.textTertiary)
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
            } else {
                Chart(hrvData) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("HRV", dataPoint.value)
                    )
                    .foregroundStyle(Theme.primaryMint)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("HRV", dataPoint.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.primaryMint.opacity(0.3), Theme.primaryMint.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel()
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel()
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .frame(height: 120)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var hrvData: [HRVDataPoint] {
        sessions
            .filter { $0.hrvAfter != nil }
            .map { HRVDataPoint(date: $0.startDate, value: $0.hrvAfter ?? 0) }
            .sorted { $0.date < $1.date }
    }

    private var averageHRV: Double? {
        let values = sessions.compactMap { $0.hrvAfter }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}

struct HRVDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - Weekly Summary Card

struct WeeklySummaryCard: View {
    let sessions: [SessionRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: 0) {
                SummaryItem(
                    icon: "figure.mind.and.body",
                    value: "\(sessions.count)",
                    label: "Sessions"
                )

                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.1))

                SummaryItem(
                    icon: "clock",
                    value: formattedTotalTime,
                    label: "Total Time"
                )

                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.1))

                SummaryItem(
                    icon: "repeat",
                    value: "\(totalCycles)",
                    label: "Cycles"
                )
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var totalCycles: Int {
        sessions.reduce(0) { $0 + $1.cyclesCompleted }
    }

    private var formattedTotalTime: String {
        let totalSeconds = sessions.reduce(0) { $0 + $1.duration }
        let minutes = Int(totalSeconds) / 60
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}

struct SummaryItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Theme.primaryMint)

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Stats Card

struct QuickStatsCard: View {
    let sessions: [SessionRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Time Stats")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(Theme.textPrimary)

            VStack(spacing: 12) {
                QuickStatRow(
                    icon: "calendar",
                    label: "First Session",
                    value: firstSessionDate
                )

                QuickStatRow(
                    icon: "trophy.fill",
                    label: "Longest Streak",
                    value: "\(longestStreak) days"
                )

                QuickStatRow(
                    icon: "heart.fill",
                    label: "Best HRV",
                    value: bestHRV
                )

                QuickStatRow(
                    icon: "arrow.up.right",
                    label: "Avg HRV Improvement",
                    value: avgHRVImprovement
                )
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var firstSessionDate: String {
        guard let first = sessions.last else { return "-" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: first.startDate)
    }

    private var longestStreak: Int {
        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedDates = sessions
            .map { calendar.startOfDay(for: $0.startDate) }
            .sorted()

        var uniqueDates = [Date]()
        for date in sortedDates {
            if uniqueDates.last != date {
                uniqueDates.append(date)
            }
        }

        var maxStreak = 1
        var currentStreak = 1

        for i in 1..<uniqueDates.count {
            let daysBetween = calendar.dateComponents([.day], from: uniqueDates[i-1], to: uniqueDates[i]).day ?? 0
            if daysBetween == 1 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        return maxStreak
    }

    private var bestHRV: String {
        guard let max = sessions.compactMap({ $0.hrvAfter }).max() else { return "-" }
        return String(format: "%.0f ms", max)
    }

    private var avgHRVImprovement: String {
        let improvements = sessions.compactMap { session -> Double? in
            guard let before = session.hrvBefore, let after = session.hrvAfter, before > 0 else { return nil }
            return ((after - before) / before) * 100
        }
        guard !improvements.isEmpty else { return "-" }
        let avg = improvements.reduce(0, +) / Double(improvements.count)
        return String(format: "%+.1f%%", avg)
    }
}

struct QuickStatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Theme.primaryMint)
                .frame(width: 24)

            Text(label)
                .font(.system(.body, design: .rounded))
                .foregroundColor(Theme.textSecondary)

            Spacer()

            Text(value)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundColor(Theme.textPrimary)
        }
    }
}

#Preview {
    InsightsView()
        .preferredColorScheme(.dark)
}
