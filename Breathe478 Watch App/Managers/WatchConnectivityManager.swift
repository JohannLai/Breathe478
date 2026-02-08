import Foundation
import WatchConnectivity

/// Manages Watch connectivity for syncing session data to iPhone
@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var isPhoneReachable = false

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

    /// Send a completed session to iPhone
    func sendSessionToiPhone(
        startDate: Date,
        endDate: Date,
        cyclesCompleted: Int,
        duration: TimeInterval,
        hrvBefore: Double?,
        hrvAfter: Double?,
        averageHeartRate: Double?,
        syncedToHealthKit: Bool
    ) {
        guard let wcSession = session else { return }

        let data: [String: Any] = [
            "type": "newSession",
            "startDate": startDate.timeIntervalSince1970,
            "endDate": endDate.timeIntervalSince1970,
            "cyclesCompleted": cyclesCompleted,
            "duration": duration,
            "hrvBefore": hrvBefore ?? -1,
            "hrvAfter": hrvAfter ?? -1,
            "averageHeartRate": averageHeartRate ?? -1,
            "syncedToHealthKit": syncedToHealthKit,
            "sourceDevice": "Apple Watch"
        ]

        // Use transferUserInfo for reliable background delivery
        // This ensures data is delivered even if iPhone is not immediately reachable
        // Only use transferUserInfo (not sendMessage) to avoid duplicate delivery
        print("📤 [Watch→iPhone] Sending session via transferUserInfo: \(cyclesCompleted) cycles, duration=\(duration)s")
        wcSession.transferUserInfo(data)
    }

    // MARK: - Private Methods

    private func updateState() {
        guard let wcSession = session else { return }
        isPhoneReachable = wcSession.isReachable
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.updateState()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.updateState()
        }
    }

    // Receive messages from iPhone (for future settings sync)
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            self.handleMessage(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            self.handleApplicationContext(applicationContext)
        }
    }

    @MainActor
    private func handleMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "settingsSync":
            applySettings(message)
        default:
            break
        }
    }

    @MainActor
    private func handleApplicationContext(_ context: [String: Any]) {
        // Apply synced settings from iPhone
        applySettings(context)
    }

    @MainActor
    private func applySettings(_ settings: [String: Any]) {
        // Future: sync settings like default cycles, sound/haptic preferences
        if let defaultCycles = settings["defaultCycles"] as? Int {
            UserDefaults.standard.set(defaultCycles, forKey: "defaultCycles")
        }
        if let soundEnabled = settings["soundEnabled"] as? Bool {
            UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        }
        if let hapticEnabled = settings["hapticEnabled"] as? Bool {
            UserDefaults.standard.set(hapticEnabled, forKey: "hapticEnabled")
        }
    }
}
