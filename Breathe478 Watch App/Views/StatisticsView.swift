import SwiftUI
import SwiftData
import Charts

/// Main statistics view showing HRV trends and practice history
struct StatisticsView: View {
    @Query(sort: \SessionRecord.startDate, order: .reverse) private var sessions: [SessionRecord]
    @StateObject private var healthKitManager = HealthKitManager.shared

    @State private var hrvData: [(date: Date, value: Double)] = []
    @State private var selectedTimeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week = "7D"
        case month = "30D"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary Card
                SummaryCard(sessions: sessions)

                // HRV Chart
                HRVChartCard(
                    hrvData: hrvData,
                    sessions: filteredSessions,
                    timeRange: $selectedTimeRange
                )

                // Recent Sessions
                if !sessions.isEmpty {
                    RecentSessionsCard(sessions: Array(sessions.prefix(5)))
                }
            }
            .padding(.horizontal, 8)
        }
        .background(Theme.backgroundColor)
        .task {
            await loadHRVData()
        }
        .onChange(of: selectedTimeRange) { _, _ in
            Task {
                await loadHRVData()
            }
        }
    }

    private var filteredSessions: [SessionRecord] {
        let startDate = Calendar.current.date(
            byAdding: .day,
            value: -selectedTimeRange.days,
            to: Date()
        ) ?? Date()
        return sessions.filter { $0.startDate >= startDate }
    }

    private func loadHRVData() async {
        let startDate = Calendar.current.date(
            byAdding: .day,
            value: -selectedTimeRange.days,
            to: Date()
        ) ?? Date()
        hrvData = await healthKitManager.fetchHRVData(from: startDate, to: Date())
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let sessions: [SessionRecord]

    private var weekSessions: [SessionRecord] {
        sessions.lastWeek
    }

    var body: some View {
        VStack(spacing: 12) {
            // Streak
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(sessions.currentStreak)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text(String(localized: "day streak"))
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
            }

            Divider().background(Color.white.opacity(0.2))

            // Week stats
            HStack(spacing: 16) {
                StatItem(
                    value: "\(weekSessions.count)",
                    label: String(localized: "Sessions"),
                    icon: "figure.mind.and.body"
                )

                StatItem(
                    value: formatDuration(weekSessions.totalDuration),
                    label: String(localized: "Total Time"),
                    icon: "clock.fill"
                )

                if let avgImprovement = weekSessions.averageHRVImprovement {
                    StatItem(
                        value: String(format: "%+.0f%%", avgImprovement),
                        label: "HRV",
                        icon: "waveform.path.ecg"
                    )
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h\(remainingMinutes)m"
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Theme.primaryMint)
            Text(value)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - HRV Chart Card

struct HRVChartCard: View {
    let hrvData: [(date: Date, value: Double)]
    let sessions: [SessionRecord]
    @Binding var timeRange: StatisticsView.TimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("HRV")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                // Time range picker
                Picker("", selection: $timeRange) {
                    ForEach(StatisticsView.TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .labelsHidden()
                .frame(width: 60)
            }

            // Chart
            if !hrvData.isEmpty {
                Chart {
                    ForEach(hrvData, id: \.date) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("HRV", dataPoint.value)
                        )
                        .foregroundStyle(Theme.primaryGradient)
                        .lineStyle(StrokeStyle(lineWidth: 2))

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
                    }

                    // Session markers
                    ForEach(sessions, id: \.id) { session in
                        if let hrv = session.hrvAfter {
                            PointMark(
                                x: .value("Date", session.startDate),
                                y: .value("HRV", hrv)
                            )
                            .foregroundStyle(Theme.primaryCyan)
                            .symbolSize(30)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel()
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel()
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .frame(height: 100)
            } else {
                Text(String(localized: "No HRV data available"))
                    .font(.caption)
                    .foregroundColor(Theme.textTertiary)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
            }

            // Average HRV
            if !hrvData.isEmpty {
                let avgHRV = hrvData.map(\.value).reduce(0, +) / Double(hrvData.count)
                HStack {
                    Text(String(localized: "Average"))
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textTertiary)
                    Spacer()
                    Text(String(format: "%.0f ms", avgHRV))
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(Theme.primaryMint)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Recent Sessions Card

struct RecentSessionsCard: View {
    let sessions: [SessionRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Recent"))
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            ForEach(sessions, id: \.id) { session in
                SessionRow(session: session)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SessionRow: View {
    let session: SessionRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.startDate, style: .date)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Text("\(session.cyclesCompleted) cycles · \(session.formattedDuration)")
                    .font(.system(size: 9))
                    .foregroundColor(Theme.textTertiary)
            }

            Spacer()

            if let improvement = session.hrvImprovement {
                Text(String(format: "%+.0f%%", improvement))
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundColor(improvement >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    StatisticsView()
}
