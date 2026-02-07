import SwiftUI
import CoreHaptics

/// Start view for iOS - larger display with more options
struct StartViewiOS: View {
    @ObservedObject var viewModel: BreathingViewModeliOS
    let onStart: () -> Void

    @State private var showingCyclePicker = false
    @State private var contentAppeared = false

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
        VStack(spacing: 0) {
            Spacer()

            // Breathing flower preview
            BreathingFlower(
                scale: 0.6,
                isAnimating: true,
                phase: nil,
                size: 240
            )
            .frame(width: 240, height: 240)
            .scaleEffect(contentAppeared ? 1 : 0.5)
            .opacity(contentAppeared ? 1 : 0)

            // Title
            Text("4-7-8 Breathe")
                .font(.system(.title, design: .rounded, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .padding(.top, 24)
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 20)

            // Subtitle
            Text("Relax your mind and body")
                .font(.system(.body, design: .rounded))
                .foregroundColor(Theme.textSecondary)
                .padding(.top, 4)
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 20)

            // Duration/Cycle Selector
            Button {
                showingCyclePicker = true
            } label: {
                HStack(spacing: 8) {
                    Text("\(viewModel.totalCycles) Cycles")
                        .foregroundColor(Theme.breatheTeal)
                        .fontWeight(.medium)

                    Text("•")
                        .foregroundColor(Theme.textTertiary)

                    Text(totalDurationText)
                        .foregroundColor(Theme.textSecondary)

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(Theme.textTertiary)
                }
                .font(.system(.body, design: .rounded))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.top, 24)
            .opacity(contentAppeared ? 1 : 0)
            .offset(y: contentAppeared ? 0 : 20)

            Spacer()

            // Start Button
            Button(action: onStart) {
                Text("Start")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Theme.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .opacity(contentAppeared ? 1 : 0)
            .offset(y: contentAppeared ? 0 : 20)
        }
        .onAppear {
            withAnimation(Theme.gentleAppear.delay(0.1)) {
                contentAppeared = true
            }
        }
        .onDisappear {
            contentAppeared = false
        }
        .sheet(isPresented: $showingCyclePicker) {
            CyclePickerSheet(
                selectedCycles: $viewModel.totalCycles,
                durationPerCycle: Int(BreathingPhase.cycleDuration)
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

/// Cycle picker sheet
struct CyclePickerSheet: View {
    @Binding var selectedCycles: Int
    let durationPerCycle: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                HapticWheelPicker(
                    selection: $selectedCycles,
                    range: 1...10,
                    durationPerCycle: durationPerCycle
                )
                .frame(height: 200)
            }
            .navigationTitle("Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.breatheTeal)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

/// UIKit-based wheel picker with haptic feedback on scroll
struct HapticWheelPicker: UIViewRepresentable {
    @Binding var selection: Int
    let range: ClosedRange<Int>
    let durationPerCycle: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = HapticPickerView()
        picker.delegate = context.coordinator
        picker.dataSource = context.coordinator
        picker.backgroundColor = .clear
        picker.coordinator = context.coordinator

        // Set initial selection
        let initialRow = selection - range.lowerBound
        picker.selectRow(initialRow, inComponent: 0, animated: false)
        context.coordinator.currentRow = initialRow

        return picker
    }

    func updateUIView(_ uiView: UIPickerView, context: Context) {
        let currentRow = selection - range.lowerBound
        if uiView.selectedRow(inComponent: 0) != currentRow {
            uiView.selectRow(currentRow, inComponent: 0, animated: false)
            context.coordinator.currentRow = currentRow
        }
    }

    class Coordinator: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
        var parent: HapticWheelPicker
        var currentRow: Int = 0
        var hapticEngine: CHHapticEngine?

        init(_ parent: HapticWheelPicker) {
            self.parent = parent
            super.init()
            setupHaptics()
        }

        private func setupHaptics() {
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
            do {
                hapticEngine = try CHHapticEngine()
                try hapticEngine?.start()
            } catch {
                print("Haptic engine error: \(error)")
            }
        }

        func triggerHaptic(forRow row: Int) {
            if row != currentRow && row >= 0 && row < parent.range.count {
                currentRow = row
                playHaptic()
            }
        }

        private func playHaptic() {
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
                  let engine = hapticEngine else { return }

            // Create a sharp, short haptic event (like picker tick)
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)

            do {
                let pattern = try CHHapticPattern(events: [event], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: 0)
            } catch {
                print("Haptic play error: \(error)")
            }
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            1
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            parent.range.count
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            36
        }

        func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
            let cycles = parent.range.lowerBound + row
            let total = parent.durationPerCycle * cycles
            let minutes = total / 60
            let seconds = total % 60

            let durationText: String
            if minutes > 0 && seconds > 0 {
                durationText = "\(minutes)m \(seconds)s"
            } else if minutes > 0 {
                durationText = "\(minutes)m"
            } else {
                durationText = "\(seconds)s"
            }

            let title = "\(cycles) cycles • \(durationText)"
            return NSAttributedString(
                string: title,
                attributes: [.foregroundColor: UIColor.white]
            )
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            parent.selection = parent.range.lowerBound + row
            currentRow = row
        }
    }
}

/// Custom UIPickerView subclass that intercepts scroll events for haptic feedback
class HapticPickerView: UIPickerView {
    weak var coordinator: HapticWheelPicker.Coordinator?
    private var displayLink: CADisplayLink?
    private let rowHeight: CGFloat = 36

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            startDisplayLink()
        } else {
            stopDisplayLink()
        }
    }

    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(checkCurrentRow))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func checkCurrentRow() {
        // Find the table view inside picker
        guard let tableView = findTableView(in: self) else { return }

        let centerY = tableView.contentOffset.y + tableView.bounds.height / 2
        let estimatedRow = Int(round(centerY / rowHeight)) - 1
        let clampedRow = max(0, min(estimatedRow, numberOfRows(inComponent: 0) - 1))

        coordinator?.triggerHaptic(forRow: clampedRow)
    }

    private func findTableView(in view: UIView) -> UITableView? {
        for subview in view.subviews {
            if let tableView = subview as? UITableView {
                return tableView
            }
            if let found = findTableView(in: subview) {
                return found
            }
        }
        return nil
    }

    deinit {
        stopDisplayLink()
    }
}

#Preview {
    StartViewiOS(viewModel: BreathingViewModeliOS()) { }
        .preferredColorScheme(.dark)
}
