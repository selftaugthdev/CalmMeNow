import AVFoundation
import SwiftUI

enum BreathingTechnique: String, CaseIterable {
  case physiologicalSigh = "Physiological Sigh"
  case boxBreathing = "Box Breathing"
  case coherenceBreathing = "Coherence Breathing"

  var description: String {
    switch self {
    case .physiologicalSigh:
      return "Two short inhales, one long exhale. Rapid stress relief."
    case .boxBreathing:
      return "4-4-4-4 pattern. Navy SEAL technique for focus."
    case .coherenceBreathing:
      return "5-5 pattern. Synchronizes with heart rate."
    }
  }

  var duration: Int {
    switch self {
    case .physiologicalSigh: return 60  // 1 minute
    case .boxBreathing: return 120  // 2 minutes
    case .coherenceBreathing: return 90  // 1.5 minutes
    }
  }
}

enum BreathingPhase {
  case inhale
  case hold
  case exhale
  case hold2
}

struct BreathingExerciseView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var speechService = SpeechService()
  @State private var selectedTechnique: BreathingTechnique = .physiologicalSigh
  @State private var isExerciseActive = false
  @State private var currentPhase: BreathingPhase = .inhale
  @State private var timeRemaining = 0
  @State private var phaseTimer: Timer?
  @State private var exerciseTimer: Timer?
  @State private var orbScale: CGFloat = 1.0
  @State private var orbOpacity: Double = 0.8
  @State private var boxProgress: CGFloat = 0.0
  @State private var currentBoxSide = 0
  @State private var voiceGuidanceEnabled = false

  // Haptic feedback
  let impactFeedback = UIImpactFeedbackGenerator(style: .light)

  var body: some View {
    ZStack {
      // Calming gradient background
      LinearGradient(
        gradient: Gradient(colors: [
          Color.blue.opacity(0.1),
          Color.purple.opacity(0.1),
          Color.mint.opacity(0.1),
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 30) {
        // Header
        HStack {
          Button(action: {
            stopExercise()
            presentationMode.wrappedValue.dismiss()
          }) {
            Image(systemName: "xmark.circle.fill")
              .font(.title2)
              .foregroundColor(.gray)
          }

          Spacer()

          VStack(spacing: 4) {
            Text("Breathing Exercise")
              .font(.title2)
              .fontWeight(.semibold)
              .foregroundColor(.primary)

            Text("Scientifically-backed techniques")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Spacer()

          // Timer
          Text("\(timeRemaining)")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.blue)
            .frame(width: 50)
        }
        .padding()

        if !isExerciseActive {
          // Technique selection
          VStack(spacing: 20) {
            Text("Choose a breathing technique:")
              .font(.headline)
              .foregroundColor(.primary)

            ForEach(BreathingTechnique.allCases, id: \.self) { technique in
              Button(action: {
                selectedTechnique = technique
              }) {
                HStack {
                  VStack(alignment: .leading, spacing: 4) {
                    Text(technique.rawValue)
                      .font(.headline)
                      .fontWeight(.semibold)
                      .foregroundColor(.primary)

                    Text(technique.description)
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }

                  Spacer()

                  if selectedTechnique == technique {
                    Image(systemName: "checkmark.circle.fill")
                      .foregroundColor(.blue)
                  }
                }
                .padding()
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(
                      selectedTechnique == technique
                        ? Color.blue.opacity(0.1) : Color(.systemBackground)
                    )
                    .overlay(
                      RoundedRectangle(cornerRadius: 12)
                        .stroke(
                          selectedTechnique == technique ? Color.blue : Color.gray.opacity(0.3),
                          lineWidth: 1)
                    )
                )
              }
              .buttonStyle(PlainButtonStyle())
            }

            // Voice guidance toggle
            HStack {
              Image(systemName: voiceGuidanceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .foregroundColor(voiceGuidanceEnabled ? .blue : .gray)

              Text("Voice guidance")
                .font(.subheadline)
                .foregroundColor(.primary)

              Spacer()

              Toggle("", isOn: $voiceGuidanceEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            )
            .padding(.horizontal, 20)

            Button(action: startExercise) {
              Text("Start Exercise")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(
                  RoundedRectangle(cornerRadius: 25)
                    .fill(Color.blue)
                )
            }
            .padding(.top, 20)
          }
          .padding(.horizontal, 20)
        } else {
          // Exercise area
          VStack(spacing: 40) {
            // Breathing visualization
            ZStack {
              if selectedTechnique == .boxBreathing {
                BoxBreathingVisual(progress: boxProgress, currentSide: currentBoxSide)
              } else {
                BreathingOrb(scale: orbScale, opacity: orbOpacity, technique: selectedTechnique)
              }
            }
            .frame(width: 200, height: 200)

            // Phase instruction
            VStack(spacing: 8) {
              Text(getPhaseInstruction())
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

              Text(getPhaseDescription())
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
          }
        }

        Spacer()
      }
    }
    .onDisappear {
      stopExercise()
      speechService.stop()
    }
  }

  // MARK: - Exercise Logic

  private func startExercise() {
    isExerciseActive = true
    timeRemaining = selectedTechnique.duration
    currentPhase = .inhale

    // Welcome message
    if voiceGuidanceEnabled {
      let welcomeMessage =
        "Starting \(selectedTechnique.rawValue). Follow the visual guide and breathe naturally."
      speechService.speak(welcomeMessage, rate: 0.4, pitch: 0.9)

      // Start phase progression after welcome message
      DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        self.startPhaseProgression()
      }
    } else {
      // Start immediately if voice guidance is disabled
      startPhaseProgression()
    }

    // Start exercise timer
    exerciseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      if timeRemaining > 0 {
        timeRemaining -= 1
      } else {
        stopExercise()
      }
    }
  }

  private func stopExercise() {
    isExerciseActive = false
    phaseTimer?.invalidate()
    exerciseTimer?.invalidate()
    phaseTimer = nil
    exerciseTimer = nil
    speechService.stop()
  }

  private func startPhaseProgression() {
    switch selectedTechnique {
    case .physiologicalSigh:
      startPhysiologicalSigh()
    case .boxBreathing:
      startBoxBreathing()
    case .coherenceBreathing:
      startCoherenceBreathing()
    }
  }

  // MARK: - Physiological Sigh

  private func startPhysiologicalSigh() {
    let cycleDuration: TimeInterval = 8.0  // 8 seconds per cycle

    phaseTimer = Timer.scheduledTimer(withTimeInterval: cycleDuration, repeats: true) { _ in
      performPhysiologicalSighCycle()
    }

    // Start first cycle immediately
    performPhysiologicalSighCycle()
  }

  private func performPhysiologicalSighCycle() {
    // First inhale (2 seconds)
    currentPhase = .inhale
    if voiceGuidanceEnabled {
      speechService.speak("Inhale", rate: 0.4, pitch: 0.9)
    }
    withAnimation(.easeInOut(duration: 2.0)) {
      orbScale = 1.3
      orbOpacity = 1.0
    }
    impactFeedback.impactOccurred()

    // Second inhale (1 second) - with longer pause before speaking
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      // Add a longer pause before the second instruction
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
        if voiceGuidanceEnabled {
          speechService.speak("Top off inhale", rate: 0.4, pitch: 0.9)
        }
      }
      withAnimation(.easeInOut(duration: 1.0)) {
        orbScale = 1.6
        orbOpacity = 1.0
      }
      impactFeedback.impactOccurred()

      // Long exhale (5 seconds) - with longer pause before speaking
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        currentPhase = .exhale
        // Add a longer pause before the exhale instruction
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
          if voiceGuidanceEnabled {
            speechService.speak("Long exhale", rate: 0.35, pitch: 0.85)
          }
        }
        withAnimation(.easeInOut(duration: 5.0)) {
          orbScale = 0.7
          orbOpacity = 0.6
        }
        impactFeedback.impactOccurred()
      }
    }
  }

  // MARK: - Box Breathing

  private func startBoxBreathing() {
    let phaseDuration: TimeInterval = 4.0  // 4 seconds per phase

    // Start with "Inhale" instruction
    if voiceGuidanceEnabled {
      speechService.speak("Inhale", rate: 0.4, pitch: 0.9)
    }

    phaseTimer = Timer.scheduledTimer(withTimeInterval: phaseDuration, repeats: true) { _ in
      progressBoxBreathing()
    }

    // Start first phase immediately
    progressBoxBreathing()
  }

  private func progressBoxBreathing() {
    switch currentPhase {
    case .inhale:
      currentPhase = .hold
      currentBoxSide = 1
      if voiceGuidanceEnabled {
        speechService.speak("Hold", rate: 0.4, pitch: 0.9)
      }
      withAnimation(.easeInOut(duration: 4.0)) {
        boxProgress = 0.25
      }
      impactFeedback.impactOccurred()

    case .hold:
      currentPhase = .exhale
      currentBoxSide = 2
      if voiceGuidanceEnabled {
        speechService.speak("Exhale", rate: 0.4, pitch: 0.9)
      }
      withAnimation(.easeInOut(duration: 4.0)) {
        boxProgress = 0.5
      }
      impactFeedback.impactOccurred()

    case .exhale:
      currentPhase = .hold2
      currentBoxSide = 3
      if voiceGuidanceEnabled {
        speechService.speak("Hold", rate: 0.4, pitch: 0.9)
      }
      withAnimation(.easeInOut(duration: 4.0)) {
        boxProgress = 0.75
      }
      impactFeedback.impactOccurred()

    case .hold2:
      currentPhase = .inhale
      currentBoxSide = 0
      if voiceGuidanceEnabled {
        speechService.speak("Inhale", rate: 0.4, pitch: 0.9)
      }
      withAnimation(.easeInOut(duration: 4.0)) {
        boxProgress = 1.0
      }
      impactFeedback.impactOccurred()
    }
  }

  // MARK: - Coherence Breathing

  private func startCoherenceBreathing() {
    let cycleDuration: TimeInterval = 10.0  // 5s inhale + 5s exhale

    phaseTimer = Timer.scheduledTimer(withTimeInterval: cycleDuration, repeats: true) { _ in
      performCoherenceCycle()
    }

    // Start first cycle immediately
    performCoherenceCycle()
  }

  private func performCoherenceCycle() {
    // Inhale (5 seconds)
    currentPhase = .inhale
    if voiceGuidanceEnabled {
      speechService.speak("Inhale", rate: 0.4, pitch: 1.0)
    }
    withAnimation(.easeInOut(duration: 5.0)) {
      orbScale = 1.4
      orbOpacity = 1.0
    }
    impactFeedback.impactOccurred()

    // Exhale (5 seconds)
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
      currentPhase = .exhale
      if voiceGuidanceEnabled {
        speechService.speak("Exhale", rate: 0.4, pitch: 0.9)
      }
      withAnimation(.easeInOut(duration: 5.0)) {
        orbScale = 0.8
        orbOpacity = 0.7
      }
      impactFeedback.impactOccurred()
    }
  }

  // MARK: - UI Helpers

  private func getPhaseInstruction() -> String {
    switch selectedTechnique {
    case .physiologicalSigh:
      switch currentPhase {
      case .inhale:
        return orbScale > 1.4 ? "Top off inhale..." : "Inhale..."
      case .exhale:
        return "Long exhale..."
      default:
        return "Inhale..."
      }

    case .boxBreathing:
      switch currentPhase {
      case .inhale: return "Inhale"
      case .hold: return "Hold"
      case .exhale: return "Exhale"
      case .hold2: return "Hold"
      }

    case .coherenceBreathing:
      switch currentPhase {
      case .inhale: return "Inhale"
      case .exhale: return "Exhale"
      default: return "Inhale"
      }
    }
  }

  private func getPhaseDescription() -> String {
    switch selectedTechnique {
    case .physiologicalSigh:
      return "Two short inhales, one long exhale"
    case .boxBreathing:
      return "4 seconds each phase"
    case .coherenceBreathing:
      return "5 seconds each phase"
    }
  }
}

