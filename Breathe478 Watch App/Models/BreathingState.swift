import Foundation

/// Represents the overall state of the breathing session
enum BreathingState: Equatable {
    case ready
    case preparing // User clicked start, showing instructions/countdown
    case breathing(phase: BreathingPhase)
    case paused(previousPhase: BreathingPhase)
    case completed

    /// Whether the session is currently active (breathing or paused)
    var isActive: Bool {
        switch self {
        case .preparing, .breathing, .paused:
            return true
        case .ready, .completed:
            return false
        }
    }

    /// Whether the breathing animation should be running
    var isBreathing: Bool {
        if case .breathing = self {
            return true
        }
        return false
    }

    /// The current phase, if applicable
    var currentPhase: BreathingPhase? {
        switch self {
        case .breathing(let phase):
            return phase
        case .paused(let previousPhase):
            return previousPhase
        default:
            return nil
        }
    }
}
