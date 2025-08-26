# Instant Calm – iOS App

**One-tap relief for sudden stress, anxiety, anger, or overwhelm.**  
Built with SwiftUI. Designed for simplicity, speed, and emotional clarity.

---

## 🧠 Core Idea

A minimalist iOS app that helps users regulate their nervous system within **60 seconds** when overwhelmed by stress, panic, sadness, or anger — e.g. after being cut off in traffic, receiving bad news, or a sudden emotional spike.

---

## ✅ Core Principles

- **Zero friction**: No login, no setup, no overwhelm.
- **Fast access**: 1-tap access to relief.
- **Progressive clarity**: From broad emotion → specific state → tailored relief.
- **Accessibility first**: Designed for shaky hands, racing minds, and heightened emotion.

---

## 🎯 Target User

- People experiencing **panic attacks**, **emotional flooding**, or **sudden spikes** of stress or frustration.
- ADHD, autistic, HSP, anxious or emotionally intense users.
- Situational triggers: co-worker said something mean, social rejection, car cuts you off, bad comment, etc.

---

## 🧱 App Architecture (Current)

### Home Screen

- 🔘 "CALM ME DOWN NOW" (always visible/emergency top button)
- 🧘 App icon / logo
- 🗣️ "Tap how you feel"
- Subtitle: "We'll help you feel better in 60 seconds."
- 💠 Emotion Grid (3 buttons):
  - 😰 Anxious
  - 😡 Angry
  - 😢 Sad

---

### Emotion Tap → Intensity Modal

When a user taps an emotion card:

- Fullscreen modal:
  - Text prompt: _"Are you feeling a little nervous or full panic?"_
  - 2 buttons:
    - 🟦 Mild (e.g., "A little nervous")
    - 🟥 Severe (e.g., "Full Panic")

---

### Relief Experience

Based on selection:

#### Mild:

- Calm ambient sound (rain, ocean, etc.)
- Short 60s animation: breathing bubble or tapping game
- "Try another | I feel better" buttons

#### Severe:

- Dimmed screen
- Focused breathing + grounding audio
- 30–60s calming sequence with minimal interaction
- Follow-up prompt: "Want to reflect? Try again?"

---

## 🌱 Planned Features (Future)

- [ ] **Soothing mini-games** (bubble pop, swipe to calm, etc.)
- [ ] **Lock screen widget**: Quick panic relief
- [ ] **Shortcut support**: Siri or back tap trigger
- [ ] **Breathing visual options**: Box, 4–7–8, paced
- [ ] **Journal mode (optional)**: "What happened just now?"
- [ ] **Streaks / gentle encouragement**: "You calmed yourself 3 days in a row"
- [ ] **Theme customization** (light/dark, background visuals)
- [ ] **Background looping mode** (leave the audio running)
- [ ] **Audio personalization** (chill beats vs. nature vs. guided)

---

## 📱 Best Practices

- Use **Haptics** for feedback (light tap, pulse at start/end of relief)
- Add **accessibility support** (VoiceOver, larger tap zones)
- **Store last used emotion** for quick relaunch
- Avoid **cognitive overload** — always prioritize clarity over complexity

---

## 🧰 Tech Stack

- **SwiftUI**
- **Xcode 16+**
- **Firebase Analytics** - For tracking user interactions and app usage
- **Audio playback**: AVFoundation or SwiftAudio
- (Optional) Future integrations: WidgetKit, CoreML (for emotion detection), HealthKit (for HR tracking)

## 🔥 Firebase Setup

This app uses Firebase Analytics to track user interactions. To set up Firebase:

1. **Create a Firebase project** at [Firebase Console](https://console.firebase.google.com/)
2. **Add an iOS app** to your Firebase project
3. **Download the `GoogleService-Info.plist`** file from Firebase Console
4. **Place the file** in the `CalmMeNow/` directory
5. **The file is already in `.gitignore`** to prevent committing sensitive data

**Note:** A template file `GoogleService-Info.plist.template` is provided to show the required structure.

---

## 🧪 Testing

- Test in real-world stress scenarios (simulate panic → test 3-tap flow)
- Include test users with neurodivergence
- Measure success by:
  - Completion rate of 60-second sequences
  - Reduction in panic intensity (user self-rated)
  - Re-use / return rates

---

## 👥 Contributors

**Solo Dev:** `@thierrydebelder`  
Designed in Cursor. Inspired by simplicity and compassion.

---

## 💡 Inspiration

- "A friend in your pocket" — support without judgment
- Stoic, Buddhist, and trauma-informed calming techniques
- The idea that just 1 minute of calm can change everything

---

## 📦 Assets Needed

- [ ] Audio files (calming, panic relief, loops)
- [ ] Emotion icons (SVG or PNG, large format)
- [ ] Breathing animation visuals or assets
- [ ] SFX for game / bubble popping
- [ ] Logo/icon export (App Store ready)

---

## 📲 App Store Positioning

**Name idea:** _"60 Second Calm"_ or _"In-The-Moment"_  
**Keywords:** anxiety, stress, panic, calm, relax, grounding  
**Tagline:** "Calm your mind. In 60 seconds."

---

## 🧘 Closing Note

This app isn't trying to be everything — it's trying to be _there_ when users need it most.  
Fast, kind, and instantly useful.

---
