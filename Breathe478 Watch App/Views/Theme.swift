import SwiftUI

/// App theme constants
enum Theme {
    // MARK: - Colors

    // Colors from User's HTML Reference
    // Inhale: rgb(88, 201, 195)
    static let htmlTeal = Color(red: 88/255, green: 201/255, blue: 195/255)
    
    // Hold: rgb(80, 180, 150)
    static let htmlGreen = Color(red: 80/255, green: 180/255, blue: 150/255)
    
    // Exhale: rgb(100, 210, 255)
    static let htmlBlue = Color(red: 100/255, green: 210/255, blue: 255/255)
    
    // Mapped to app semantics
    static let breatheTeal = htmlTeal
    static let breatheGreen = htmlGreen
    static let breatheBlue = htmlBlue
    
    // Gradient for UI elements
    static let primaryGradient = LinearGradient(
        colors: [breatheTeal, breatheBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Legacy support
    static let primaryCyan = breatheTeal
    static let primaryMint = breatheGreen

    static let backgroundColor = Color.black
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)

    // MARK: - Animation

    static let defaultAnimation: Animation = .easeInOut(duration: 0.3)
    
    // Custom cubic-bezier(0.42, 0, 0.58, 1) from HTML
    static func breathingCurve(duration: Double) -> Animation {
        Animation.timingCurve(0.42, 0, 0.58, 1.0, duration: duration)
    }

    // MARK: - Dimensions

    static let buttonCornerRadius: CGFloat = 20
    static let smallButtonCornerRadius: CGFloat = 12
}

/// Reusable button style for the app
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded, weight: .semibold))
            .foregroundColor(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Theme.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Secondary button style
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded, weight: .medium))
            .foregroundColor(Theme.textPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: Theme.smallButtonCornerRadius))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func primaryButtonStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }

    func secondaryButtonStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
}