// MARK: - Visual Components

struct BreathingOrb: View {
  let scale: CGFloat
  let opacity: Double
  let technique: BreathingTechnique

  var body: some View {
    ZStack {
      // Background pulse for coherence breathing
      if technique == .coherenceBreathing {
        Circle()
          .fill(Color.blue.opacity(0.1))
          .scaleEffect(scale * 1.2)
          .opacity(opacity * 0.5)
      }

      // Main orb
      Circle()
        .fill(
          LinearGradient(
            gradient: Gradient(colors: [
              Color.blue.opacity(0.8),
              Color.purple.opacity(0.6),
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .overlay(
          Circle()
            .stroke(Color.white.opacity(0.3), lineWidth: 2)
        )
    }
  }
}

struct BoxBreathingVisual: View {
  let progress: CGFloat
  let currentSide: Int

  var body: some View {
    ZStack {
      // Box outline
      RoundedRectangle(cornerRadius: 20)
        .stroke(Color.gray.opacity(0.3), lineWidth: 3)
        .frame(width: 150, height: 150)

      // Progress indicator
      RoundedRectangle(cornerRadius: 20)
        .trim(from: 0, to: progress)
        .stroke(Color.blue, lineWidth: 3)
        .frame(width: 150, height: 150)
        .rotationEffect(.degrees(-90))

      // Phase indicator
      Text(getPhaseText())
        .font(.title)
        .fontWeight(.bold)
        .foregroundColor(.blue)
    }
  }

  private func getPhaseText() -> String {
    switch currentSide {
    case 0: return "I"
    case 1: return "H"
    case 2: return "E"
    case 3: return "H"
    default: return "I"
    }
  }
}

#Preview {
  BreathingExerciseView()
}
