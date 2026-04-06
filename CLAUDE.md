# CalmMeNow — Claude Code Instructions

## Project Overview
iOS app (SwiftUI, Xcode 16+) for panic and anxiety relief. Targets: main app, Watch companion (`CalmMeNowWatch Watch App/`), widget (`CalmMeNowWidget/`).

## Build & Run
Open `CalmMeNow.xcodeproj` in Xcode. No special build scripts — just build and run.

## File Inclusion
Uses `PBXFileSystemSynchronizedRootGroup` — any `.swift` file added to `CalmMeNow/` is **automatically included** in the build. No need to touch `project.pbxproj`.

## Package Dependencies
- RevenueCat + PaywallKit — subscription/paywall
- Firebase (Analytics, Auth, AppCheck, Functions)
- Lottie — animated mascots

## Key Architecture
- **Singletons:** `HapticManager.shared`, `PaywallManager.shared`, `AudioManager.shared`, `ProgressTracker.shared`, `BreathingProgramService.shared`, `CheckInReminderService.shared`, `BreathingReminderService.shared`
- **Premium gating:** `await paywallManager.requestAIAccess()` → returns Bool, shows paywall automatically
- **`PaywallManager.freeLaunchMode = true`** — all features currently free. Set to `false` before shipping to enforce paywalls.
- **AppStorage keys:** `"prefVoice"`, `"prefHaptics"`, `"hasShownFirstLaunchOverlay"`

## Important Types
- `BreathingPhase` — `.inhale`, `.hold`, `.exhale`, `.hold2` (top of `BreathingExerciseView.swift`)
- `BreathingOrb(scale:opacity:technique:)` — takes `BreathingTechnique`
- `BoxBreathingVisual(progress:currentSide:)` — both in `BreathingExerciseView.swift`
- `EmotionCard(emoji:emotion:subtext:isSelected:onTap:isPremium:hasAccess:)` — in `ContentView.swift`
- `Color(hex:)` — available app-wide
- `SpeechService` — ObservableObject, `speak(_:rate:pitch:)`, `stopAll()`

## Home Screen Card Order
1. Emergency Calm button
2. Grounding + Body Relax (HStack)
3. Breathing Programs (full-width)
4. Games + Daily Coach (HStack)
5. Panic Plan + Smart Plan (HStack)
6. Positive Boost, Crisis Help, Trigger Tracker, Night Protocol, Safe Person Card

## Do Not Modify
- `BreathingExerciseView.swift` — used by `TailoredExperienceView`, must stay intact

## Deep Links (Widgets → App)
- `calmmenow://emergency` → opens `EmergencyCalmView`
- `calmmenow://night` → opens `NightProtocolView`
- Handled in `DeepLinkManager` (inside `CalmMeNowApp.swift`), consumed in `MainTabView`

## SourceKit False Positives
After creating new files, SourceKit shows "Cannot find type X in scope" errors for cross-file references until Xcode re-indexes. These clear on first build — ignore them.

## Git Commit Style
- Never add `Co-Authored-By: Claude...` trailers to commits.
- Keep messages concise and imperative.

## Pending Before Ship
- Set `PaywallManager.freeLaunchMode = false` in `PaywallManager.swift` to enable premium gating.
