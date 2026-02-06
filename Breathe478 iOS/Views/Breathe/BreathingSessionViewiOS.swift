import SwiftUI

/// Main breathing session view for iOS
struct BreathingSessionViewiOS: View {
    @ObservedObject var viewModel: BreathingViewModeliOS
    let onEnd: () -> Void
    @State private var contentAppeared = false

    var body: some View {
        ZStack {
            // Background - tap to pause/resume
            Theme.backgroundColor.ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.togglePause()
                }

            VStack(spacing: 0) {
                // Header
                HStack {
                    // Close button
                    Button(action: onEnd) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.textTertiary)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .opacity(contentAppeared ? 1 : 0)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Breathing flower - large and centered
                BreathingFlower(
                    scale: viewModel.animationScale,
                    isAnimating: viewModel.state.isBreathing,
                    phase: viewModel.state.currentPhase,
                    size: 280
                )
                .frame(width: 280, height: 280)
                .scaleEffect(contentAppeared ? 1 : 0.5)
                .opacity(contentAppeared ? 1 : 0)

                Spacer()

                // Phase text and beat counter - more breathing room
                VStack(spacing: 12) {
                    if let phase = viewModel.state.currentPhase {
                        Text(phase.displayText)
                            .font(.system(.title2, design: .rounded, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))

                        Text("\(viewModel.currentBeat)")
                            .font(.system(size: 56, weight: .ultraLight, design: .rounded))
                            .foregroundColor(Theme.textPrimary.opacity(0.9))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(Theme.softFade, value: viewModel.currentBeat)
                    }
                }
                .frame(height: 110)
                .animation(Theme.softFade, value: viewModel.state.currentPhase)
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 20)

                // Spacer between text and progress
                Spacer()
                    .frame(height: 40)

                // Cycle progress - minimal pill style
                CycleProgressIndicator(
                    currentCycle: viewModel.currentCycle,
                    totalCycles: viewModel.totalCycles
                )
                .opacity(contentAppeared ? 1 : 0)
                .padding(.bottom, 50)
            }

            // Pause overlay
            if case .paused = viewModel.state {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()

                    VStack(spacing: 32) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(Theme.textSecondary)

                        Text("Paused")
                            .font(.system(.title2, design: .rounded, weight: .medium))
                            .foregroundColor(.white)

                        // Action buttons
                        VStack(spacing: 12) {
                            // Resume button
                            Button(action: { viewModel.togglePause() }) {
                                Text("Resume")
                                    .font(.system(.body, design: .rounded, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Theme.primaryGradient)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)

                            // End Session button
                            Button(action: onEnd) {
                                Text("End Session")
                                    .font(.system(.body, design: .rounded, weight: .medium))
                                    .foregroundColor(Theme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 40)
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(Theme.softFade, value: viewModel.state)
        .onAppear {
            withAnimation(Theme.gentleAppear.delay(0.1)) {
                contentAppeared = true
            }
        }
        .onDisappear {
            contentAppeared = false
        }
    }
}

/// Apple-style minimal cycle progress indicator
struct CycleProgressIndicator: View {
    let currentCycle: Int
    let totalCycles: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...totalCycles, id: \.self) { cycle in
                Capsule()
                    .fill(fillColor(for: cycle))
                    .frame(width: capsuleWidth(for: cycle), height: 4)
                    .animation(.easeOut(duration: 0.4), value: currentCycle)
            }
        }
    }

    private func fillColor(for cycle: Int) -> Color {
        if cycle < currentCycle {
            return Theme.primaryMint
        } else if cycle == currentCycle {
            return Theme.primaryMint.opacity(0.8)
        } else {
            return Color.white.opacity(0.15)
        }
    }

    private func capsuleWidth(for cycle: Int) -> CGFloat {
        cycle == currentCycle ? 24 : 16
    }
}

#Preview {
    BreathingSessionViewiOS(viewModel: BreathingViewModeliOS()) { }
        .preferredColorScheme(.dark)
}
