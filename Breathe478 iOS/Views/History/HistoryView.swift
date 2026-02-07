import SwiftUI
import SwiftData

/// Session history list for iOS
struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SessionRecord.startDate, order: .reverse) private var sessions: [SessionRecord]

    @State private var selectedSession: SessionRecord?

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    EmptyHistoryView()
                } else {
                    List {
                        ForEach(groupedSessions, id: \.0) { date, daySessions in
                            Section {
                                ForEach(daySessions) { session in
                                    SessionRowView(session: session)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedSession = session
                                        }
                                }
                                .onDelete { indexSet in
                                    deleteSession(from: daySessions, at: indexSet)
                                }
                            } header: {
                                Text(sectionHeader(for: date))
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    .foregroundColor(Theme.textSecondary)
                                    .textCase(nil)
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.backgroundColor)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedSession) { session in
                SessionDetailSheet(session: session)
            }
        }
    }

    private var groupedSessions: [(Date, [SessionRecord])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startDate)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    private func sectionHeader(for date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    private func deleteSession(from daySessions: [SessionRecord], at offsets: IndexSet) {
        for index in offsets {
            let session = daySessions[index]
            modelContext.delete(session)
        }
        try? modelContext.save()
    }
}

// MARK: - Empty State

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 56))
                .foregroundColor(Theme.textTertiary)

            Text("No Sessions Yet")
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            Text("Complete your first breathing session to see it here.")
                .font(.system(.body, design: .rounded))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.backgroundColor)
    }
}

// MARK: - Session Row

struct SessionRowView: View {
    let session: SessionRecord

    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(alignment: .leading, spacing: 2) {
                Text(timeString)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(Theme.textPrimary)

                Text(durationString)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(Theme.textTertiary)
            }

            Spacer()

            // Stats
            HStack(spacing: 16) {
                // Cycles
                StatPill(icon: "repeat", value: "\(session.cyclesCompleted)")

                // HRV if available
                if let hrv = session.hrvAfter {
                    StatPill(icon: "waveform.path.ecg", value: String(format: "%.0f", hrv))
                }

                // Device indicator
                Image(systemName: session.sourceDevice == "iPhone" ? "iphone" : "applewatch")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textTertiary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(.vertical, 8)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: session.startDate)
    }

    private var durationString: String {
        let minutes = Int(session.duration) / 60
        let seconds = Int(session.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct StatPill: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(value)
                .font(.system(.caption, design: .rounded, weight: .medium))
        }
        .foregroundColor(Theme.textSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }
}

// MARK: - Session Detail Sheet

struct SessionDetailSheet: View {
    let session: SessionRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.primaryMint)

                        Text(dateString)
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)

                        Text(timeRangeString)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.top, 24)

                    // Stats card
                    VStack(spacing: 16) {
                        DetailRow(icon: "clock", label: "Duration", value: formattedDuration)
                        Divider().background(Color.white.opacity(0.1))

                        DetailRow(icon: "repeat", label: "Cycles", value: "\(session.cyclesCompleted)")
                        Divider().background(Color.white.opacity(0.1))

                        DetailRow(
                            icon: session.sourceDevice == "iPhone" ? "iphone" : "applewatch",
                            label: "Device",
                            value: session.sourceDevice ?? "Unknown"
                        )

                        if session.syncedToHealthKit {
                            Divider().background(Color.white.opacity(0.1))
                            DetailRow(icon: "heart.fill", label: "Health Sync", value: "Synced")
                        }
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                    // HRV card if available
                    if session.hrvBefore != nil || session.hrvAfter != nil {
                        VStack(spacing: 16) {
                            Text("Heart Rate Variability")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 0) {
                                VStack(spacing: 8) {
                                    Text("Before")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(Theme.textTertiary)

                                    if let before = session.hrvBefore {
                                        Text(String(format: "%.0f", before))
                                            .font(.system(.title2, design: .rounded, weight: .bold))
                                            .foregroundColor(Theme.textSecondary)
                                        Text("ms")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundColor(Theme.textTertiary)
                                    } else {
                                        Text("-")
                                            .font(.system(.title2, design: .rounded))
                                            .foregroundColor(Theme.textTertiary)
                                    }
                                }
                                .frame(maxWidth: .infinity)

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 20))
                                    .foregroundColor(Theme.textTertiary)

                                VStack(spacing: 8) {
                                    Text("After")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(Theme.textTertiary)

                                    if let after = session.hrvAfter {
                                        Text(String(format: "%.0f", after))
                                            .font(.system(.title2, design: .rounded, weight: .bold))
                                            .foregroundColor(Theme.primaryMint)
                                        Text("ms")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundColor(Theme.textTertiary)
                                    } else {
                                        Text("-")
                                            .font(.system(.title2, design: .rounded))
                                            .foregroundColor(Theme.textTertiary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }

                            if let improvement = hrvImprovement {
                                HStack {
                                    Image(systemName: improvement >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    Text(String(format: "%+.1f%% change", improvement))
                                }
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundColor(improvement >= 0 ? .green : .orange)
                                .padding(.top, 8)
                            }
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)
                    }

                    // Heart rate if available
                    if let avgHR = session.averageHeartRate {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                Text("Average Heart Rate")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                            }

                            Text(String(format: "%.0f bpm", avgHR))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 32)
                }
            }
            .background(Theme.backgroundColor)
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primaryMint)
                }
            }
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: session.startDate)
    }

    private var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: session.startDate)
        let end = formatter.string(from: session.endDate)
        return "\(start) - \(end)"
    }

    private var formattedDuration: String {
        let minutes = Int(session.duration) / 60
        let seconds = Int(session.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var hrvImprovement: Double? {
        guard let before = session.hrvBefore, let after = session.hrvAfter, before > 0 else {
            return nil
        }
        return ((after - before) / before) * 100
    }
}

struct DetailRow: View {
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
    HistoryView()
        .preferredColorScheme(.dark)
}
