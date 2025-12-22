import SwiftUI

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
        VStack(spacing: 2) {
            // Flower Preview - compact for watch screen
            BreathingFlower(scale: 0.6, isAnimating: true, phase: .none, size: 90)
                .frame(width: 90, height: 90)
                .id("StartFlower") // Keep state stable

            Text("4-7-8 Breathe")
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .padding(.top, 4)

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
                .font(.system(.footnote, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            
            Spacer()

            // Start Button
            Button(action: onStart) {
                Text(String(localized: "Start"))
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
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
