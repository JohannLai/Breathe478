import SwiftUI

/// The breathing flower animation with 6 petals - HTML Style
struct BreathingFlower: View {
    let scale: CGFloat          // 0.2 (contracted) to 1.0 (expanded)
    let isAnimating: Bool
    var phase: BreathingPhase? = nil
    
    // HTML uses 6 petals
    private let petalCount = 6
    
    // Sizing to match HTML proportions roughly
    // HTML: Container 260px, Petal 130px (Petal is 0.5 of container)
    // Watch screen width approx 160-190pt.
    // Let's assume a container of 160pt. Petal = 80pt.
    private let basePetalSize: CGFloat = 80
    
    // Rotation state for the "floating" effect during hold/idle
    @State private var floatingRotation: Double = 0
    
    // Dynamic color based on phase (matching HTML logic)
    private var petalColor: Color {
        switch phase {
        case .inhale:
            return Theme.htmlTeal // 青色
        case .hold:
            return Theme.htmlGreen // Greenish
        case .exhale:
            return Theme.htmlBlue // Blue
        case .none:
            return Color.white.opacity(0.2)
        }
    }
    
    // Animation duration derived from phase or default
    private var animationDuration: Double {
        phase?.duration ?? 2.0
    }
    
    // Calculate petal offset based on scale
    // HTML Inhaling: translate(55px) from center.
    // HTML Petal size 130px. 55px is approx 42% of petal size.
    // If basePetalSize is 80, max offset should be approx 34.
    private var petalOffset: CGFloat {
        // Map 0.2...1.0 to 0...maxOffset
        // Contracted (0.2): 0 offset
        // Expanded (1.0): 34 offset
        let normalized = max(0, (scale - 0.2) / 0.8)
        return normalized * 34
    }
    
    // Calculate rotation for each petal
    // HTML: 0, 60, 120...
    private func rotation(for index: Int) -> Double {
        Double(index) * 60.0
    }

    var body: some View {
        ZStack {
            // Petals
            ForEach(0..<petalCount, id: \.self) { index in
                PetalCircle(color: petalColor)
                    .frame(width: basePetalSize, height: basePetalSize)
                    // Offset moves them outward
                    .offset(x: petalOffset)
                    // Rotate to form the flower
                    .rotationEffect(.degrees(rotation(for: index)))
                    // Add the overall rotation (breathing rotation)
                    .rotationEffect(.degrees(floatingRotation))
            }
        }
        // Use the custom cubic-bezier curve from HTML
        .animation(Theme.breathingCurve(duration: animationDuration), value: scale)
        // Smooth color transition
        .animation(.linear(duration: 2.0), value: phase) 
        .onAppear {
            if isAnimating {
                startFloatingAnimation()
            }
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                startFloatingAnimation()
            }
        }
    }
    
    private func startFloatingAnimation() {
        // Continuous slow rotation for "alive" feel
        // HTML: 60s linear infinite
        withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
            floatingRotation = 360
        }
    }
}

/// A single petal circle with blend mode
struct PetalCircle: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color.opacity(0.8)) // Adjust opacity to match look
            // HTML uses mix-blend-mode: screen
            .blendMode(.screen)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 50) {
            // Contracted
            BreathingFlower(scale: 0.2, isAnimating: false, phase: nil)
                .frame(width: 160, height: 160)
            
            // Expanded
            BreathingFlower(scale: 1.0, isAnimating: true, phase: .inhale)
                .frame(width: 160, height: 160)
        }
    }
}
