import SwiftUI
import SwiftData
import Charts

/// Detailed HRV analysis view
struct HRVDetailView: View {
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

                // Main HRV Chart
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Heart Rate Variability")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(Theme.textPrimary)

                            if let currentHRV = latestHRV {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(String(format: "%.0f", currentHRV))
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundColor(Theme.primaryMint)

                                    Text("ms")
                                        .font(.system(.body, design: .rounded))
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }
                        }

                        Spacer()

                        if let trend = hrvTrend {
                            TrendBadge(trend: trend)
                        }
                    }

                    if hrvData.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "applewatch")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.textTertiary)

                            Text("Apple Watch Required")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(Theme.textSecondary)

                            Text("HRV data is measured by Apple Watch.\nComplete breathing sessions on your Watch.")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(Theme.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                    } else {
                        Chart(hrvData) { dataPoint in
                            LineMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("HRV", dataPoint.value)
                            )
                            .foregroundStyle(Theme.primaryMint)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2))

                            AreaMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("HRV", dataPoint.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Theme.primaryMint.opacity(0.4), Theme.primaryMint.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("HRV", dataPoint.value)
                            )
                            .foregroundStyle(Theme.primaryMint)
                            .symbolSize(30)
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
                        .chartYScale(domain: hrvRange)
                        .frame(height: 200)
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)

                // Before/After Comparison
                if !filteredSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Before & After Sessions")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(Theme.textPrimary)

                        Chart(beforeAfterData) { item in
                            BarMark(
                                x: .value("Session", item.sessionIndex),
                                y: .value("HRV", item.value)
                            )
                            .foregroundStyle(item.type == .before ?
                                Color.gray.opacity(0.5) : Theme.primaryMint)
                            .position(by: .value("Type", item.type.rawValue))
                        }
                        .chartXAxis {
                            AxisMarks { _ in
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
                        .chartLegend {
                            HStack(spacing: 16) {
                                LegendItem(color: Color.gray.opacity(0.5), label: "Before")
                                LegendItem(color: Theme.primaryMint, label: "After")
                            }
                        }
                        .frame(height: 160)
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                }

                // Statistics
                VStack(alignment: .leading, spacing: 16) {
                    Text("Statistics")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(Theme.textPrimary)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatBox(
                            label: "Average",
                            value: averageHRV,
                            icon: "equal"
                        )

                        StatBox(
                            label: "Highest",
                            value: highestHRV,
                            icon: "arrow.up"
                        )

                        StatBox(
                            label: "Lowest",
                            value: lowestHRV,
                            icon: "arrow.down"
                        )

                        StatBox(
                            label: "Avg Change",
                            value: avgChange,
                            icon: "arrow.up.right"
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
                            .foregroundColor(Theme.primaryMint)
                        Text("About HRV")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                    }

                    Text("Heart Rate Variability (HRV) measures the variation in time between heartbeats. Higher HRV generally indicates better cardiovascular fitness and stress resilience. Regular breathing exercises can help improve your HRV over time.")
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
        .navigationTitle("HRV Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Computed Properties

    private var filteredSessions: [SessionRecord] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        return sessions.filter { $0.startDate >= cutoffDate }
    }

    private var hrvData: [HRVDataPoint] {
        filteredSessions
            .filter { $0.hrvAfter != nil }
            .map { HRVDataPoint(date: $0.startDate, value: $0.hrvAfter ?? 0) }
            .sorted { $0.date < $1.date }
    }

    private var hrvRange: ClosedRange<Double> {
        let values = hrvData.map { $0.value }
        guard let min = values.min(), let max = values.max() else {
            return 0...100
        }
        let padding = (max - min) * 0.1
        return (min - padding)...(max + padding)
    }

    private var latestHRV: Double? {
        filteredSessions.first?.hrvAfter
    }

    private var hrvTrend: Double? {
        let recentSessions = Array(filteredSessions.prefix(5))
        let olderSessions = Array(filteredSessions.dropFirst(5).prefix(5))

        let recentAvg = recentSessions.compactMap { $0.hrvAfter }.reduce(0, +) / max(1, Double(recentSessions.compactMap { $0.hrvAfter }.count))
        let olderAvg = olderSessions.compactMap { $0.hrvAfter }.reduce(0, +) / max(1, Double(olderSessions.compactMap { $0.hrvAfter }.count))

        guard olderAvg > 0 else { return nil }
        return ((recentAvg - olderAvg) / olderAvg) * 100
    }

    private var beforeAfterData: [BeforeAfterItem] {
        let recentSessions = Array(filteredSessions.prefix(5).reversed())
        var items = [BeforeAfterItem]()

        for (index, session) in recentSessions.enumerated() {
            if let before = session.hrvBefore {
                items.append(BeforeAfterItem(sessionIndex: index + 1, value: before, type: .before))
            }
            if let after = session.hrvAfter {
                items.append(BeforeAfterItem(sessionIndex: index + 1, value: after, type: .after))
            }
        }

        return items
    }

    private var averageHRV: String {
        let values = filteredSessions.compactMap { $0.hrvAfter }
        guard !values.isEmpty else { return "-" }
        return String(format: "%.0f ms", values.reduce(0, +) / Double(values.count))
    }

    private var highestHRV: String {
        guard let max = filteredSessions.compactMap({ $0.hrvAfter }).max() else { return "-" }
        return String(format: "%.0f ms", max)
    }

    private var lowestHRV: String {
        guard let min = filteredSessions.compactMap({ $0.hrvAfter }).min() else { return "-" }
        return String(format: "%.0f ms", min)
    }

    private var avgChange: String {
        let improvements = filteredSessions.compactMap { session -> Double? in
            guard let before = session.hrvBefore, let after = session.hrvAfter, before > 0 else { return nil }
            return ((after - before) / before) * 100
        }
        guard !improvements.isEmpty else { return "-" }
        let avg = improvements.reduce(0, +) / Double(improvements.count)
        return String(format: "%+.1f%%", avg)
    }
}

// MARK: - Supporting Types

struct BeforeAfterItem: Identifiable {
    let id = UUID()
    let sessionIndex: Int
    let value: Double
    let type: MeasurementType

    enum MeasurementType: String {
        case before = "Before"
        case after = "After"
    }
}

struct TrendBadge: View {
    let trend: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
            Text(String(format: "%+.1f%%", trend))
        }
        .font(.system(.caption, design: .rounded, weight: .medium))
        .foregroundColor(trend >= 0 ? .green : .orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((trend >= 0 ? Color.green : Color.orange).opacity(0.2))
        .clipShape(Capsule())
    }
}

struct StatBox: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Theme.primaryMint)

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

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Theme.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        HRVDetailView()
    }
    .preferredColorScheme(.dark)
}
