import SwiftUI
import SwiftData

/// Container view for the Breathe tab, managing session flow
struct BreatheTab: View {
    @StateObject private var viewModel = BreathingViewModeliOS()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Theme.backgroundColor.ignoresSafeArea()

            switch viewModel.state {
            case .ready:
                StartViewiOS(viewModel: viewModel) {
                    withAnimation(Theme.relaxedTransition) {
                        viewModel.startSession()
                    }
                }
                .transition(.opacity)

            case .preparing:
                PreparationViewiOS(viewModel: viewModel)
                    .transition(.opacity)

            case .breathing, .paused:
                BreathingSessionViewiOS(viewModel: viewModel) {
                    withAnimation(Theme.relaxedTransition) {
                        viewModel.endSession()
                    }
                }
                .transition(.opacity)

            case .completed:
                CompletionViewiOS(viewModel: viewModel) {
                    withAnimation(Theme.relaxedTransition) {
                        viewModel.startSession()
                    }
                } onDone: {
                    withAnimation(Theme.relaxedTransition) {
                        viewModel.reset()
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(Theme.relaxedTransition, value: viewModel.state)
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }
}

#Preview {
    BreatheTab()
        .preferredColorScheme(.dark)
}
