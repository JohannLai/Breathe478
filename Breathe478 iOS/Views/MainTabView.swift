import SwiftUI

/// Main tab navigation for iOS app
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            BreatheTab()
                .tabItem {
                    Label("Breathe", systemImage: "wind")
                }
                .tag(0)

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .tint(Theme.breatheTeal)
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}
