import AVFoundation
import UIKit

/// Manages audio feedback for iOS breathing sessions
@MainActor
final class AudioManageriOS: ObservableObject {
    static let shared = AudioManageriOS()

    private var audioPlayer: AVAudioPlayer?
    private var backgroundPlayer: AVAudioPlayer?

    // Audio session configuration
    private let audioSession = AVAudioSession.sharedInstance()

    private init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            // Configure for playback, mixing with others
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    // MARK: - Phase Sounds

    func playPhaseSound(_ phase: BreathingPhase) {
        // Generate tone based on phase
        switch phase {
        case .inhale:
            playTone(frequency: 440, duration: 0.3) // A4 - rising feel
        case .hold:
            playTone(frequency: 392, duration: 0.2) // G4 - neutral
        case .exhale:
            playTone(frequency: 349, duration: 0.3) // F4 - falling feel
        }
    }

    func playCompletion() {
        // Play a pleasant completion sound
        playTone(frequency: 523, duration: 0.2) // C5
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.playTone(frequency: 659, duration: 0.2) // E5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.playTone(frequency: 784, duration: 0.4) // G5
        }
    }

    // MARK: - Tone Generation

    private func playTone(frequency: Double, duration: Double) {
        let sampleRate: Double = 44100
        let samples = Int(sampleRate * duration)

        var audioData = [Float](repeating: 0, count: samples)

        // Generate sine wave with fade in/out
        for i in 0..<samples {
            let time = Double(i) / sampleRate
            let amplitude = calculateEnvelope(sample: i, totalSamples: samples)
            audioData[i] = Float(amplitude * sin(2.0 * .pi * frequency * time))
        }

        // Convert to Data
        let data = audioData.withUnsafeBytes { buffer in
            Data(buffer)
        }

        // Create audio buffer and play
        playAudioData(data, sampleRate: sampleRate)
    }

    private func calculateEnvelope(sample: Int, totalSamples: Int) -> Double {
        let fadeLength = min(totalSamples / 10, 2000) // 10% fade, max ~45ms
        let position = Double(sample)
        let total = Double(totalSamples)
        let fade = Double(fadeLength)

        if sample < fadeLength {
            return position / fade * 0.3 // Fade in, max 0.3 volume
        } else if sample > totalSamples - fadeLength {
            return (total - position) / fade * 0.3 // Fade out
        }
        return 0.3 // Sustain at 0.3 volume
    }

    private func playAudioData(_ data: Data, sampleRate: Double) {
        // For production, you would use proper audio generation
        // This is a simplified placeholder - in real app, use bundled audio files
        // or proper audio synthesis with AudioToolbox/AudioUnit

        // Play system sound as fallback
        AudioServicesPlaySystemSound(1104) // Soft tap sound
    }

    // MARK: - Control

    func pause() {
        audioPlayer?.pause()
    }

    func resume() {
        audioPlayer?.play()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
