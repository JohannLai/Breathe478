import Foundation
import SwiftData
import WatchConnectivity

/// Manages Watch connectivity for syncing session data between iPhone and Apple Watch
@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var isWatchPaired = false
    @Published var isWatchReachable = false
    @Published var lastSyncDate: Date?

    private var session: WCSession?
    private var modelContainer: ModelContainer?

    override private init() {
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // MARK: - Configuration

    /// Set the ModelContainer so we can save received sessions directly
    func setModelContainer(_ container: ModelContainer) {
        self.modelContainer = container
    }

    // MARK: - Public Methods

    /// Send a session record to the Watch
    func sendSessionToWatch(_ session: SessionRecord) {
        guard let wcSession = self.session,
              wcSession.isPaired,
              wcSession.isWatchAppInstalled else {
            return
        }

        let data: [String: Any] = [
            "type": "newSession",
            "startDate": session.startDate.timeIntervalSince1970,
            "endDate": session.endDate.timeIntervalSince1970,
            "cyclesCompleted": session.cyclesCompleted,
            "duration": session.duration,
            "hrvBefore": session.hrvBefore ?? -1,
            "hrvAfter": session.hrvAfter ?? -1,
            "averageHeartRate": session.averageHeartRate ?? -1,
            "syncedToHealthKit": session.syncedToHealthKit,
            "sourceDevice": session.sourceDevice ?? "iPhone"
        ]

        // Use transferUserInfo for reliable background delivery
        wcSession.transferUserInfo(data)
    }

    // MARK: - Private Methods

    /// Save a session from Watch into SwiftData, with deduplication
    private func saveSessionFromWatch(_ sessionData: [String: Any]) {
        guard let startTimestamp = sessionData["startDate"] as? TimeInterval,
              let endTimestamp = sessionData["endDate"] as? TimeInterval,
              let cycles = sessionData["cyclesCompleted"] as? Int,
              let duration = sessionData["duration"] as? TimeInterval else {
            return
        }

        let startDate = Date(timeIntervalSince1970: startTimestamp)
        let endDate = Date(timeIntervalSince1970: endTimestamp)

        let hrvBefore: Double? = {
            if let value = sessionData["hrvBefore"] as? Double, value >= 0 { return value }
            return nil
        }()
        let hrvAfter: Double? = {
            if let value = sessionData["hrvAfter"] as? Double, value >= 0 { return value }
            return nil
        }()
        let averageHeartRate: Double? = {
            if let value = sessionData["averageHeartRate"] as? Double, value >= 0 { return value }
            return nil
        }()
        let syncedToHealthKit = sessionData["syncedToHealthKit"] as? Bool ?? false
        let sourceDevice = sessionData["sourceDevice"] as? String ?? "Apple Watch"

        guard let container = modelContainer else { return }

        let context = ModelContext(container)

        // Deduplicate: check if a session with the same startDate already exists
        // Use a small time window (1 second) to handle floating point precision
        let windowStart = startDate.addingTimeInterval(-0.5)
        let windowEnd = startDate.addingTimeInterval(0.5)
        let predicate = #Predicate<SessionRecord> { record in
            record.startDate >= windowStart && record.startDate <= windowEnd
        }
        let descriptor = FetchDescriptor<SessionRecord>(predicate: predicate)

        do {
            let existing = try context.fetch(descriptor)
            if !existing.isEmpty {
                // Session already exists, skip
                return
            }
        } catch {
            // If fetch fails, proceed to insert (better to have a duplicate than lose data)
        }

        let record = SessionRecord(
            startDate: startDate,
            endDate: endDate,
            cyclesCompleted: cycles,
            duration: duration,
            hrvBefore: hrvBefore,
            hrvAfter: hrvAfter,
            averageHeartRate: averageHeartRate,
            syncedToHealthKit: syncedToHealthKit,
            sourceDevice: sourceDevice
        )

        context.insert(record)
        do {
            try context.save()
            lastSyncDate = Date()
        } catch {
            print("WatchConnectivity: Failed to save session: \(error.localizedDescription)")
        }
    }

    private func updateSessionState() {
        guard let wcSession = session else { return }
        isWatchPaired = wcSession.isPaired
        isWatchReachable = wcSession.isReachable
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.updateSessionState()
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session
        session.activate()
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.updateSessionState()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.updateSessionState()
        }
    }

    // Receive user info transfers (reliable background delivery from Watch)
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        Task { @MainActor in
            handleReceivedData(userInfo)
        }
    }

    // Receive immediate messages from Watch (fallback, not currently used)
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            handleReceivedData(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            handleReceivedData(message)
            replyHandler(["status": "ok"])
        }
    }

    @MainActor
    private func handleReceivedData(_ data: [String: Any]) {
        guard let type = data["type"] as? String else { return }

        switch type {
        case "newSession":
            saveSessionFromWatch(data)
        default:
            break
        }
    }
}
