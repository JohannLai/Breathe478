import SwiftUI
import SwiftData

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

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onReceive(NotificationCenter.default.publisher(for: .watchSessionReceived)) { notification in
                    handleWatchSession(notification.userInfo)
                }
        }
        .modelContainer(sharedModelContainer)
    }

    /// Handle incoming session data from Watch
    private func handleWatchSession(_ userInfo: [AnyHashable: Any]?) {
        guard let info = userInfo,
              let startDate = info["startDate"] as? Date,
              let endDate = info["endDate"] as? Date,
              let cyclesCompleted = info["cyclesCompleted"] as? Int,
              let duration = info["duration"] as? TimeInterval else {
            return
        }

        // Parse optional HRV values (-1 means nil from Watch)
        let hrvBefore: Double? = {
            if let value = info["hrvBefore"] as? Double, value >= 0 {
                return value
            }
            return nil
        }()

        let hrvAfter: Double? = {
            if let value = info["hrvAfter"] as? Double, value >= 0 {
                return value
            }
            return nil
        }()

        let averageHeartRate: Double? = {
            if let value = info["averageHeartRate"] as? Double, value >= 0 {
                return value
            }
            return nil
        }()

        let syncedToHealthKit = info["syncedToHealthKit"] as? Bool ?? false
        let sourceDevice = info["sourceDevice"] as? String ?? "Apple Watch"

        // Create and save the session record
        let record = SessionRecord(
            startDate: startDate,
            endDate: endDate,
            cyclesCompleted: cyclesCompleted,
            duration: duration,
            hrvBefore: hrvBefore,
            hrvAfter: hrvAfter,
            averageHeartRate: averageHeartRate,
            syncedToHealthKit: syncedToHealthKit,
            sourceDevice: sourceDevice
        )

        let context = sharedModelContainer.mainContext
        context.insert(record)
        try? context.save()
    }
}
