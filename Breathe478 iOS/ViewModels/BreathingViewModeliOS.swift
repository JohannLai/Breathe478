import SwiftUI
import SwiftData
import Combine
import UIKit

/// ViewModel managing the 4-7-8 breathing session for iOS
@MainActor
final class BreathingViewModeliOS: ObservableObject {

    // MARK: - Published Properties

    @Published var state: BreathingState = .ready
    @Published var currentCycle: Int = 1
    @Published var totalCycles: Int = 4
    @Published var phaseElapsedTime: TimeInterval = 0
    @Published var animationScale: CGFloat = 0.2  // Initial contracted state
    @Published var sessionStartTime: Date?

    // Preparation
    @Published var prepCountdown: Int = 3

    // Session status
    @Published var sessionSaved: Bool = false

    // MARK: - Private Properties

    private var phaseTimer: Timer?
    private let hapticManager = HapticManageriOS.shared
    private let healthKitManager = HealthKitManager.shared
    private let timerInterval: TimeInterval = 0.05

    private var modelContext: ModelContext?

    // Settings
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("screenAwakeEnabled") private var screenAwakeEnabled = true

    // MARK: - Initialization

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Computed Properties

    /// Current phase duration
    var currentPhaseDuration: TimeInterval {
        state.currentPhase?.duration ?? 0
    }

    /// Remaining seconds in current phase (rounded up)
    var remainingSeconds: Int {
        let remaining = currentPhaseDuration - phaseElapsedTime
        return max(0, Int(ceil(remaining)))
    }

    /// Current beat count (1, 2, 3...) - for sequential counting display
    var currentBeat: Int {
        let elapsed = Int(floor(phaseElapsedTime))
        return min(elapsed + 1, Int(currentPhaseDuration))
    }

    /// Progress within current phase (0.0 to 1.0)
    var phaseProgress: CGFloat {
        guard currentPhaseDuration > 0 else { return 0 }
        return CGFloat(phaseElapsedTime / currentPhaseDuration)
    }

    /// Overall session progress (0.0 to 1.0)
    var sessionProgress: CGFloat {
        let completedCycles = CGFloat(currentCycle - 1)
        let cycleProgress = phaseProgressInCycle
        return (completedCycles + cycleProgress) / CGFloat(totalCycles)
    }

    /// Progress within current cycle (0.0 to 1.0)
    private var phaseProgressInCycle: CGFloat {
        guard let phase = state.currentPhase else { return 0 }
        let cycleDuration = BreathingPhase.cycleDuration

        var elapsedInCycle: TimeInterval = phaseElapsedTime
        switch phase {
        case .inhale:
            break
        case .hold:
            elapsedInCycle += BreathingPhase.inhale.duration
        case .exhale:
            elapsedInCycle += BreathingPhase.inhale.duration + BreathingPhase.hold.duration
        }

        return CGFloat(elapsedInCycle / cycleDuration)
    }

    /// Total session duration
    var totalSessionDuration: TimeInterval {
        guard let startTime = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }

    /// Formatted total duration string
    var formattedDuration: String {
        let duration = totalSessionDuration
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Session Control

    /// Start the session preparation (count in)
    func startSession() {
        // Keep screen awake if enabled
        if screenAwakeEnabled {
            UIApplication.shared.isIdleTimerDisabled = true
        }

        // Reset state
        currentCycle = 1
        phaseElapsedTime = 0
        sessionStartTime = nil
        sessionSaved = false

        // Start preparation
        state = .preparing
        prepCountdown = 5

        // Start countdown timer for preparation
        stopTimers()
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else { return }
                if self.prepCountdown > 0 {
                    // Play haptic tick for the countdown (last 3 seconds)
                    if self.prepCountdown <= 3 && self.hapticEnabled {
                        self.hapticManager.playTick()
                    }
                    self.prepCountdown -= 1
                } else {
                    timer.invalidate()
                    self.startBreathingCycle()
                }
            }
        }

