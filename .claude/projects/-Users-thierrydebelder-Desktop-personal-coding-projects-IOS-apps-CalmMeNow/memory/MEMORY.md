# CalmMeNow – Session Memory

## Project Overview
- iOS app (Swift/SwiftUI), Xcode 16, iOS 17.6+ deployment target
- Bundle ID: `com.thierrydb.CalmMeNow`, Display name: "Calm SOS"
- Uses **PBXFileSystemSynchronizedRootGroup** — new Swift files added to the filesystem are automatically included in the build. No project.pbxproj edits needed for new files.
- App is currently **100% free** — no content is gated behind a paywall yet (paywall infrastructure with RevenueCat exists but nothing is locked)

## Key Architecture
- `Color(hex: String)` extension lives in `Utils/Color+Hex.swift` — correct usage is `Color(hex: "#RRGGBB")`
- `HapticManager.shared` — singleton, methods: `lightImpact()`, `mediumImpact()`, `heavyImpact()`, `success()`, `selection()`, `emotionButtonTap()`, `emergencyButtonTap()`
- `SpeechService` — `ObservableObject`, `speak(_ text: String)`, `stop()`, `stopAll()`. Use `@StateObject private var speechService = SpeechService()`
- `@AppStorage("prefSounds")` — user preference for audio/TTS (check before calling speechService.speak)
- `AudioManager.shared` — plays background audio files
- `PaywallManager.shared` — `requestAIAccess() async -> Bool`, `guardAIOrPaywall(...)`
- `RevenueCatService.shared` — subscription backend

## App Structure
### Main Navigation (`MainTabView`)
- **Home** tab → `ContentView`
- **Journal** tab → `JournalListView` (biometric-locked)
- **Settings** tab → `SettingsView`

### Home Screen Cards (ContentView)
- 🚨 CALM ME DOWN NOW button → `EmergencyCalmView` (ALWAYS FREE, never gate)
- 2×2 grid: Games | Panic Plan (AI) | Daily Coach (AI) | Smart Plan (AI)
- Full-width: 🌱 Grounding → `SomaticGroundingView` ← **NEW (built this session)**
- Full-width: ✨ Positive Boost → `PositiveQuotesView`
- Streak card → `StreakHeatmapView`/`StreakCardView`

## Features Built This Session
### `SomaticGroundingView` (`Views/Grounding/SomaticGroundingView.swift`)
- Full interactive 5-4-3-2-1 grounding experience
- 3 phases: intro → 5 sense screens → completion
- Per-sense colored backgrounds with animation: SEE=blue, TOUCH=purple, HEAR=teal, SMELL=amber, TASTE=rose
- Tappable dot checkboxes (N dots per sense), haptic on each tap, auto-advance when all tapped
- TTS reads each prompt (respects `prefSounds`)
- Progress bar, skip button, "You're here. You're now." completion screen
- Also replaces old `GroundingExerciseView` in `EmergencyStepRunnerView.swift`

## Planned Premium Features (not yet built)
1. ~~Somatic Grounding 5-4-3-2-1~~ ✅ Done
2. Trigger Tracker + AI pattern insights
3. Custom Breathing Programs library
4. Mood trend charts (exportable for therapist)
5. Night Mode / Nightmare Protocol
6. Voice-guided body scan
7. Custom affirmations engine
8. Flashback Interruption Protocol (PTSD-specific)
9. Safe Person Card
10. Apple Watch complication

## SourceKit Diagnostics Note
SourceKit shows "Cannot find X in scope" errors across files — these are IDE-only cross-file resolution artifacts. Xcode compiles correctly since all files are in the same module via PBXFileSystemSynchronizedRootGroup.
