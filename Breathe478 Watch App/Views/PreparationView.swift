import SwiftUI

/// Preparation view shown before session starts
struct PreparationView: View {
    @ObservedObject var viewModel: BreathingViewModel
    
    // Scale for pulsing flower
    @State private var flowerScale: CGFloat = 0.5
    
    var body: some View {
        ZStack {
            Theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 16) {
                if viewModel.prepCountdown > 2 {
                    // Instruction phase
                    VStack(spacing: 20) {
                        Text("Be still, and bring your attention to your breath.")
                            .font(.system(.body, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal)
                            .transition(.opacity)
                        
                        // 4-7-8 Hint
                        HStack(spacing: 16) {
                            InstructionItem(label: String(localized: "Inhale"), value: "4", color: Theme.breatheTeal)
                            InstructionItem(label: String(localized: "Hold"), value: "7", color: Theme.breatheGreen)
                            InstructionItem(label: String(localized: "Exhale"), value: "8", color: Theme.breatheBlue)
                        }
                    }
                    .transition(.opacity)
                } else {
                    // Countdown phase - Apple Style
                    // Match BreathingView layout exactly for smooth transition
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Small preview flower that breathes gently
                        BreathingFlower(scale: flowerScale, isAnimating: true, phase: .none)
                            .frame(width: 160, height: 160) // Match BreathingView size
                            .onAppear {
                                // 1. Breathe a bit
                                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                    flowerScale = 0.6
                                }
                            }
                            .onChange(of: viewModel.prepCountdown) { _, newValue in
                                // 2. As we approach 0, shrink down to 0.2 to match the start of "Inhale"
                                if newValue <= 1 {
                                    withAnimation(.easeOut(duration: 1.0)) {
                                        flowerScale = 0.2
                                    }
                                }
                            }
                        
                        Spacer()
                        
                        // Match BreathingView's phaseText layout exactly
                        Text("Get Ready...")
                            .font(.system(.title3, design: .rounded, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                            .transition(.opacity)
                            .frame(height: 30) // Same as BreathingView phaseText
                            .padding(.bottom, 20)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.5), value: viewModel.prepCountdown > 2)
        }
    }
}

struct InstructionItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Theme.textSecondary)
        }
    }
}

#Preview {
    PreparationView(viewModel: BreathingViewModel())
}
