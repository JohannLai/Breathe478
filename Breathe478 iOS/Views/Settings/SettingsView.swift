import SwiftUI

/// Settings view for iOS app
struct SettingsView: View {
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("screenAwakeEnabled") private var screenAwakeEnabled = true
    @AppStorage("defaultCycles") private var defaultCycles = 4

    @State private var showingAbout = false
    @State private var showingHealthAccess = false

    var body: some View {
        NavigationStack {
            List {
                // Session Settings
                Section {
                    // Default cycles
                    HStack {
                        Label("Default Cycles", systemImage: "repeat")
                            .foregroundColor(Theme.textPrimary)

                        Spacer()

                        Picker("", selection: $defaultCycles) {
                            ForEach(1...10, id: \.self) { count in
                                Text("\(count)").tag(count)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.primaryMint)
                    }

                    // Haptic toggle
                    Toggle(isOn: $hapticEnabled) {
                        Label("Haptic Feedback", systemImage: "hand.tap")
                            .foregroundColor(Theme.textPrimary)
                    }
                    .tint(Theme.primaryMint)

                    // Screen awake toggle
                    Toggle(isOn: $screenAwakeEnabled) {
                        Label("Keep Screen On", systemImage: "sun.max")
                            .foregroundColor(Theme.textPrimary)
                    }
                    .tint(Theme.primaryMint)
                } header: {
                    Text("Session")
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Color.white.opacity(0.05))

                // Health Section
                Section {
                    Button(action: { showingHealthAccess = true }) {
                        HStack {
                            Label("Health Access", systemImage: "heart.fill")
                                .foregroundColor(Theme.textPrimary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                } header: {
                    Text("Health")
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Color.white.opacity(0.05))

                // About Section
                Section {
                    Button(action: { showingAbout = true }) {
                        HStack {
                            Label("About 4-7-8 Breathing", systemImage: "info.circle")
                                .foregroundColor(Theme.textPrimary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.textTertiary)
                        }
                    }

                    HStack {
                        Label("Version", systemImage: "number")
                            .foregroundColor(Theme.textPrimary)

                        Spacer()

                        Text(appVersion)
                            .foregroundColor(Theme.textSecondary)
                    }
                } header: {
                    Text("About")
                        .foregroundColor(Theme.textSecondary)
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundColor)
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingHealthAccess) {
                HealthAccessView()
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Theme.primaryGradient)
                                .frame(width: 80, height: 80)

                            Image(systemName: "wind")
                                .font(.system(size: 36))
                                .foregroundColor(.black)
                        }

                        Text("4-7-8 Breathing")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)

                    // What is it
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What is 4-7-8 Breathing?")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(Theme.textPrimary)

                        Text("The 4-7-8 breathing technique, also known as \"relaxing breath,\" was developed by Dr. Andrew Weil. It's based on an ancient yogic technique called pranayama, which helps practitioners gain control over their breathing.")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(Theme.textSecondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)

                    // How it works
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How It Works")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(Theme.textPrimary)

                        VStack(spacing: 16) {
                            BreathingStepRow(
                                number: "1",
                                title: "Inhale",
                                duration: "4 seconds",
                                description: "Breathe in quietly through your nose",
                                color: Theme.htmlTeal
                            )

                            BreathingStepRow(
                                number: "2",
                                title: "Hold",
                                duration: "7 seconds",
                                description: "Hold your breath",
                                color: Theme.htmlGreen
                            )

                            BreathingStepRow(
                                number: "3",
                                title: "Exhale",
                                duration: "8 seconds",
                                description: "Exhale completely through your mouth",
                                color: Theme.htmlBlue
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Benefits
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Benefits")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(Theme.textPrimary)

                        VStack(alignment: .leading, spacing: 8) {
                            BenefitRow(icon: "moon.fill", text: "Helps you fall asleep faster")
                            BenefitRow(icon: "heart.fill", text: "Reduces anxiety and stress")
                            BenefitRow(icon: "brain.head.profile", text: "Improves focus and concentration")
                            BenefitRow(icon: "waveform.path.ecg", text: "Can improve heart rate variability")
                            BenefitRow(icon: "lungs.fill", text: "Strengthens respiratory function")
                        }
                    }
                    .padding(.horizontal, 20)

                    // Tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tips for Practice")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(Theme.textPrimary)

                        Text("• Practice in a comfortable position\n• Start with 4 cycles and gradually increase\n• Best practiced before sleep or when feeling stressed\n• Consistency is key - practice daily for best results")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(Theme.textSecondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 32)
                }
            }
            .background(Theme.backgroundColor)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primaryMint)
                }
            }
        }
    }
}

struct BreathingStepRow: View {
    let number: String
    let title: String
    let duration: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay {
                    Text(number)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)

                    Text("• \(duration)")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(color)
                }

                Text(description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(Theme.textTertiary)
            }

            Spacer()
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Theme.primaryMint)
                .frame(width: 24)

            Text(text)
                .font(.system(.body, design: .rounded))
                .foregroundColor(Theme.textSecondary)

            Spacer()
        }
    }
}

// MARK: - Health Access View

struct HealthAccessView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isAuthorized = false

    private let healthKitManager = HealthKitManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.red)
                }

                // Title
                VStack(spacing: 8) {
                    Text("Health Integration")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundColor(Theme.textPrimary)

                    Text("Breathe 478 uses HealthKit to track your HRV and save mindful minutes.")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Permissions list
                VStack(alignment: .leading, spacing: 16) {
                    PermissionRow(
                        icon: "waveform.path.ecg",
                        title: "Heart Rate Variability",
                        description: "Track HRV before and after sessions"
                    )

                    PermissionRow(
                        icon: "heart",
                        title: "Heart Rate",
                        description: "Monitor average heart rate during practice"
                    )

                    PermissionRow(
                        icon: "figure.mind.and.body",
                        title: "Mindful Minutes",
                        description: "Save sessions as mindful minutes"
                    )
                }
                .padding(20)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)

                Spacer()

                // Authorize button
                Button(action: requestAuthorization) {
                    Text(isAuthorized ? "Access Granted" : "Enable Health Access")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundColor(isAuthorized ? Theme.textSecondary : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            if isAuthorized {
                                Color.white.opacity(0.1)
                            } else {
                                Theme.primaryGradient
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(isAuthorized)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Theme.backgroundColor)
            .navigationTitle("Health Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primaryMint)
                }
            }
            .task {
                // Check current authorization status
                await checkAuthorization()
            }
        }
    }

    private func requestAuthorization() {
        Task {
            await healthKitManager.requestAuthorization()
            await MainActor.run {
                isAuthorized = healthKitManager.isAuthorized
            }
        }
    }

    private func checkAuthorization() async {
        // HealthKit doesn't provide a direct way to check authorization status
        // for read permissions, so we attempt to fetch data to verify
        let hrv = await healthKitManager.fetchLatestHRV()
        await MainActor.run {
            // If we got data or no error, assume authorized
            isAuthorized = hrv != nil
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.red)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(Theme.textPrimary)

                Text(description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(Theme.textTertiary)
            }

            Spacer()
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
