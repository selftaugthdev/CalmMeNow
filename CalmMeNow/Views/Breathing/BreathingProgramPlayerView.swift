import SwiftUI

struct BreathingProgramPlayerView: View {
  @Environment(\.dismiss) private var dismiss
  let program: BreathingProgram

  @StateObject private var speechService = SpeechService()
  @AppStorage("prefVoice") private var voiceGuidanceEnabled = false
  @AppStorage("prefHaptics") private var hapticsEnabled = true
  @StateObject private var audioManager = AudioManager.shared

  // Ambient sound selection — nil means no sound
  @State private var selectedAmbientSound: AmbientSound? = nil

  enum AmbientSound: String, CaseIterable, Identifiable {
    case night       = "ethereal-night-loop"
    case rain        = "ambient-rain"
    case ocean       = "ambient-ocean"
    case brownNoise  = "ambient-brown-noise"
    case whiteNoise  = "ambient-white-noise"

    var id: String { rawValue }
    var label: String {
      switch self {
      case .night:      return "Night"
      case .rain:       return "Rain"
      case .ocean:      return "Ocean"
      case .brownNoise: return "Brown"
      case .whiteNoise: return "White"
      }
    }
    var icon: String {
      switch self {
      case .night:      return "moon.stars.fill"
      case .rain:       return "cloud.rain.fill"
      case .ocean:      return "water.waves"
      case .brownNoise: return "waveform"
      case .whiteNoise: return "waveform.circle"
      }
    }
  }

  @State private var isExerciseActive = false
  @State private var isStarting = false
  @State private var timeRemaining = 0
  @State private var currentPhase: BreathingPhase = .inhale

  // Orb animation state
  @State private var orbScale: CGFloat = 1.0
  @State private var orbOpacity: Double = 0.8

  // Box animation state
  @State private var boxProgress: CGFloat = 0.0
  @State private var currentBoxSide = 0

