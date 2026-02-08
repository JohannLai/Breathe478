import WatchKit
import Foundation

/// Manages haptic feedback for breathing guidance
/// Uses .click for clean single-tap feel, with iOS-matched timing patterns
final class HapticManager {
    static let shared = HapticManager()

    private let device = WKInterfaceDevice.current()
    private var pulseTimer: Timer?
    private var pulseIndex: Int = 0
    private var pulseTimes: [TimeInterval] = []
    private var pulseCompletion: (() -> Void)?

    private var holdTimers: [Timer] = []

    // MARK: - Configuration

    /// Number of pulses for inhale phase (4 seconds)
    private let inhalePulseCount: Int = 18

    /// Power exponent for timing curve (matched to iOS: 0.6 = sparse → dense)
    private let inhaleTimingExponent: Double = 0.6

    private init() {}

    // MARK: - Phase Haptics

    /// Play the complete inhale haptic pattern
    /// Uses accelerating pulses (sparse → dense) with .start for strong taps
    func playInhalePattern(duration: TimeInterval = 4.0, completion: (() -> Void)? = nil) {
        stopCurrentPattern()

        pulseTimes = generateInhalePulseTimes(duration: duration)
        pulseIndex = 0
        pulseCompletion = completion

        // First pulse immediately
        device.play(.start)

        // Schedule subsequent pulses
        scheduleNextPulse()
    }

    /// Play the hold haptic pattern
    /// Entry tap, steady heartbeat every second, exit notification
    /// Matched to iOS hold pattern
    func playHoldPattern(duration: TimeInterval = 7.0, completion: (() -> Void)? = nil) {
        stopCurrentPattern()
        pulseCompletion = completion

        // No entry tap - transition cue from ViewModel handles it

        // Steady heartbeat - one pulse per second
        for i in 1...Int(duration) - 1 {
            let beatTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(i), repeats: false) { [weak self] _ in
                self?.device.play(.start)
            }
            holdTimers.append(beatTimer)
        }

        // End-of-hold cue is handled by ViewModel at phase transition

        // Completion callback
        let completionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.pulseCompletion?()
        }
        holdTimers.append(completionTimer)
    }

    /// Play the exhale haptic pattern
    /// No haptics during exhale - let user focus on releasing breath
    /// Matched to iOS behavior
    func playExhalePattern(duration: TimeInterval = 8.0, completion: (() -> Void)? = nil) {
        stopCurrentPattern()
        pulseCompletion = completion

        // Silent exhale - schedule completion only
        let completionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.pulseCompletion?()
        }
        holdTimers.append(completionTimer)
    }

    /// Stop any currently playing haptic pattern
    func stopCurrentPattern() {
        pulseTimer?.invalidate()
        pulseTimer = nil
        pulseTimes = []
        pulseIndex = 0
        pulseCompletion = nil

        for timer in holdTimers {
            timer.invalidate()
        }
        holdTimers.removeAll()
    }

    // MARK: - Pulse Time Generation

    /// Generate inhale pulse times with acceleration curve (sparse → dense)
    /// Stops at 90% of duration to leave space for transition cue
    private func generateInhalePulseTimes(duration: TimeInterval) -> [TimeInterval] {
        var times: [TimeInterval] = []
        let effectiveDuration = duration * 0.9

        for i in 1...inhalePulseCount {
            let progress = Double(i) / Double(inhalePulseCount)
            let time = effectiveDuration * pow(progress, inhaleTimingExponent)
            times.append(time)
        }

        return times
    }

    // MARK: - Pulse Scheduling

    private func scheduleNextPulse() {
        guard pulseIndex < pulseTimes.count else {
            pulseCompletion?()
            return
        }

        let currentTime = pulseIndex == 0 ? 0 : pulseTimes[pulseIndex - 1]
        let nextTime = pulseTimes[pulseIndex]
        let delay = nextTime - currentTime

        pulseTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.device.play(.start)
            self.pulseIndex += 1
            self.scheduleNextPulse()
        }
    }

    // MARK: - Event Haptics

    func playInhaleStart() {
        device.play(.start)
    }

    func playHoldStart() {
        device.play(.stop)
    }

    func playExhaleStart() {
        device.play(.directionDown)
    }

    func playCycleComplete() {
        device.play(.success)
    }

    func playSessionComplete() {
        stopCurrentPattern()
        device.play(.notification)
    }

    func playRhythmClick() {
        device.play(.click)
    }

    // MARK: - Phase Transition Cue

    /// Play a strong transition cue between phases
    func playPhaseTransitionCue() {
        device.play(.success)
    }

    // MARK: - Phase Pattern

    /// Play the complete haptic pattern for a given phase
    func playPhasePattern(for phase: BreathingPhase) {
        switch phase {
        case .inhale:
            playInhalePattern(duration: phase.duration)
        case .hold:
            playHoldPattern(duration: phase.duration)
        case .exhale:
            playExhalePattern(duration: phase.duration)
        }
    }

    func playPhaseTransition(to phase: BreathingPhase, isLastCycle: Bool = false) {
        switch phase {
        case .inhale:
            playInhaleStart()
        case .hold:
            playHoldStart()
        case .exhale:
            playExhaleStart()
        }
    }
}
