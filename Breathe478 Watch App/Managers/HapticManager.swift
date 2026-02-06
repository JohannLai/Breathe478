import WatchKit
import Foundation

/// Manages haptic feedback for breathing guidance
/// Replicates Apple's Breathe app haptic patterns using precise pulse sequences
/// Uses WKInterfaceDevice since Core Haptics is not available on watchOS
final class HapticManager {
    static let shared = HapticManager()

    private let device = WKInterfaceDevice.current()
    private var pulseTimer: Timer?
    private var pulseIndex: Int = 0
    private var pulseTimes: [TimeInterval] = []
    private var pulseCompletion: (() -> Void)?

    // Hold phase specific timers for multi-stage pattern
    private var holdTimers: [Timer] = []

    // MARK: - Configuration

    /// Number of pulses for inhale phase (4 seconds)
    private let inhalePulseCount: Int = 18

    /// Number of pulses for exhale phase (8 seconds)
    private let exhalePulseCount: Int = 24

    /// Power exponent for timing curve
    private let inhaleTimingExponent: Double = 1.4  // Acceleration
    private let exhaleTimingExponent: Double = 0.7  // Deceleration

    private init() {}

    // MARK: - Phase Haptics (Pulse Sequence Implementation)

    /// Play the complete inhale haptic pattern
    /// Uses accelerating pulses to create a "rising" sensation
    func playInhalePattern(duration: TimeInterval = 4.0, completion: (() -> Void)? = nil) {
        stopCurrentPattern()

        // Generate pulse times with acceleration curve
        pulseTimes = generateInhalePulseTimes(duration: duration)
        pulseIndex = 0
        pulseCompletion = completion

        // Play initial strong tap
        device.play(.start)

        // Schedule subsequent pulses
        scheduleNextPulse(isInhale: true)
    }

    /// Play the complete exhale haptic pattern
    /// Uses decelerating pulses to create a "releasing" sensation
    func playExhalePattern(duration: TimeInterval = 8.0, completion: (() -> Void)? = nil) {
        stopCurrentPattern()

        // Generate pulse times with deceleration curve
        pulseTimes = generateExhalePulseTimes(duration: duration)
        pulseIndex = 0
        pulseCompletion = completion

        // Play initial tap
        device.play(.directionDown)

        // Schedule subsequent pulses
        scheduleNextPulse(isInhale: false)
    }

    /// Play "Fading Bio-Pulse" hold pattern (渐隐式生物脉动)
    /// Three stages: Entry Lock, Fading Heartbeat, Exit Cue
    func playHoldPattern(duration: TimeInterval = 7.0, completion: (() -> Void)? = nil) {
        stopCurrentPattern()
        pulseCompletion = completion

        // ============================================
        // Stage 1: Entry Transition - "锁止感" (Lock Feel)
        // Double tap at 0.0s and 0.1s to signal "stop inhaling, start holding"
        // ============================================

        // First tap - immediate
        device.play(.stop)

        // Second tap - 100ms later (creates "click-clack" lock sensation)
        let entryTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            self?.device.play(.click)
        }
        holdTimers.append(entryTimer)

        // ============================================
        // Stage 2: The Body - "衰减脉动" (Fading Heartbeat)
        // 3 pulses in first 3 seconds, intensity decreasing
        // Simulates a heartbeat fading into stillness
        // ============================================

