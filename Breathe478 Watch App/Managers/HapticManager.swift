import WatchKit

/// Manages haptic feedback for breathing guidance
final class HapticManager {
    static let shared = HapticManager()

    private let device = WKInterfaceDevice.current()

    private init() {}

    // MARK: - Phase Transition Haptics

    /// Play haptic for starting inhale phase (Rising feeling)
    /// Apple's Inhale: A strong, sharp tap followed by a rising sensation (or series of taps).
    /// Actually, Apple uses a series of increasingly intense taps or a specific ".start" pattern.
    func playInhaleStart() {
        // .start is the standard "session started" or "action began" haptic.
        // For breathing, a prominent tap is good.
        device.play(.start) 
    }

    /// Play haptic for starting hold phase (Subtle stop)
    /// Apple's Hold: Silence or a very subtle click.
    func playHoldStart() {
        device.play(.stop)
    }

    /// Play haptic for starting exhale phase (Falling feeling)
    /// Apple's Exhale: A "releasing" sensation.
    func playExhaleStart() {
        // .directionDown feels like "emptying".
        device.play(.directionDown)
    }

    /// Play haptic for completing one breathing cycle
    func playCycleComplete() {
        // Gentle success tap
        device.play(.success)
    }

    /// Play haptic for completing all cycles
    func playSessionComplete() {
        device.play(.notification)
    }

    // MARK: - Rhythm Guidance Haptics

    /// Play subtle click for breathing rhythm guidance
    /// Apple's implementation sends a haptic tap *every second* (or slightly faster) during inhale/exhale
    /// to guide the user without looking at the screen.
    func playRhythmClick() {
        // .click is a sharp, clean tap.
        device.play(.click)
    }

    // MARK: - Utility

    /// Play haptic for the start of a given phase
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