        // Request HealthKit authorization for saving mindful minutes
        Task {
            await healthKitManager.requestAuthorization()
        }
    }

    /// Actually start the breathing cycle after preparation
    private func startBreathingCycle() {
        guard state == .preparing else { return }

        sessionStartTime = Date()
        animationScale = 0.2
        state = .breathing(phase: .inhale)

        startTimers()
        playPhaseStart(.inhale)

        // Delay animation target update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if case .breathing = self.state {
                self.updateAnimation(for: .inhale)
            }
        }
    }

    /// Pause the current session
    func pauseSession() {
        guard case .breathing(let phase) = state else { return }
        stopTimers()
        state = .paused(previousPhase: phase)
    }

    /// Resume a paused session
    func resumeSession() {
        guard case .paused(let previousPhase) = state else { return }
        state = .breathing(phase: previousPhase)
        startTimers()
        updateAnimation(for: previousPhase)
    }

    /// Toggle between pause and resume
    func togglePause() {
        switch state {
        case .breathing:
            pauseSession()
        case .paused:
            resumeSession()
        default:
            break
        }
    }

    /// End the session early
    func endSession() {
        stopTimers()
        state = .completed
        UIApplication.shared.isIdleTimerDisabled = false
        Task {
            await finalizeSession()
        }
    }

    /// Reset to ready state
    func reset() {
        stopTimers()
        UIApplication.shared.isIdleTimerDisabled = false

        state = .ready
        currentCycle = 1
        phaseElapsedTime = 0
        animationScale = 0.2
        sessionStartTime = nil
        sessionSaved = false
    }

    // MARK: - Session Finalization

    private func finalizeSession() async {
        guard let startTime = sessionStartTime else { return }
        let endTime = Date()

        // Save to HealthKit
        let syncedToHealthKit = await healthKitManager.saveMindfulSession(startDate: startTime, endDate: endTime)

        // Save to SwiftData (iPhone sessions never have HRV — HRV requires Apple Watch sensors)
        let record = SessionRecord(
            startDate: startTime,
            endDate: endTime,
            cyclesCompleted: currentCycle,
            duration: endTime.timeIntervalSince(startTime),
            hrvBefore: nil,
            hrvAfter: nil,
            averageHeartRate: nil,
            syncedToHealthKit: syncedToHealthKit,
            sourceDevice: "iPhone"
        )

        if let context = modelContext {
            context.insert(record)
            try? context.save()
        }

        sessionSaved = true
    }

    // MARK: - Private Methods

    private func startPhase(_ phase: BreathingPhase) {
        phaseElapsedTime = 0
        state = .breathing(phase: phase)
        playPhaseStart(phase)
        updateAnimation(for: phase)
        startTimers()
    }

    private func playPhaseStart(_ phase: BreathingPhase) {
        if hapticEnabled {
            hapticManager.playPhaseTransition(phase)
        }
    }

    private func startTimers() {
        phaseTimer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.timerTick()
            }
        }
    }

    private func stopTimers() {
        phaseTimer?.invalidate()
        phaseTimer = nil
    }

    private func timerTick() {
        guard case .breathing(let phase) = state else { return }

        let previousBeat = currentBeat
        phaseElapsedTime += timerInterval

        // Play beat haptic on each second
        if currentBeat != previousBeat && hapticEnabled {
            hapticManager.playBeat()
        }

        // Check if phase is complete
        if phaseElapsedTime >= phase.duration {
            transitionToNextPhase(from: phase)
        }
    }

    private func transitionToNextPhase(from currentPhase: BreathingPhase) {
        stopTimers()

        let nextPhase = currentPhase.nextPhase

        // Check if we completed a cycle (exhale -> inhale)
        if currentPhase == .exhale {
            if currentCycle >= totalCycles {
                // Session complete
                if hapticEnabled {
                    hapticManager.playSessionComplete()
                }
                state = .completed
                UIApplication.shared.isIdleTimerDisabled = false
                Task {
                    await finalizeSession()
                }
                return
            } else {
                currentCycle += 1
            }
        }

        startPhase(nextPhase)
    }

    private func updateAnimation(for phase: BreathingPhase) {
        animationScale = phase.targetScale
    }
}