        // Pulse at 1.0s (strongest)
        let pulse1Timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.device.play(.click)
        }
        holdTimers.append(pulse1Timer)

        // Pulse at 2.0s (medium) - using .click but perceptually feels weaker due to anticipation
        let pulse2Timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.device.play(.click)
        }
        holdTimers.append(pulse2Timer)

        // Pulse at 3.0s (weakest/final) - the last heartbeat before silence
        let pulse3Timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.device.play(.click)
        }
        holdTimers.append(pulse3Timer)

        // Seconds 4-6: Complete silence (Deep Stillness)
        // No haptics - user transitions from external to internal awareness

        // ============================================
        // Stage 3: Exit Cue - "膨胀预警" (Expansion Warning)
        // Gentle rising sensation to prepare for exhale
        // Series of accelerating pulses from 6.2s to 7.0s
        // ============================================

        // Exit cue: 4 quick pulses creating "building pressure" sensation
        // Times: 6.2s, 6.5s, 6.7s, 6.9s (accelerating)
        let exitTimes: [TimeInterval] = [
            duration - 0.8,  // 6.2s
            duration - 0.5,  // 6.5s
            duration - 0.3,  // 6.7s
            duration - 0.1   // 6.9s
        ]

        for exitTime in exitTimes {
            let exitTimer = Timer.scheduledTimer(withTimeInterval: exitTime, repeats: false) { [weak self] _ in
                self?.device.play(.click)
            }
            holdTimers.append(exitTimer)
        }

        // Final strong tap right before exhale (at duration - 0.05s)
        let finalTimer = Timer.scheduledTimer(withTimeInterval: duration - 0.05, repeats: false) { [weak self] _ in
            self?.device.play(.directionUp)
        }
        holdTimers.append(finalTimer)

        // Completion callback
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

        // Stop all hold phase timers
        for timer in holdTimers {
            timer.invalidate()
        }
        holdTimers.removeAll()
    }

    // MARK: - Pulse Time Generation

    /// Generate inhale pulse times with acceleration curve
    /// Pulses get closer together, creating a "building up" sensation
    private func generateInhalePulseTimes(duration: TimeInterval) -> [TimeInterval] {
        var times: [TimeInterval] = []

        for i in 1...inhalePulseCount {
            let progress = Double(i) / Double(inhalePulseCount)
            // Power curve: t = T * (k/n)^α where α > 1 creates acceleration
            let time = duration * pow(progress, inhaleTimingExponent)
            times.append(time)
        }

        return times
    }

    /// Generate exhale pulse times with deceleration curve
    /// Pulses get further apart, creating a "releasing" sensation
    private func generateExhalePulseTimes(duration: TimeInterval) -> [TimeInterval] {
        var times: [TimeInterval] = []

        for i in 1...exhalePulseCount {
            let progress = Double(i) / Double(exhalePulseCount)
            // Power curve: α < 1 creates deceleration (pulses spread out)
            let time = duration * pow(progress, exhaleTimingExponent)
            times.append(time)
        }

        return times
    }

    // MARK: - Pulse Scheduling

    private func scheduleNextPulse(isInhale: Bool, isHold: Bool = false) {
        guard pulseIndex < pulseTimes.count else {
            // All pulses played
            pulseCompletion?()
            return
        }

        let currentTime = pulseIndex == 0 ? 0 : pulseTimes[pulseIndex - 1]
        let nextTime = pulseTimes[pulseIndex]
        let delay = nextTime - currentTime

        pulseTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            // Play the pulse
            if isHold {
                // Very subtle pulse for hold
                self.device.play(.click)
            } else if isInhale {
                // Inhale uses click for consistent rhythm
                self.device.play(.click)
            } else {
                // Exhale also uses click
                self.device.play(.click)
            }

            self.pulseIndex += 1
            self.scheduleNextPulse(isInhale: isInhale, isHold: isHold)
        }
    }

    // MARK: - Event Haptics (Simple WKInterfaceDevice)

    /// Play haptic for starting inhale phase
    func playInhaleStart() {
        device.play(.start)
    }

    /// Play haptic for starting hold phase
    func playHoldStart() {
        device.play(.stop)
    }

    /// Play haptic for starting exhale phase
    func playExhaleStart() {
        device.play(.directionDown)
    }

    /// Play haptic for completing one breathing cycle
    func playCycleComplete() {
        device.play(.success)
    }

    /// Play haptic for completing all cycles
    func playSessionComplete() {
        stopCurrentPattern()
        device.play(.notification)
    }

    /// Play subtle click for rhythm guidance (legacy support)
    func playRhythmClick() {
        device.play(.click)
    }

    // MARK: - Phase Transition with Full Pattern

    /// Play the complete haptic pattern for a given phase
    /// This is the main method to call for Apple Breathe-style haptics
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

    /// Legacy method for simple phase transition haptic
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
