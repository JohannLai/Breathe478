import SwiftUI
import SwiftData
import UIKit

@main
struct Breathe478iOSApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SessionRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Configure global appearance for dark theme
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .black
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // Activate WatchConnectivity early so it's ready to receive data
        // The ModelContainer will be set in body via onAppear
        _ = WatchConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .onAppear {
                    // Give WatchConnectivityManager access to SwiftData for saving received sessions
                    WatchConnectivityManager.shared.setModelContainer(sharedModelContainer)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
