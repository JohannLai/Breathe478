import UIKit

/// Manages haptic feedback for iOS breathing sessions
@MainActor
final class HapticManageriOS {
    static let shared = HapticManageriOS()

    // Haptic generators
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    private init() {
        prepareGenerators()
    }

    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notification.prepare()
        selection.prepare()
    }

    // MARK: - Phase Transitions

    func playPhaseTransition(_ phase: BreathingPhase) {
        switch phase {
        case .inhale:
            // Strong start for inhale
            impactHeavy.impactOccurred()
        case .hold:
            // Light tap for hold
            impactLight.impactOccurred()
        case .exhale:
            // Medium for exhale
            impactMedium.impactOccurred()
        }

        // Prepare for next use
        prepareGenerators()
    }

    // MARK: - Rhythm

    func playTick() {
        selection.selectionChanged()
        selection.prepare()
    }

    func playBeat() {
        impactLight.impactOccurred(intensity: 0.5)
        impactLight.prepare()
    }

    // MARK: - Completion

    func playCycleComplete() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    func playSessionComplete() {
        // Double success haptic for session complete
        notification.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.notification.notificationOccurred(.success)
            self.notification.prepare()
        }
    }
}
