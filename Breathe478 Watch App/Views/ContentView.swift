import SwiftUI
import SwiftData

/// Main content view with tab navigation
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = BreathingViewModel()
    @StateObject private var healthKitManager = HealthKitManager.shared

    @State private var selectedTab: Tab = .breathe

    enum Tab {
        case breathe
        case stats
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Breathing Tab
            breathingContent
                .tag(Tab.breathe)

            // Statistics Tab
            StatisticsView()
                .tag(Tab.stats)
        }
        .tabViewStyle(.verticalPage)
        .onAppear {
            viewModel.setModelContext(modelContext)
            Task {
                await healthKitManager.requestAuthorization()
            }
        }
    }

    @ViewBuilder
    private var breathingContent: some View {
        switch viewModel.state {
        case .ready:
            StartView(viewModel: viewModel) {
                viewModel.startSession()
            }
            
        case .preparing:
            PreparationView(viewModel: viewModel)

        case .breathing, .paused:
            BreathingView(viewModel: viewModel) {
                viewModel.endSession()
            }

        case .completed:
            CompletionView(
                viewModel: viewModel,
                onRepeat: {
                    viewModel.reset()
                    viewModel.startSession()
                },
                onDone: {
                    viewModel.reset()
                }
            )
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SessionRecord.self, inMemory: true)
}
