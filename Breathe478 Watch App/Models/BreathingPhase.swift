import Foundation

/// Represents the current phase of the 4-7-8 breathing cycle
enum BreathingPhase: String, CaseIterable {
    case inhale = "inhale"
    case hold = "hold"
    case exhale = "exhale"

    /// Duration in seconds for each phase
    var duration: TimeInterval {
        switch self {
        case .inhale: return 4.0
        case .hold: return 7.0
        case .exhale: return 8.0
        }
    }

    /// Localized display text for the phase (Apple Breathe style)
    var displayText: String {
        switch self {
        case .inhale: return String(localized: "Inhale...", comment: "Breathing phase: inhale with ellipsis")
        case .hold: return String(localized: "Hold", comment: "Breathing phase: hold breath")
        case .exhale: return String(localized: "Exhale.", comment: "Breathing phase: exhale with period")
        }
    }

    /// Returns the next phase in the breathing cycle
    var nextPhase: BreathingPhase {
        switch self {
        case .inhale: return .hold
        case .hold: return .exhale
        case .exhale: return .inhale
        }
    }

    /// Target scale for the breathing animation
    var targetScale: CGFloat {
        switch self {
        case .inhale: return 1.0   // 展开
        case .hold: return 1.0     // 保持展开
        case .exhale: return 0.2   // 收缩 (Match contracted state)
        }
    }

    /// Interval for haptic feedback during this phase (nil means no continuous haptics)
    var hapticInterval: TimeInterval? {
        switch self {
        case .inhale: return 1.0  // 1 tap per second
        case .hold: return nil     // No haptics during hold
        case .exhale: return 1.0   // 1 tap per second
        }
    }

    /// Total duration of one complete breathing cycle (4 + 7 + 8 = 19 seconds)
    static var cycleDuration: TimeInterval {
        return BreathingPhase.allCases.reduce(0) { $0 + $1.duration }
    }
}
