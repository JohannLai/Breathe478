import SwiftUI

/// Preparation countdown view for iOS
struct PreparationViewiOS: View {
    @ObservedObject var viewModel: BreathingViewModeliOS
    @State private var contentAppeared = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Flower with subtle animation
            BreathingFlower(
                scale: 0.5,
                isAnimating: true,
                phase: nil,
                size: 220
            )
            .frame(width: 220, height: 220)
            .scaleEffect(contentAppeared ? 1 : 0.5)
            .opacity(contentAppeared ? 1 : 0)

            VStack(spacing: 16) {
                Text("Get Ready")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 15)

                Text("Find a comfortable position")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 15)

                // Countdown
                Text("\(viewModel.prepCountdown)")
                    .font(.system(size: 72, weight: .light, design: .rounded))
                    .foregroundColor(Theme.breatheTeal)
                    .contentTransition(.numericText())
                    .animation(Theme.softFade, value: viewModel.prepCountdown)
                    .opacity(contentAppeared ? 1 : 0)
                    .scaleEffect(contentAppeared ? 1 : 0.8)
            }

            Spacer()

            // Cancel button
            Button {
                viewModel.reset()
            } label: {
                Text("Cancel")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.bottom, 48)
            .opacity(contentAppeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(Theme.gentleAppear.delay(0.15)) {
                contentAppeared = true
            }
        }
        .onDisappear {
            contentAppeared = false
        }
    }
}

#Preview {
    PreparationViewiOS(viewModel: BreathingViewModeliOS())
        .preferredColorScheme(.dark)
}
