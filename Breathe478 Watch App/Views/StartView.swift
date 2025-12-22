import SwiftUI

/// Apple Watch screen size categories
/// Based on screen height in points
enum WatchSize {
    case small      // Series 3 38mm (~170pt), SE/S4-6 40mm (~197pt)
    case medium     // SE/S4-6 44mm (~224pt), S7-9 41mm (~215pt)
    case large      // S7-9 45mm (~242pt), S10 42mm
    case extraLarge // S10 46mm (~254pt), Ultra 49mm (~251pt)
    
    init(screenHeight: CGFloat) {
        switch screenHeight {
        case ..<200:
            self = .small
        case 200..<230:
            self = .medium
        case 230..<250:
            self = .large
        default:
            self = .extraLarge
        }
    }
    
    var flowerSize: CGFloat {
        switch self {
        case .small: return 55
        case .medium: return 70
        case .large: return 85
        case .extraLarge: return 110 // Ultra/S10 46mm - more spacious
        }
    }
    
    var titleFont: Font {
        switch self {
        case .small: return .system(.caption, design: .rounded, weight: .semibold)
        case .medium: return .system(.footnote, design: .rounded, weight: .semibold)
        case .large: return .system(.body, design: .rounded, weight: .semibold)
        case .extraLarge: return .system(.title3, design: .rounded, weight: .semibold)
        }
    }
    
    var selectorFont: Font {
        switch self {
        case .small: return .system(.caption2, design: .rounded)
        case .medium: return .system(.caption, design: .rounded)
        case .large: return .system(.footnote, design: .rounded)
        case .extraLarge: return .system(.body, design: .rounded)
        }
    }
    
    var buttonFont: Font {
        switch self {
        case .small: return .system(.caption, design: .rounded, weight: .semibold)
        case .medium: return .system(.footnote, design: .rounded, weight: .semibold)
        case .large: return .system(.body, design: .rounded, weight: .semibold)
        case .extraLarge: return .system(.title3, design: .rounded, weight: .semibold)
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 10
        case .large: return 12
        case .extraLarge: return 16
        }
    }
    
    var verticalSpacing: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 4
        case .large: return 6
        case .extraLarge: return 10
        }
    }
}

/// Initial screen for setting up and starting a breathing session
struct StartView: View {
    @ObservedObject var viewModel: BreathingViewModel
    let onStart: () -> Void

    @State private var showingCyclePicker = false

    // Total duration calculation
    private var totalDurationText: String {
        let totalSeconds = Int(BreathingPhase.cycleDuration) * viewModel.totalCycles
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        if minutes > 0 && seconds > 0 {
             return String(format: "%dm %ds", minutes, seconds)
        } else if minutes > 0 {
             return String(format: "%dm", minutes)
        } else {
             return String(format: "%ds", seconds)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let watchSize = WatchSize(screenHeight: geometry.size.height)
            
            VStack(spacing: 0) {
                // Flower Preview - adaptive size based on watch model
                BreathingFlower(scale: 0.6, isAnimating: true, phase: .none, size: watchSize.flowerSize)
                    .frame(width: watchSize.flowerSize, height: watchSize.flowerSize)
                    .id("StartFlower")

                Text("4-7-8 Breathe")
                    .font(watchSize.titleFont)
                    .foregroundColor(Theme.textPrimary)
                    .padding(.top, watchSize.verticalSpacing)

                // Duration/Cycle Selector
                Button {
                    showingCyclePicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text("\(viewModel.totalCycles) Cycles")
                            .foregroundColor(Theme.breatheTeal)
                            .fontWeight(.medium)
                        
                        Text("•")
                            .foregroundColor(Theme.textTertiary)

                        Text(totalDurationText)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .font(watchSize.selectorFont)
                    .padding(.horizontal, watchSize.horizontalPadding)
                    .padding(.vertical, watchSize.verticalSpacing + 4)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.top, watchSize.verticalSpacing)
                
                Spacer()

                // Start Button
                Button(action: onStart) {
                    Text(String(localized: "Start"))
                        .font(watchSize.buttonFont)
                        .frame(maxWidth: .infinity)
                }
                .primaryButtonStyle()
                .padding(.horizontal, watchSize.horizontalPadding)
                .padding(.bottom, watchSize.verticalSpacing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.backgroundColor)
        .sheet(isPresented: $showingCyclePicker) {
            CyclePickerSheet(
                selectedCycles: $viewModel.totalCycles,
                durationPerCycle: Int(BreathingPhase.cycleDuration)
            )
        }
    }
}

/// Picker sheet for selecting number of cycles
struct CyclePickerSheet: View {
    @Binding var selectedCycles: Int
    let durationPerCycle: Int
    @Environment(\.dismiss) private var dismiss

    private func durationText(for cycles: Int) -> String {
        let total = durationPerCycle * cycles
        let minutes = total / 60
        let seconds = total % 60
        if minutes > 0 && seconds > 0 {
             return "\(minutes)m \(seconds)s"
        } else if minutes > 0 {
             return "\(minutes)m"
        } else {
             return "\(seconds)s"
        }
    }

    var body: some View {
        VStack {
            Text(String(localized: "Duration"))
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
                .padding(.top)

            Picker("Duration", selection: $selectedCycles) {
                ForEach(1...10, id: \.self) { count in
                    Text("\(count) cycles • \(durationText(for: count))")
                        .tag(count)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            
            Button(String(localized: "Done")) {
                dismiss()
            }
            .foregroundColor(Theme.breatheTeal)
        }
    }
}

#Preview {
    StartView(viewModel: BreathingViewModel()) { }
}
