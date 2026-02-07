import UIKit
import CoreHaptics

/// Manages haptic feedback for iOS breathing sessions
/// Replicates Apple's Breathe app haptic patterns using Core Haptics
@MainActor
final class HapticManageriOS {
    static let shared = HapticManageriOS()

    private var engine: CHHapticEngine?
    private var currentPlayer: CHHapticPatternPlayer?

    // Fallback generators for devices without Core Haptics
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    // MARK: - Configuration

    /// Number of pulses for inhale phase (4 seconds)
    private let inhalePulseCount: Int = 18

    /// Number of pulses for exhale phase (8 seconds)
    private let exhalePulseCount: Int = 24

    /// Power exponent for timing curve
    private let inhaleTimingExponent: Double = 0.6  // Low-to-high frequency (sparse → dense)
    private let exhaleTimingExponent: Double = 0.7  // Deceleration

    private var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    private init() {
        setupEngine()
        prepareGenerators()
    }

    private func setupEngine() {
        guard supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                do {
                    try self?.engine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }
            engine?.stoppedHandler = { reason in
                print("Haptic engine stopped: \(reason)")
            }
            try engine?.start()
        } catch {
            print("Failed to create haptic engine: \(error)")
        }
    }

    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notification.prepare()
        selection.prepare()
    }

    // MARK: - Phase Patterns (Apple Breathe Style)

    /// Play the complete inhale haptic pattern
    /// Uses accelerating pulses to create a "rising" sensation
    func playInhalePattern(duration: TimeInterval = 4.0) {
        guard supportsHaptics, let engine = engine else {
            // Fallback
            impactHeavy.impactOccurred()
            return
        }

        stopCurrentPattern()

        do {
            var events: [CHHapticEvent] = []

            // Generate pulse times with acceleration curve
            let pulseTimes = generateInhalePulseTimes(duration: duration)

            for (index, time) in pulseTimes.enumerated() {
                // Intensity increases as we progress
                let progress = Float(index) / Float(pulseTimes.count)
                let intensity = 0.3 + (0.5 * progress)

                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: time
                ))
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            currentPlayer = try engine.makePlayer(with: pattern)
            try currentPlayer?.start(atTime: 0)
        } catch {
            print("Failed to play inhale pattern: \(error)")
            impactHeavy.impactOccurred()
        }
    }

    /// Play the hold haptic pattern
    /// Entry double-tap, steady heartbeat every second, exit double-tap
    func playHoldPattern(duration: TimeInterval = 7.0) {
        guard supportsHaptics, let engine = engine else {
            // Fallback
            impactLight.impactOccurred()
            return
        }

        stopCurrentPattern()

        do {
            var events: [CHHapticEvent] = []

            // Entry double-tap - "锁止感" (Lock Feel)
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0
            ))
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ],
                relativeTime: 0.1
            ))

            // Steady heartbeat - one pulse per second (7 beats for 7 seconds)
            // Start from 1s to avoid overlapping with entry double-tap
            for i in 1...Int(duration) - 1 {
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ],
                    relativeTime: TimeInterval(i)
                ))
            }

            // Exit double-tap - signal exhale is coming
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ],
                relativeTime: duration - 0.15
            ))
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                ],
                relativeTime: duration - 0.05
            ))

            let pattern = try CHHapticPattern(events: events, parameters: [])
            currentPlayer = try engine.makePlayer(with: pattern)
            try currentPlayer?.start(atTime: 0)
        } catch {
            print("Failed to play hold pattern: \(error)")
            impactLight.impactOccurred()
        }
    }

    /// Play the complete exhale haptic pattern
    /// No haptics during exhale - let user focus on releasing breath
    func playExhalePattern(duration: TimeInterval = 8.0) {
        stopCurrentPattern()
    }

    /// Stop any currently playing haptic pattern
    func stopCurrentPattern() {
        try? currentPlayer?.stop(atTime: 0)
        currentPlayer = nil
    }

    // MARK: - Pulse Time Generation

    /// Generate inhale pulse times with acceleration curve
    private func generateInhalePulseTimes(duration: TimeInterval) -> [TimeInterval] {
        var times: [TimeInterval] = []

        for i in 1...inhalePulseCount {
            let progress = Double(i) / Double(inhalePulseCount)
            let time = duration * pow(progress, inhaleTimingExponent)
            times.append(time)
        }

        return times
    }

    /// Generate exhale pulse times with deceleration curve
    private func generateExhalePulseTimes(duration: TimeInterval) -> [TimeInterval] {
        var times: [TimeInterval] = []

        for i in 1...exhalePulseCount {
            let progress = Double(i) / Double(exhalePulseCount)
            let time = duration * pow(progress, exhaleTimingExponent)
            times.append(time)
        }

        return times
    }

    // MARK: - Phase Transitions

    /// Play the complete haptic pattern for a given phase
    func playPhaseTransition(_ phase: BreathingPhase) {
        switch phase {
        case .inhale:
            playInhalePattern(duration: phase.duration)
        case .hold:
            playHoldPattern(duration: phase.duration)
        case .exhale:
            playExhalePattern(duration: phase.duration)
        }
    }

    // MARK: - Simple Haptics

    func playTick() {
        if supportsHaptics, let engine = engine {
            do {
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ],
                    relativeTime: 0
                )
                let pattern = try CHHapticPattern(events: [event], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: 0)
            } catch {
                selection.selectionChanged()
            }
        } else {
            selection.selectionChanged()
        }
        selection.prepare()
    }

    func playBeat() {
        // Beat haptics are now handled by the pattern itself
        // This is kept for compatibility but does nothing
        // to avoid interfering with the phase pattern
    }

    // MARK: - Completion

    func playCycleComplete() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    func playSessionComplete() {
        stopCurrentPattern()
        notification.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.notification.notificationOccurred(.success)
            self.notification.prepare()
        }
    }
}
