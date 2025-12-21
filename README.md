# Breathe 478 - Apple Watch App

A standalone Apple Watch app implementing the 4-7-8 breathing technique with beautiful petal animations and haptic feedback guidance, inspired by Apple's Mindfulness app.

## Features

- **4-7-8 Breathing Technique**: 4 seconds inhale, 7 seconds hold, 8 seconds exhale
- **Petal Animation**: Beautiful flower-petal breathing animation
- **Haptic Feedback**: Rhythm guidance during breathing phases
- **Customizable Cycles**: 1-10 breathing cycles (default: 4)
- **Pause/Resume**: Tap to pause or resume your session
- **Bilingual Support**: English and Chinese localization

## Requirements

- watchOS 10.0+
- Xcode 15.0+
- Swift 5.9+

## Project Setup

### Option 1: Create New Xcode Project

1. Open Xcode and select **File > New > Project**
2. Choose **watchOS > App** template
3. Configure the project:
   - Product Name: `Breathe478`
   - Team: Your Apple Developer Team
   - Organization Identifier: Your identifier (e.g., `com.yourname`)
   - Interface: **SwiftUI**
   - Watch-only App: **Yes**
   - Language: **Swift**

4. Delete the auto-generated files in the project

5. Drag all files from the `Breathe478 Watch App` folder into the Xcode project:
   - `Breathe478App.swift`
   - `Info.plist`
   - `Models/` folder
   - `ViewModels/` folder
   - `Views/` folder
   - `Managers/` folder
   - `Resources/` folder

6. Ensure all Swift files are added to the watch app target

### Option 2: Use the files directly

Copy all the source files into an existing watchOS project structure.

## Project Structure

```
Breathe478 Watch App/
├── Breathe478App.swift          # App entry point
├── Info.plist                   # App configuration
├── Models/
│   ├── BreathingPhase.swift     # Breathing phase enum (inhale, hold, exhale)
│   └── BreathingState.swift     # Session state management
├── ViewModels/
│   └── BreathingViewModel.swift # Core business logic and timers
├── Views/
│   ├── ContentView.swift        # Main navigation container
│   ├── StartView.swift          # Session setup screen
│   ├── BreathingView.swift      # Active breathing session
│   ├── CompletionView.swift     # Session complete screen
│   ├── PetalView.swift          # Breathing flower animation
│   └── Theme.swift              # Colors and styles
├── Managers/
│   └── HapticManager.swift      # Haptic feedback controller
└── Resources/
    ├── Localizable.xcstrings    # Localization strings
    └── Assets.xcassets/         # App icons and colors
```

## Usage

1. **Start Screen**: Select the number of cycles (1-10) and tap "Start"
2. **Breathing Session**: Follow the animation and haptic cues
   - Inhale as the flower expands
   - Hold when expanded
   - Exhale as the flower contracts
3. **Pause/Resume**: Tap anywhere on screen to pause/resume
4. **End Early**: Swipe left or use the X button to end early
5. **Completion**: View your session stats and choose to repeat or finish

## Haptic Feedback Pattern

| Transition | Haptic Type | Purpose |
|------------|-------------|---------|
| Start Inhale | `.start` | Clear phase start signal |
| Start Hold | `.click` | Gentle transition cue |
| Start Exhale | `.directionDown` | Downward guidance |
| Cycle Complete | `.success` | Positive reinforcement |
| Session Complete | `.notification` | Strong completion signal |

During inhale and exhale phases, subtle rhythm clicks guide your breathing pace.

## Customization

### Colors
Edit `Theme.swift` to customize the color scheme:
```swift
static let primaryCyan = Color(red: 0.39, green: 0.82, blue: 1.0)
static let primaryMint = Color(red: 0.36, green: 0.90, blue: 0.82)
```

### Timing
Edit `BreathingPhase.swift` to adjust phase durations:
```swift
var duration: TimeInterval {
    switch self {
    case .inhale: return 4.0  // Adjust inhale duration
    case .hold: return 7.0    // Adjust hold duration
    case .exhale: return 8.0  // Adjust exhale duration
    }
}
```

## License

MIT License - Feel free to use and modify for your projects.
