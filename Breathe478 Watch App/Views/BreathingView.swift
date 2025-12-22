import SwiftUI

/// Main view during an active breathing session
struct BreathingView: View {
    @ObservedObject var viewModel: BreathingViewModel
    let onEnd: () -> Void

    var body: some View {
        ZStack {
            // Background
            Theme.backgroundColor.ignoresSafeArea()

            // Subtle End Button (Top Leading)
            VStack {
                HStack {
                    Button(action: onEnd) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.textTertiary)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                    .padding(.leading, 8)
                    
                    Spacer()
                }
                Spacer()
            }
            .zIndex(1) // Ensure it's above the flower

            VStack(spacing: 0) {
                Spacer()

                // Breathing flower animation
                // The flower handles its own rotation and expansion
                BreathingFlower(
                    scale: viewModel.animationScale,
                    isAnimating: viewModel.state.isBreathing,
                    phase: viewModel.state.currentPhase
                )
                .frame(width: 160, height: 160)
                
                Spacer()
                
                // Phase text
                // Positioned below the flower
                phaseText
                    .frame(height: 30)
                    .padding(.bottom, 20)
            }
            
            // Tap anywhere to toggle pause (optional, but good UX)
            // We use a transparent overlay to capture taps without blocking the button
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.togglePause()
                }
                .zIndex(0)
            
            // Pause Overlay
            if case .paused = viewModel.state {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    
                    Text(String(localized: "Paused"))
                        .font(.system(.title3, design: .rounded, weight: .medium))
                        .foregroundColor(.white)
                }
                .zIndex(2)
                .allowsHitTesting(false) // Let taps pass through to resume
            }
        }
    }

    @ViewBuilder
    private var phaseText: some View {
        Group {
            if let phase = viewModel.state.currentPhase, viewModel.state.isBreathing {
                // Combine Phase Name + Countdown
                // E.g., "Inhale · 4"
                HStack(spacing: 8) {
                    Text(phase.displayText)
                        .font(.system(.title3, design: .rounded, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    
                    // Sequential beat count (1, 2, 3...)
                    // More mindful than countdown - focus on the current beat
                    Text("\(viewModel.currentBeat)")
                        .font(.system(.title3, design: .rounded, weight: .medium))
                        .foregroundColor(Theme.textSecondary.opacity(0.8))
                        .monospacedDigit()
                        .transition(.opacity)
                        .id("Beat-\(viewModel.currentBeat)")
                }
                .transition(.opacity)
            } else {
                Text("") // Placeholder to keep layout stable
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.state.currentPhase)
    }
}

#Preview {
    BreathingView(viewModel: BreathingViewModel()) { }
}
