import SwiftUI
import SwiftData
import Charts

/// Detailed Heart Rate analysis view
struct HeartRateDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SessionRecord.startDate, order: .reverse) private var sessions: [SessionRecord]

    @State private var selectedTimeRange: TimeRange = .month

    enum TimeRange: String, CaseIterable {
        case week = "7D"
        case month = "30D"
        case threeMonths = "3M"
        case year = "1Y"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Time range picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)

                // Main Heart Rate Chart
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Heart Rate")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(Theme.textPrimary)

                            if let currentHR = latestHeartRate {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(String(format: "%.0f", currentHR))
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundColor(.red)

                                    Text("bpm")
                                        .font(.system(.body, design: .rounded))
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }
                        }

                        Spacer()

                        if let trend = hrTrend {
                            HRTrendBadge(trend: trend)
                        }
                    }

                    if hrData.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.textTertiary)

                            Text("No Heart Rate Data")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(Theme.textSecondary)

                            Text("Heart rate is measured during\nbreathing sessions on Apple Watch.")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(Theme.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                    } else {
                        Chart(hrData) { dataPoint in
                            LineMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("HR", dataPoint.value)
                            )
                            .foregroundStyle(Color.red.opacity(0.8))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2))

                            AreaMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("HR", dataPoint.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.4), Color.red.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("HR", dataPoint.value)
                            )
                            .foregroundStyle(Color.red)
                            .symbolSize(30)
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Color.white.opacity(0.1))
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
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
                        .chartYScale(domain: hrRange)
                        .frame(height: 200)
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)

                // Statistics
                VStack(alignment: .leading, spacing: 16) {
                    Text("Statistics")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(Theme.textPrimary)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        HRStatBox(
                            label: "Average",
                            value: averageHR,
                            icon: "equal"
                        )

                        HRStatBox(
                            label: "Lowest",
                            value: lowestHR,
                            icon: "arrow.down"
                        )

                        HRStatBox(
                            label: "Highest",
                            value: highestHR,
                            icon: "arrow.up"
                        )

                        HRStatBox(
                            label: "Sessions",
                            value: "\(sessionsWithHR)",
                            icon: "number"
                        )
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)

                // Info card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.red.opacity(0.8))
                        Text("About Heart Rate")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                    }

                    Text("A lower resting heart rate generally indicates better cardiovascular fitness. During 4-7-8 breathing, your heart rate typically decreases as the parasympathetic nervous system activates, promoting relaxation.")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                        .lineSpacing(4)
                }
                .padding(20)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .padding(.top, 16)
        }
        .background(Theme.backgroundColor)
        .navigationTitle("Heart Rate")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Computed Properties

    private var filteredSessions: [SessionRecord] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        return sessions.filter { $0.startDate >= cutoffDate }
    }

    private var hrData: [HRVDataPoint] {
        filteredSessions
            .filter { $0.averageHeartRate != nil }
            .map { HRVDataPoint(date: $0.startDate, value: $0.averageHeartRate ?? 0) }
            .sorted { $0.date < $1.date }
    }

    private var hrRange: ClosedRange<Double> {
        let values = hrData.map { $0.value }
        guard let min = values.min(), let max = values.max() else {
            return 40...120
        }
        let padding = Swift.max(5, (max - min) * 0.15)
        return (min - padding)...(max + padding)
    }

    private var latestHeartRate: Double? {
        filteredSessions.first(where: { $0.averageHeartRate != nil })?.averageHeartRate
    }

    private var hrTrend: Double? {
        let recentSessions = Array(filteredSessions.prefix(5))
        let olderSessions = Array(filteredSessions.dropFirst(5).prefix(5))

        let recentValues = recentSessions.compactMap { $0.averageHeartRate }
        let olderValues = olderSessions.compactMap { $0.averageHeartRate }

        guard !recentValues.isEmpty, !olderValues.isEmpty else { return nil }

        let recentAvg = recentValues.reduce(0, +) / Double(recentValues.count)
        let olderAvg = olderValues.reduce(0, +) / Double(olderValues.count)

        guard olderAvg > 0 else { return nil }
        return ((recentAvg - olderAvg) / olderAvg) * 100
    }

    private var averageHR: String {
        let values = filteredSessions.compactMap { $0.averageHeartRate }
        guard !values.isEmpty else { return "-" }
        return String(format: "%.0f bpm", values.reduce(0, +) / Double(values.count))
    }

    private var highestHR: String {
        guard let max = filteredSessions.compactMap({ $0.averageHeartRate }).max() else { return "-" }
        return String(format: "%.0f bpm", max)
    }

    private var lowestHR: String {
        guard let min = filteredSessions.compactMap({ $0.averageHeartRate }).min() else { return "-" }
        return String(format: "%.0f bpm", min)
    }

    private var sessionsWithHR: Int {
        filteredSessions.filter { $0.averageHeartRate != nil }.count
    }
}

// MARK: - Supporting Views

struct HRTrendBadge: View {
    let trend: Double

    var body: some View {
        HStack(spacing: 4) {
            // For heart rate, lower is generally better
            Image(systemName: trend <= 0 ? "arrow.down.right" : "arrow.up.right")
            Text(String(format: "%+.1f%%", trend))
        }
        .font(.system(.caption, design: .rounded, weight: .medium))
        .foregroundColor(trend <= 0 ? .green : .orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((trend <= 0 ? Color.green : Color.orange).opacity(0.2))
        .clipShape(Capsule())
    }
}

struct HRStatBox: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.red.opacity(0.8))

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        HeartRateDetailView()
    }
    .preferredColorScheme(.dark)
}