  @State private var exerciseTimer: Timer?
  @State private var cycleTimer: Timer?
  @State private var isCleanedUp = false

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          Color(red: 0.05, green: 0.07, blue: 0.20),
          Color(red: 0.08, green: 0.10, blue: 0.26),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack(spacing: 30) {
        // Header
        HStack {
          Button(action: {
            cleanup()
            dismiss()
          }) {
            Image(systemName: "xmark.circle.fill")
              .font(.title2)
              .foregroundColor(.white.opacity(0.5))
          }

          Spacer()

          VStack(spacing: 4) {
            Text("\(program.emoji) \(program.name)")
              .font(.title2)
              .fontWeight(.semibold)
              .foregroundColor(.white)
            Text(program.ratioLabel)
              .font(.caption)
              .foregroundColor(.white.opacity(0.5))
          }

          Spacer()

          Text(timeString(timeRemaining))
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(Color(red: 0.6, green: 0.75, blue: 1.0))
            .frame(width: 54)
        }
        .padding()

        Spacer()

        if isExerciseActive {
          // Breathing visual
          ZStack {
            if program.style == .box {
              BoxBreathingVisual(progress: boxProgress, currentSide: currentBoxSide)
            } else {
              BreathingOrb(
                scale: orbScale,
                opacity: orbOpacity,
                technique: program.style == .physiologicalSigh
                  ? .physiologicalSigh : .coherenceBreathing
              )
            }
          }
          .frame(width: 220, height: 220)

          // Phase label
          VStack(spacing: 8) {
            Text(phaseLabel)
              .font(.title)
              .fontWeight(.semibold)
              .foregroundColor(.white)
              .animation(.easeInOut(duration: 0.3), value: currentPhase)

            Text(program.description)
              .font(.caption)
              .foregroundColor(.white.opacity(0.55))
              .multilineTextAlignment(.center)
              .padding(.horizontal, 40)
          }

        } else {
          // Pre-start info card
          VStack(spacing: 20) {
            Text(program.emoji)
              .font(.system(size: 60))

            Text(program.name)
              .font(.title)
              .fontWeight(.bold)
              .foregroundColor(.white)

            Text(program.description)
              .font(.body)
              .foregroundColor(.white.opacity(0.6))
              .multilineTextAlignment(.center)
              .padding(.horizontal, 30)

            HStack(spacing: 30) {
              VStack(spacing: 4) {
                Text(program.ratioLabel)
                  .font(.headline)
                  .fontWeight(.semibold)
                  .foregroundColor(.white)
                Text("Ratio")
                  .font(.caption)
                  .foregroundColor(.white.opacity(0.5))
              }
              VStack(spacing: 4) {
                Text(program.durationLabel)
                  .font(.headline)
                  .fontWeight(.semibold)
                  .foregroundColor(.white)
                Text("Duration")
                  .font(.caption)
                  .foregroundColor(.white.opacity(0.5))
              }
            }
            .padding()
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
            )

            // Voice toggle
            HStack {
              Image(
                systemName: voiceGuidanceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill"
              )
              .foregroundColor(voiceGuidanceEnabled ? Color(red: 0.6, green: 0.75, blue: 1.0) : .white.opacity(0.4))
              Text("Voice guidance")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
              Spacer()
              Toggle("", isOn: $voiceGuidanceEnabled)
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.6, green: 0.75, blue: 1.0)))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            )

            // Ambient sound picker
            VStack(alignment: .leading, spacing: 10) {
              HStack {
                Image(systemName: "music.note")
                  .foregroundColor(selectedAmbientSound != nil ? Color(red: 0.6, green: 0.75, blue: 1.0) : .white.opacity(0.4))
                Text("Ambient sound")
                  .font(.subheadline)
                  .foregroundColor(.white.opacity(0.85))
              }

              LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                Button {
                  selectedAmbientSound = nil
                } label: {
                  Text("Off")
                    .font(.caption.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                      RoundedRectangle(cornerRadius: 20)
                        .fill(selectedAmbientSound == nil ? Color(red: 0.6, green: 0.75, blue: 1.0) : Color.white.opacity(0.12))
                    )
                    .foregroundColor(.white)
                }

                ForEach(AmbientSound.allCases) { sound in
                  Button {
                    selectedAmbientSound = selectedAmbientSound == sound ? nil : sound
                  } label: {
                    HStack(spacing: 4) {
                      Image(systemName: sound.icon)
                        .font(.caption)
                      Text(sound.label)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                      RoundedRectangle(cornerRadius: 20)
                        .fill(selectedAmbientSound == sound ? Color(red: 0.6, green: 0.75, blue: 1.0) : Color.white.opacity(0.12))
                    )
                    .foregroundColor(.white)
                  }
                }
              }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            )

            Button(action: {
              guard !isStarting else { return }
              isStarting = true
              startExercise()
              DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { isStarting = false }
            }) {
              Text(isStarting ? "Starting…" : "Start")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 48)
                .padding(.vertical, 14)
                .background(
                  RoundedRectangle(cornerRadius: 25)
                    .fill(isStarting ? Color.white.opacity(0.2) : Color(red: 0.6, green: 0.75, blue: 1.0))
                )
            }
            .disabled(isStarting)
          }
          .padding(.horizontal, 30)
        }

        Spacer()
      }
    }
    .onDisappear { cleanup() }
  }

  // MARK: - Phase Label

  private var phaseLabel: String {
    switch currentPhase {
    case .inhale:
      return program.style == .physiologicalSigh ? "Inhale…" : "Inhale"
    case .hold:
      return "Hold"
    case .exhale:
      return program.style == .physiologicalSigh ? "Long exhale…" : "Exhale"
    case .hold2:
      return "Hold"
    }
  }

  // MARK: - Exercise Control

  private func startExercise() {
    isCleanedUp = false
    isExerciseActive = true
    timeRemaining = program.duration
    currentPhase = .inhale

    if let sound = selectedAmbientSound {
      audioManager.playSound(sound.rawValue, loop: true)
    }
    orbScale = 1.0
    orbOpacity = 0.8
    boxProgress = 0.0
    currentBoxSide = 0

    exerciseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      guard !isCleanedUp else { return }
      if timeRemaining > 0 {
        timeRemaining -= 1
      } else {
        cleanup()
      }
    }

    if voiceGuidanceEnabled {
      speechService.speak("Starting \(program.name). Follow the visual guide.", rate: 0.4, pitch: 0.9)
      DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        guard !isCleanedUp else { return }
        startCycleTimer()
      }
    } else {
      startCycleTimer()
    }
  }

  private func startCycleTimer() {
    performCycle()
    let interval = program.cycleDuration
    cycleTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
      guard !isCleanedUp else { return }
      performCycle()
    }
  }

  private func performCycle() {
    switch program.style {
    case .physiologicalSigh:
      performPhysiologicalSighCycle()
    case .box:
      performBoxCycle()
    case .orb:
      performGenericOrbCycle()
    }
  }

  // MARK: - Physiological Sigh Cycle (double inhale)

  private func performPhysiologicalSighCycle() {
    currentPhase = .inhale
    if hapticsEnabled { HapticManager.shared.breathingPhase() }
    if voiceGuidanceEnabled { speechService.speak("Inhale", rate: 0.4, pitch: 0.9) }
    withAnimation(.easeInOut(duration: 2.0)) { orbScale = 1.3; orbOpacity = 1.0 }

    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      guard !isCleanedUp else { return }
      if voiceGuidanceEnabled { speechService.speak("Top off inhale", rate: 0.4, pitch: 0.9) }
      withAnimation(.easeInOut(duration: 1.0)) { orbScale = 1.6; orbOpacity = 1.0 }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
      guard !isCleanedUp else { return }
      currentPhase = .exhale
      if hapticsEnabled { HapticManager.shared.breathingPhase() }
      if voiceGuidanceEnabled {
        speechService.speak("Long exhale", rate: 0.35, pitch: 0.85)
      }
      withAnimation(.easeInOut(duration: program.exhale)) { orbScale = 0.7; orbOpacity = 0.6 }
    }
  }

  // MARK: - Box Breathing Cycle

  private func performBoxCycle() {
    // Reset for clean cycle
    boxProgress = 0.0
    currentBoxSide = 0
    currentPhase = .inhale
    if hapticsEnabled { HapticManager.shared.breathingPhase() }
    if voiceGuidanceEnabled { speechService.speak("Inhale", rate: 0.4, pitch: 0.9) }
    withAnimation(.easeInOut(duration: program.inhale)) { boxProgress = 0.25 }

    let holdStart = program.inhale
    DispatchQueue.main.asyncAfter(deadline: .now() + holdStart) {
      guard !isCleanedUp else { return }
      currentPhase = .hold
      currentBoxSide = 1
      if hapticsEnabled { HapticManager.shared.breathingPhase() }
      if voiceGuidanceEnabled { speechService.speak("Hold", rate: 0.4, pitch: 0.9) }
      withAnimation(.easeInOut(duration: program.holdAfterInhale)) { boxProgress = 0.5 }
    }

    let exhaleStart = program.inhale + program.holdAfterInhale
    DispatchQueue.main.asyncAfter(deadline: .now() + exhaleStart) {
      guard !isCleanedUp else { return }
      currentPhase = .exhale
      currentBoxSide = 2
      if hapticsEnabled { HapticManager.shared.breathingPhase() }
      if voiceGuidanceEnabled { speechService.speak("Exhale", rate: 0.4, pitch: 0.9) }
      withAnimation(.easeInOut(duration: program.exhale)) { boxProgress = 0.75 }
    }

    let hold2Start = program.inhale + program.holdAfterInhale + program.exhale
    DispatchQueue.main.asyncAfter(deadline: .now() + hold2Start) {
      guard !isCleanedUp else { return }
      currentPhase = .hold2
      currentBoxSide = 3
      if hapticsEnabled { HapticManager.shared.breathingPhase() }
      if voiceGuidanceEnabled { speechService.speak("Hold", rate: 0.4, pitch: 0.9) }
      withAnimation(.easeInOut(duration: program.holdAfterExhale)) { boxProgress = 1.0 }
    }
  }

  // MARK: - Generic Orb Cycle

  private func performGenericOrbCycle() {
    currentPhase = .inhale
    if hapticsEnabled { HapticManager.shared.breathingPhase() }
    if voiceGuidanceEnabled { speechService.speak("Inhale", rate: 0.4, pitch: 0.9) }
    withAnimation(.easeInOut(duration: program.inhale)) { orbScale = 1.5; orbOpacity = 1.0 }

    var offset = program.inhale

    if program.holdAfterInhale > 0 {
      DispatchQueue.main.asyncAfter(deadline: .now() + offset) {
        guard !isCleanedUp else { return }
        currentPhase = .hold
        if hapticsEnabled { HapticManager.shared.breathingPhase() }
        if voiceGuidanceEnabled { speechService.speak("Hold", rate: 0.4, pitch: 0.9) }
      }
      offset += program.holdAfterInhale
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + offset) {
      guard !isCleanedUp else { return }
      currentPhase = .exhale
      if hapticsEnabled { HapticManager.shared.breathingPhase() }
      if voiceGuidanceEnabled { speechService.speak("Exhale", rate: 0.4, pitch: 0.85) }
      withAnimation(.easeInOut(duration: program.exhale)) { orbScale = 0.8; orbOpacity = 0.7 }
    }
    offset += program.exhale

    if program.holdAfterExhale > 0 {
      DispatchQueue.main.asyncAfter(deadline: .now() + offset) {
        guard !isCleanedUp else { return }
        currentPhase = .hold2
        if hapticsEnabled { HapticManager.shared.breathingPhase() }
        if voiceGuidanceEnabled { speechService.speak("Hold", rate: 0.4, pitch: 0.9) }
      }
    }
  }

  // MARK: - Cleanup

  private func cleanup() {
    isCleanedUp = true
    isExerciseActive = false
    isStarting = false

    exerciseTimer?.invalidate()
    cycleTimer?.invalidate()
    exerciseTimer = nil
    cycleTimer = nil

    speechService.stopAll()
    audioManager.stopSoundImmediately()

    orbScale = 1.0
    orbOpacity = 0.8
    boxProgress = 0.0
    currentBoxSide = 0
    currentPhase = .inhale
    timeRemaining = 0
  }

  // MARK: - Helpers

  private func timeString(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return m > 0 ? "\(m):\(String(format: "%02d", s))" : "\(s)s"
  }
}

#Preview {
  BreathingProgramPlayerView(
    program: BreathingProgramService.shared.builtInPrograms[0]
  )
}
