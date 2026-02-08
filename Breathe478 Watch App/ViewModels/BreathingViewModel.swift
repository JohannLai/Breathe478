import SwiftUI
import SwiftData
import Combine

/// ViewModel managing the 4-7-8 breathing session with HRV tracking
@MainActor
final class BreathingViewModel: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var state: BreathingState = .ready
    @Published var currentCycle: Int = 1
    @Published var totalCycles: Int = 4
    @Published var phaseElapsedTime: TimeInterval = 0
    @Published var animationScale: CGFloat = 0.2  // 初始收缩状态 (Contracted)
    @Published var sessionStartTime: Date?
    
    // Preparation
    @Published var prepCountdown: Int = 3

    // HRV Tracking
    @Published var hrvBefore: Double?
    @Published var hrvAfter: Double?
    @Published var averageHeartRate: Double?
    @Published var isMeasuringHRV: Bool = false
    @Published var sessionSaved: Bool = false

    // MARK: - Private Properties

    private var phaseTimer: Timer?
    private var hapticTimer: Timer?
    private let hapticManager = HapticManager.shared
    private let healthKitManager = HealthKitManager.shared
    private let timerInterval: TimeInterval = 0.05

    private var modelContext: ModelContext?

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

    /// HRV improvement (if both before/after available)
    var hrvImprovement: Double? {
        guard let before = hrvBefore, let after = hrvAfter, before > 0 else {
            return nil
        }
        return ((after - before) / before) * 100
    }

    // MARK: - Session Control

    /// Start the session preparation (count in)
    func startSession() {
        // Reset state
        currentCycle = 1
        phaseElapsedTime = 0
        sessionStartTime = nil
        hrvBefore = nil
        hrvAfter = nil
        averageHeartRate = nil
        sessionSaved = false

        // Start preparation
        state = .preparing
        prepCountdown = 5 // 5 seconds to read instructions

        // Start countdown timer for preparation
        stopTimers() // Ensure clean slate
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else { return }
                if self.prepCountdown > 0 {
                    // Play haptic tick for the countdown (last 3 seconds)
                    if self.prepCountdown <= 3 {
                        self.hapticManager.playRhythmClick()
                    }
                    self.prepCountdown -= 1
                } else {
                    timer.invalidate()
                    self.startBreathingCycle()
                }
            }
        }

        // Start workout session to activate heart rate sensor + keep app alive
        Task {
            await healthKitManager.startWorkoutSession()
        }

        // Fetch baseline HRV in background (non-blocking) early
        Task {
            hrvBefore = await healthKitManager.fetchLatestHRV()
        }
    }
    
    /// Actually start the breathing cycle after preparation
    private func startBreathingCycle() {
        guard state == .preparing else { return } // Avoid starting if cancelled
        
        sessionStartTime = Date()
        animationScale = 0.2 // Start contracted
        state = .breathing(phase: .inhale)
        
        // Start timers for breathing
        startTimers()
        
        // Start haptics for first phase (full Core Haptics pattern)
        hapticManager.playPhasePattern(for: .inhale)

        // DELAY the animation target update.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Check if we are still in the session
            if case .breathing = self.state {
                 self.updateAnimation(for: .inhale)
            }
        }
    }

    /// Alias for compatibility
    func startSessionSync() {
        startSession()
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
        Task {
            await finalizeSession()
        }
    }

    /// Reset to ready state
    func reset() {
        stopTimers()

        // End workout session
        Task {
            await healthKitManager.endWorkoutSession()
        }

        state = .ready
        currentCycle = 1
        phaseElapsedTime = 0
        animationScale = 0.2  // Reset to contracted
        sessionStartTime = nil
        hrvBefore = nil
        hrvAfter = nil
        averageHeartRate = nil
        sessionSaved = false
    }

    // MARK: - Session Finalization

    /// Finalize session: measure HRV after, save to HealthKit and SwiftData
    private func finalizeSession() async {
        guard let startTime = sessionStartTime else { return }
        let endTime = Date()

        // Measure HRV after session
        isMeasuringHRV = true
        hrvAfter = await healthKitManager.fetchLatestHRV()

        // Wait briefly for heart rate data to be written to HealthKit
        try? await Task.sleep(for: .seconds(2))

        // Get average heart rate during session
        averageHeartRate = await healthKitManager.fetchAverageHeartRate(from: startTime, to: endTime)
        isMeasuringHRV = false

        // Save to HealthKit
        let syncedToHealthKit = await healthKitManager.saveMindfulSession(startDate: startTime, endDate: endTime)

        // Save to SwiftData
        let record = SessionRecord(
            startDate: startTime,
            endDate: endTime,
            cyclesCompleted: currentCycle,
            duration: endTime.timeIntervalSince(startTime),
            hrvBefore: hrvBefore,
            hrvAfter: hrvAfter,
            averageHeartRate: averageHeartRate,
            syncedToHealthKit: syncedToHealthKit
        )

        if let context = modelContext {
            context.insert(record)
            try? context.save()
        }

        // Send session data to iPhone
        WatchConnectivityManager.shared.sendSessionToiPhone(
            startDate: startTime,
            endDate: endTime,
            cyclesCompleted: currentCycle,
            duration: endTime.timeIntervalSince(startTime),
            hrvBefore: hrvBefore,
            hrvAfter: hrvAfter,
            averageHeartRate: averageHeartRate,
            syncedToHealthKit: syncedToHealthKit
        )

        sessionSaved = true

        // End workout session after all data is fetched and saved
        await healthKitManager.endWorkoutSession()
    }

    // MARK: - Private Methods

    private func startPhase(_ phase: BreathingPhase) {
        phaseElapsedTime = 0
        state = .breathing(phase: phase)

        // Play the full Core Haptics pattern for this phase
        // This replaces both the phase transition haptic and rhythm haptics
        hapticManager.playPhasePattern(for: phase)

        // Update animation
        updateAnimation(for: phase)

        // Start timers
        startTimers()
    }

    private func startTimers() {
        // Main phase timer
        phaseTimer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.timerTick()
            }
        }
    }

    private func stopTimers() {
        phaseTimer?.invalidate()
        phaseTimer = nil
        hapticTimer?.invalidate()
        hapticTimer = nil
        // Stop any playing Core Haptics pattern
        hapticManager.stopCurrentPattern()
    }

    private func timerTick() {
        guard case .breathing(let phase) = state else { return }

        phaseElapsedTime += timerInterval

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
                hapticManager.playSessionComplete()
                state = .completed
                Task {
                    await finalizeSession()
                }
                return
            } else {
                currentCycle += 1
            }
        }

        // Play transition cue for all phase transitions
        hapticManager.playPhaseTransitionCue()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startPhase(nextPhase)
        }
    }

    private func updateAnimation(for phase: BreathingPhase) {
        // 直接设置目标值，让 View 层处理动画
        animationScale = phase.targetScale
    }
}
