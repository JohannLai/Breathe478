import SwiftUI

/// View shown after completing a breathing session
struct CompletionView: View {
    @ObservedObject var viewModel: BreathingViewModel
    let onRepeat: () -> Void
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Success icon
                ZStack {
                    Circle()
                        .fill(Theme.primaryGradient)
                        .frame(width: 44, height: 44)

                    Image(systemName: "checkmark")
                        .font(.title3.bold())
                        .foregroundColor(.black)
                }

                // Completion text
                Text(String(localized: "Session Complete"))
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)

                // Session stats
                VStack(spacing: 6) {
                    StatRow(
                        icon: "repeat",
                        label: String(localized: "Cycles"),
                        value: "\(viewModel.currentCycle)"
                    )

                    StatRow(
                        icon: "clock",
                        label: String(localized: "Duration"),
                        value: viewModel.formattedDuration
                    )

                    // HRV Data (if available)
                    if let hrvAfter = viewModel.hrvAfter {
                        StatRow(
                            icon: "waveform.path.ecg",
                            label: "HRV",
                            value: String(format: "%.0f ms", hrvAfter)
                        )
                    }

                    // HRV Improvement
                    if let improvement = viewModel.hrvImprovement {
                        HRVImprovementRow(improvement: improvement)
                    }

                    // Average Heart Rate
                    if let avgHR = viewModel.averageHeartRate {
                        StatRow(
                            icon: "heart.fill",
                            label: String(localized: "Avg HR"),
                            value: String(format: "%.0f bpm", avgHR)
                        )
                    }
                }
                .padding(10)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Measuring indicator
                if viewModel.isMeasuringHRV {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text(String(localized: "Measuring HRV..."))
                            .font(.caption2)
                            .foregroundColor(Theme.textTertiary)
                    }
                }

                // Saved indicator
                if viewModel.sessionSaved {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text(String(localized: "Saved to Health"))
                            .font(.caption2)
                            .foregroundColor(Theme.textTertiary)
                    }
                }

                // Action buttons
                VStack(spacing: 8) {
                    Button(action: onRepeat) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text(String(localized: "Repeat"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .primaryButtonStyle()

                    Button(action: onDone) {
                        Text(String(localized: "Done"))
                            .frame(maxWidth: .infinity)
                    }
                    .secondaryButtonStyle()
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 8)
        }
        .background(Theme.backgroundColor)
    }
}

/// HRV improvement display row
struct HRVImprovementRow: View {
    let improvement: Double

    var body: some View {
        HStack {
            Image(systemName: improvement >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.caption)
                .foregroundColor(improvement >= 0 ? .green : .orange)
                .frame(width: 20)

            Text(String(localized: "HRV Change"))
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Theme.textSecondary)

            Spacer()

            Text(String(format: "%+.1f%%", improvement))
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundColor(improvement >= 0 ? .green : .orange)
        }
    }
}

/// A row displaying a statistic with icon
struct StatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Theme.primaryMint)
                .frame(width: 20)

            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Theme.textSecondary)

            Spacer()

            Text(value)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundColor(Theme.textPrimary)
        }
    }
}

#Preview {
    CompletionView(viewModel: BreathingViewModel(), onRepeat: { }, onDone: { })
}
