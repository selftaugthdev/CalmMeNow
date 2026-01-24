//
//  PMRExerciseView.swift
//  CalmMeNow
//
//  Progressive Muscle Relaxation Exercise
//

import SwiftUI

struct MuscleGroup: Identifiable {
  let id = UUID()
  let name: String
  let emoji: String
  let tenseInstruction: String
  let relaxInstruction: String
}

enum PMRPhase {
  case tense
  case relax
}

struct PMRExerciseView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var speechService = SpeechService()
  @AppStorage("prefVoice") private var voiceGuidanceEnabled = false
  @AppStorage("prefHaptics") private var hapticsEnabled = true

  @State private var currentGroupIndex = 0
  @State private var currentPhase: PMRPhase = .tense
  @State private var phaseTimeRemaining: Int = 5
  @State private var isRunning = false
  @State private var showCompletion = false
  @State private var timer: Timer?
  @State private var pulseAnimation = false

  private let tenseDuration = 5  // seconds
  private let relaxDuration = 10  // seconds

  private let muscleGroups: [MuscleGroup] = [
    MuscleGroup(
      name: "Hands & Forearms",
      emoji: "✊",
      tenseInstruction: "Make tight fists and tense your forearms",
      relaxInstruction: "Release and let your hands go limp"
    ),
    MuscleGroup(
      name: "Upper Arms",
      emoji: "💪",
      tenseInstruction: "Bend your elbows and flex your biceps",
      relaxInstruction: "Let your arms fall heavy and relaxed"
    ),
    MuscleGroup(
      name: "Forehead",
      emoji: "😤",
      tenseInstruction: "Raise your eyebrows as high as you can",
      relaxInstruction: "Let your forehead smooth out completely"
    ),
    MuscleGroup(
      name: "Eyes & Cheeks",
      emoji: "😑",
      tenseInstruction: "Squeeze your eyes shut tightly",
      relaxInstruction: "Let your eyes relax and soften"
    ),
    MuscleGroup(
      name: "Mouth & Jaw",
      emoji: "😬",
      tenseInstruction: "Clench your jaw and press your lips together",
      relaxInstruction: "Let your jaw drop slightly open"
    ),
    MuscleGroup(
      name: "Neck",
      emoji: "🦒",
      tenseInstruction: "Gently press your head back",
      relaxInstruction: "Let your neck relax and feel heavy"
    ),
    MuscleGroup(
      name: "Shoulders",
      emoji: "🤷",
      tenseInstruction: "Raise your shoulders up toward your ears",
      relaxInstruction: "Drop your shoulders down and relax"
    ),
    MuscleGroup(
      name: "Chest",
      emoji: "🫁",
      tenseInstruction: "Take a deep breath and hold it",
      relaxInstruction: "Exhale slowly and let your chest relax"
    ),
    MuscleGroup(
      name: "Stomach",
      emoji: "🧘",
      tenseInstruction: "Tighten your stomach muscles",
      relaxInstruction: "Release and let your belly soften"
    ),
    MuscleGroup(
      name: "Legs & Feet",
      emoji: "🦶",
      tenseInstruction: "Point your toes and tense your legs",
      relaxInstruction: "Let your legs go completely limp"
    ),
  ]

  // Total duration: 10 groups * (5s tense + 10s relax) = 150 seconds = 2.5 min
  private var totalDuration: Int {
    muscleGroups.count * (tenseDuration + relaxDuration)
  }

  private var overallProgress: Double {
    let completedGroups = Double(currentGroupIndex)
    let currentGroupProgress =
      currentPhase == .tense
      ? Double(tenseDuration - phaseTimeRemaining) / Double(tenseDuration + relaxDuration)
      : (Double(tenseDuration) + Double(relaxDuration - phaseTimeRemaining))
        / Double(tenseDuration + relaxDuration)

    return (completedGroups + currentGroupProgress) / Double(muscleGroups.count)
  }

  var body: some View {
    ZStack {
      // Background gradient that changes based on phase
      LinearGradient(
        gradient: Gradient(colors: phaseColors),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()
      .animation(.easeInOut(duration: 0.5), value: currentPhase)

      VStack(spacing: 0) {
        // Header
        HStack {
          Button(action: {
            cleanup()
            presentationMode.wrappedValue.dismiss()
          }) {
            Image(systemName: "xmark.circle.fill")
              .font(.title2)
              .foregroundColor(.white.opacity(0.8))
          }

          Spacer()

          Text("Muscle Relaxation")
            .font(.headline)
            .foregroundColor(.white)

          Spacer()

          // Skip button
          Button(action: {
            skipToNext()
          }) {
            Text("Skip")
              .font(.subheadline)
              .foregroundColor(.white.opacity(0.8))
          }
        }
        .padding()

        if showCompletion {
          completionView
        } else {
          exerciseContent
        }
      }
    }
    .onAppear {
      startExercise()
    }
    .onDisappear {
      cleanup()
    }
  }

  // MARK: - Phase Colors

  private var phaseColors: [Color] {
    switch currentPhase {
    case .tense:
      return [
        Color.orange.opacity(0.9),
        Color.red.opacity(0.7),
        Color.orange.opacity(0.6),
      ]
    case .relax:
      return [
        Color.blue.opacity(0.7),
        Color.cyan.opacity(0.6),
        Color.blue.opacity(0.5),
      ]
    }
  }

  // MARK: - Exercise Content

  private var exerciseContent: some View {
    VStack(spacing: 24) {
      // Overall progress bar
      VStack(spacing: 8) {
        ProgressView(value: overallProgress)
          .progressViewStyle(LinearProgressViewStyle(tint: .white))
          .scaleEffect(y: 2)

        Text("\(currentGroupIndex + 1) of \(muscleGroups.count)")
          .font(.caption)
          .foregroundColor(.white.opacity(0.8))
      }
      .padding(.horizontal, 30)
      .padding(.top, 10)

      Spacer()

      // Current muscle group display
      VStack(spacing: 20) {
        // Emoji with pulse animation
        Text(muscleGroups[currentGroupIndex].emoji)
          .font(.system(size: 80))
          .scaleEffect(pulseAnimation ? 1.15 : 1.0)
          .animation(
            Animation.easeInOut(duration: currentPhase == .tense ? 0.5 : 1.0)
              .repeatForever(autoreverses: true),
            value: pulseAnimation
          )

        // Muscle group name
        Text(muscleGroups[currentGroupIndex].name)
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundColor(.white)

        // Phase indicator
        HStack(spacing: 16) {
          PhaseIndicator(
            label: "TENSE",
            isActive: currentPhase == .tense,
            color: .orange
          )

          PhaseIndicator(
            label: "RELAX",
            isActive: currentPhase == .relax,
            color: .blue
          )
        }

        // Timer countdown
        ZStack {
          Circle()
            .stroke(Color.white.opacity(0.3), lineWidth: 8)
            .frame(width: 100, height: 100)

          Circle()
            .trim(
              from: 0,
              to: CGFloat(phaseTimeRemaining)
                / CGFloat(currentPhase == .tense ? tenseDuration : relaxDuration)
            )
            .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
            .frame(width: 100, height: 100)
            .rotationEffect(.degrees(-90))
            .animation(.linear(duration: 1), value: phaseTimeRemaining)

          Text("\(phaseTimeRemaining)")
            .font(.system(size: 36, weight: .bold))
            .foregroundColor(.white)
        }

        // Instruction
        Text(
          currentPhase == .tense
            ? muscleGroups[currentGroupIndex].tenseInstruction
            : muscleGroups[currentGroupIndex].relaxInstruction
        )
        .font(.title3)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
        .padding(.vertical, 16)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.2))
        )
      }
      .padding(.horizontal, 20)

      Spacer()

      // Phase label at bottom
      Text(currentPhase == .tense ? "TENSE the muscle..." : "RELAX and release...")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.white)
        .padding(.bottom, 40)
    }
  }

  // MARK: - Completion View

  private var completionView: some View {
    VStack(spacing: 40) {
      Spacer()

      // Success animation
      ZStack {
        Circle()
          .fill(Color.white.opacity(0.2))
          .frame(width: 180, height: 180)
          .scaleEffect(pulseAnimation ? 1.2 : 1.0)
          .animation(
            Animation.easeInOut(duration: 2)
              .repeatForever(autoreverses: true),
            value: pulseAnimation
          )

        Image(systemName: "sparkles")
          .font(.system(size: 80))
          .foregroundColor(.white)
      }

      VStack(spacing: 16) {
        Text("Deeply Relaxed")
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundColor(.white)

        Text("You've released tension from your entire body.")
          .font(.title3)
          .foregroundColor(.white.opacity(0.9))
          .multilineTextAlignment(.center)

        Text("Notice how calm and heavy your body feels now.")
          .font(.body)
          .foregroundColor(.white.opacity(0.7))
          .multilineTextAlignment(.center)
      }
      .padding(.horizontal, 40)

      Spacer()

      // Return button
      Button(action: {
        presentationMode.wrappedValue.dismiss()
      }) {
        Text("Return to Home")
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(.blue)
          .padding(.vertical, 16)
          .padding(.horizontal, 48)
          .background(
            RoundedRectangle(cornerRadius: 30)
              .fill(Color.white)
          )
          .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
      }
      .padding(.bottom, 60)
    }
  }

  // MARK: - Helper Methods

  private func startExercise() {
    isRunning = true
    pulseAnimation = true

    // Track PMR exercise access
    FirebaseAnalyticsService.shared.trackEmotionSelected(emotion: "pmr_exercise")

    // Speak introduction if voice is enabled
    if voiceGuidanceEnabled {
      let intro =
        "Progressive muscle relaxation. We'll tense and relax each muscle group. Let's begin."
      speechService.speak(intro, rate: 0.45, pitch: 1.0)

      // Start timer after intro
      DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
        startPhaseTimer()
        speakCurrentPhase()
      }
    } else {
      startPhaseTimer()
    }

    if hapticsEnabled {
      HapticManager.shared.mediumImpact()
    }
  }

  private func startPhaseTimer() {
    timer?.invalidate()
    phaseTimeRemaining = currentPhase == .tense ? tenseDuration : relaxDuration

    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      if phaseTimeRemaining > 1 {
        phaseTimeRemaining -= 1
      } else {
        advancePhase()
      }
    }
  }

  private func advancePhase() {
    if currentPhase == .tense {
      // Move to relax phase
      currentPhase = .relax
      phaseTimeRemaining = relaxDuration

      if hapticsEnabled {
        HapticManager.shared.softImpact()
      }

      if voiceGuidanceEnabled {
        speakCurrentPhase()
      }
    } else {
      // Move to next muscle group
      if currentGroupIndex < muscleGroups.count - 1 {
        currentGroupIndex += 1
        currentPhase = .tense
        phaseTimeRemaining = tenseDuration

        if hapticsEnabled {
          HapticManager.shared.lightImpact()
        }

        if voiceGuidanceEnabled {
          speakCurrentPhase()
        }
      } else {
        // Exercise complete
        completeExercise()
      }
    }
  }

  private func skipToNext() {
    timer?.invalidate()

    if currentPhase == .tense {
      currentPhase = .relax
      phaseTimeRemaining = relaxDuration
    } else {
      if currentGroupIndex < muscleGroups.count - 1 {
        currentGroupIndex += 1
        currentPhase = .tense
        phaseTimeRemaining = tenseDuration
      } else {
        completeExercise()
        return
      }
    }

    if hapticsEnabled {
      HapticManager.shared.lightImpact()
    }

    startPhaseTimer()
  }

  private func completeExercise() {
    timer?.invalidate()

    withAnimation(.easeInOut(duration: 0.5)) {
      showCompletion = true
    }

    if hapticsEnabled {
      HapticManager.shared.success()
    }

    if voiceGuidanceEnabled {
      speechService.speak(
        "Wonderful. You've completed the full body relaxation. Notice how calm and relaxed you feel.",
        rate: 0.45, pitch: 1.0)
    }
  }

  private func speakCurrentPhase() {
    let muscleGroup = muscleGroups[currentGroupIndex]
    let instruction =
      currentPhase == .tense
      ? "\(muscleGroup.name). \(muscleGroup.tenseInstruction)"
      : "Now relax. \(muscleGroup.relaxInstruction)"

    speechService.speak(instruction, rate: 0.45, pitch: 1.0)
  }

  private func cleanup() {
    timer?.invalidate()
    timer = nil
    speechService.stopAll()
    isRunning = false
    pulseAnimation = false
  }
}

// MARK: - Phase Indicator Component

struct PhaseIndicator: View {
  let label: String
  let isActive: Bool
  let color: Color

  var body: some View {
    Text(label)
      .font(.caption)
      .fontWeight(.bold)
      .foregroundColor(isActive ? .white : .white.opacity(0.5))
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(isActive ? color : Color.white.opacity(0.2))
      )
  }
}

#Preview {
  PMRExerciseView()
}
