import SwiftUI

/// Completion view for iOS after session ends
struct CompletionViewiOS: View {
    @ObservedObject var viewModel: BreathingViewModeliOS
    let onRepeat: () -> Void
    let onDone: () -> Void
    @State private var contentAppeared = false
    @State private var checkmarkAppeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                // Success animation with flower
                BreathingFlower(
                    scale: 0.5,
                    isAnimating: true,
                    phase: nil,
                    size: 120
                )
                .frame(width: 120, height: 120)
                .scaleEffect(contentAppeared ? 1 : 0.5)
                .opacity(contentAppeared ? 1 : 0)
                .overlay {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.primaryGradient)
                        .background(Circle().fill(Color.black).frame(width: 36, height: 36))
                        .scaleEffect(checkmarkAppeared ? 1 : 0)
                        .opacity(checkmarkAppeared ? 1 : 0)
                }

                // Completion text
                VStack(spacing: 8) {
                    Text("Session Complete")
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)

                    Text("Great job! You've completed your breathing practice.")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 15)

                // Stats card
                VStack(spacing: 16) {
                    StatRowLarge(
                        icon: "repeat",
                        label: "Cycles",
                        value: "\(viewModel.currentCycle)"
                    )

                    Divider()
                        .background(Color.white.opacity(0.1))

                    StatRowLarge(
                        icon: "clock",
                        label: "Duration",
                        value: viewModel.formattedDuration
                    )

                    if let hrvAfter = viewModel.hrvAfter {
                        Divider()
                            .background(Color.white.opacity(0.1))

                        StatRowLarge(
                            icon: "waveform.path.ecg",
                            label: "HRV",
                            value: String(format: "%.0f ms", hrvAfter)
                        )
                    }

                    if let improvement = viewModel.hrvImprovement {
                        Divider()
                            .background(Color.white.opacity(0.1))

                        HRVImprovementRowLarge(improvement: improvement)
                    }

                    if let avgHR = viewModel.averageHeartRate {
                        Divider()
                            .background(Color.white.opacity(0.1))

                        StatRowLarge(
                            icon: "heart.fill",
                            label: "Avg Heart Rate",
                            value: String(format: "%.0f bpm", avgHR)
                        )
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 20)

                // Measuring indicator
                if viewModel.isMeasuringHRV {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(Theme.textSecondary)
                        Text("Measuring HRV...")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Theme.textTertiary)
                    }
                    .opacity(contentAppeared ? 1 : 0)
                }

                // Saved indicator
                if viewModel.sessionSaved {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Saved to Health")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .opacity(contentAppeared ? 1 : 0)
                }

                Spacer(minLength: 24)

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: onRepeat) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Practice Again")
                        }
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)

                    Button(action: onDone) {
                        Text("Done")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 20)
            }
        }
        .background(Theme.backgroundColor)
        .onAppear {
            withAnimation(Theme.gentleAppear.delay(0.2)) {
                contentAppeared = true
            }
            withAnimation(Theme.gentleAppear.delay(0.5)) {
                checkmarkAppeared = true
            }
        }
        .onDisappear {
            contentAppeared = false
            checkmarkAppeared = false
        }
    }
}

/// Large stat row for completion view
struct StatRowLarge: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Theme.primaryMint)
                .frame(width: 28)

            Text(label)
                .font(.system(.body, design: .rounded))
                .foregroundColor(Theme.textSecondary)

            Spacer()

            Text(value)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
        }
    }
}

/// HRV improvement row
struct HRVImprovementRowLarge: View {
    let improvement: Double

    var body: some View {
        HStack {
            Image(systemName: improvement >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 18))
                .foregroundColor(improvement >= 0 ? .green : .orange)
                .frame(width: 28)

            Text("HRV Change")
                .font(.system(.body, design: .rounded))
                .foregroundColor(Theme.textSecondary)

            Spacer()

            Text(String(format: "%+.1f%%", improvement))
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundColor(improvement >= 0 ? .green : .orange)
        }
    }
}

#Preview {
    CompletionViewiOS(viewModel: BreathingViewModeliOS(), onRepeat: { }, onDone: { })
        .preferredColorScheme(.dark)
}
