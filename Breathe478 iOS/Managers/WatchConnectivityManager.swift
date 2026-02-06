import Foundation
import WatchConnectivity

/// Manages Watch connectivity for syncing session data between iPhone and Apple Watch
@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var isWatchPaired = false
    @Published var isWatchReachable = false
    @Published var lastSyncDate: Date?

    private var session: WCSession?

    override private init() {
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
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

        // Try to send immediately if reachable
        if wcSession.isReachable {
            wcSession.sendMessage(data, replyHandler: nil) { error in
                print("Failed to send session to Watch: \(error.localizedDescription)")
            }
        } else {
            // Use transferUserInfo for background delivery
            wcSession.transferUserInfo(data)
        }
    }

    /// Request session sync from Watch
    func requestSyncFromWatch() {
        guard let wcSession = session,
              wcSession.isPaired,
              wcSession.isReachable else {
            return
        }

        let request: [String: Any] = ["type": "syncRequest"]
        wcSession.sendMessage(request, replyHandler: { response in
            // Handle incoming sessions from Watch
            if let sessions = response["sessions"] as? [[String: Any]] {
                Task { @MainActor in
                    self.processSessions(sessions)
                }
            }
        }, errorHandler: { error in
            print("Sync request failed: \(error.localizedDescription)")
        })
    }

    // MARK: - Private Methods

    private func processSessions(_ sessions: [[String: Any]]) {
        // Process received sessions from Watch
        for sessionData in sessions {
            guard let startDate = sessionData["startDate"] as? TimeInterval,
                  let endDate = sessionData["endDate"] as? TimeInterval,
                  let cycles = sessionData["cyclesCompleted"] as? Int,
                  let duration = sessionData["duration"] as? TimeInterval else {
                continue
            }

            // Create SessionRecord and save to SwiftData
            // This would require access to ModelContext
            // For now, post notification for the app to handle
            NotificationCenter.default.post(
                name: .watchSessionReceived,
                object: nil,
                userInfo: [
                    "startDate": Date(timeIntervalSince1970: startDate),
                    "endDate": Date(timeIntervalSince1970: endDate),
                    "cyclesCompleted": cycles,
                    "duration": duration,
                    "hrvBefore": sessionData["hrvBefore"] as? Double,
                    "hrvAfter": sessionData["hrvAfter"] as? Double,
                    "averageHeartRate": sessionData["averageHeartRate"] as? Double,
                    "syncedToHealthKit": sessionData["syncedToHealthKit"] as? Bool ?? false,
                    "sourceDevice": sessionData["sourceDevice"] as? String ?? "Apple Watch"
                ]
            )
        }

        lastSyncDate = Date()
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

    // Receive messages from Watch
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            handleMessage(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            let response = handleMessageWithReply(message)
            replyHandler(response)
        }
    }

    // Receive user info transfers
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        Task { @MainActor in
            handleMessage(userInfo)
        }
    }

    @MainActor
    private func handleMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "newSession":
            processSessions([message])
        case "syncRequest":
            // Watch requesting sync - respond with local sessions
            break
        default:
            break
        }
    }

    @MainActor
    private func handleMessageWithReply(_ message: [String: Any]) -> [String: Any] {
        guard let type = message["type"] as? String else {
            return ["error": "Unknown message type"]
        }

        switch type {
        case "syncRequest":
            // Return local sessions (would need ModelContext access)
            return ["sessions": []]
        default:
            return ["error": "Unknown message type"]
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let watchSessionReceived = Notification.Name("watchSessionReceived")
}
