//
//  SleepRoutineView.swift
//  CalmMeNow
//
//  Sleep/wind-down routine (Premium)
//

import SwiftUI

struct SleepRoutineStep: Identifiable {
  let id = UUID()
  let title: String
  let description: String
  let emoji: String
  let duration: Int  // seconds
  let voicePrompts: [String]
}

enum SleepRoutinePhase: CaseIterable {
  case intro
  case breathing
  case bodyScan
  case gratitude
  case completion

  var title: String {
    switch self {
    case .intro: return "Preparing for Sleep"
    case .breathing: return "Gentle Breathing"
    case .bodyScan: return "Body Scan"
    case .gratitude: return "Gratitude Reflection"
    case .completion: return "Ready for Rest"
    }
  }

  var duration: Int {  // seconds
    switch self {
    case .intro: return 15
    case .breathing: return 120  // 2 minutes
    case .bodyScan: return 180  // 3 minutes
    case .gratitude: return 60  // 1 minute
    case .completion: return 10
    }
  }
}

struct SleepRoutineView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var speechService = SpeechService()
  @StateObject private var paywallManager = PaywallManager.shared
  @AppStorage("prefVoice") private var voiceGuidanceEnabled = true
  @AppStorage("prefHaptics") private var hapticsEnabled = true

  @State private var currentPhase: SleepRoutinePhase = .intro
  @State private var phaseTimeRemaining: Int = 15
  @State private var isRunning = false
  @State private var timer: Timer?
  @State private var breathingScale: CGFloat = 1.0
  @State private var showCompletion = false
  @State private var gratitudeItems: [String] = ["", "", ""]
  @State private var currentBodyPart = 0

  private let bodyParts = [
    "feet", "legs", "hips", "stomach", "chest",
    "hands", "arms", "shoulders", "neck", "face",
  ]

  var body: some View {
    ZStack {
      // Night theme gradient
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "#1a1a2e"),
          Color(hex: "#16213e"),
          Color(hex: "#0f3460"),
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      // Stars effect
      StarsView()

      VStack(spacing: 0) {
        // Header
        HStack {
          Button(action: {
            cleanup()
            presentationMode.wrappedValue.dismiss()
          }) {
            Image(systemName: "xmark.circle.fill")
              .font(.title2)
              .foregroundColor(.white.opacity(0.6))
          }

          Spacer()

          Text("Sleep Routine")
            .font(.headline)
            .foregroundColor(.white.opacity(0.8))

          Spacer()

          // Timer
          Text(formatTime(phaseTimeRemaining))
            .font(.headline)
            .foregroundColor(.white.opacity(0.6))
            .frame(width: 60)
        }
        .padding()

        if showCompletion {
          completionView
        } else {
          routineContent
        }
      }
    }
    .onAppear {
      checkPremiumAccess()
    }
    .onDisappear {
      cleanup()
    }
  }

  // MARK: - Routine Content

  private var routineContent: some View {
    VStack(spacing: 30) {
      // Overall progress
      VStack(spacing: 8) {
        ProgressView(value: overallProgress)
          .progressViewStyle(LinearProgressViewStyle(tint: .white.opacity(0.8)))
          .scaleEffect(y: 1.5)

        Text(currentPhase.title)
          .font(.caption)
          .foregroundColor(.white.opacity(0.6))
      }
      .padding(.horizontal, 40)

      Spacer()

      // Phase-specific content
      switch currentPhase {
      case .intro:
        introView
      case .breathing:
        breathingView
      case .bodyScan:
        bodyScanView
      case .gratitude:
        gratitudeView
      case .completion:
        EmptyView()
      }

      Spacer()

      // Skip button
      if currentPhase != .completion {
        Button(action: {
          skipToNextPhase()
        }) {
          Text("Skip to Next")
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.5))
        }
        .padding(.bottom, 30)
      }
    }
  }

  // MARK: - Intro View

  private var introView: some View {
    VStack(spacing: 24) {
      Text("🌙")
        .font(.system(size: 80))

      Text("Time to Wind Down")
        .font(.title)
        .fontWeight(.bold)
        .foregroundColor(.white)

      Text("Find a comfortable position and let go of the day.")
        .font(.body)
        .foregroundColor(.white.opacity(0.7))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)

      if !isRunning {
        Button(action: {
          startRoutine()
        }) {
          Text("Begin Routine")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(Color(hex: "#1a1a2e"))
            .padding(.vertical, 16)
            .padding(.horizontal, 48)
            .background(
              RoundedRectangle(cornerRadius: 30)
                .fill(Color.white.opacity(0.9))
            )
        }
        .padding(.top, 20)
      }
    }
  }

  // MARK: - Breathing View

  private var breathingView: some View {
    VStack(spacing: 30) {
      // Breathing circle
      ZStack {
        Circle()
          .fill(Color.white.opacity(0.1))
          .frame(width: 200, height: 200)
          .scaleEffect(breathingScale * 1.2)

        Circle()
          .fill(Color.white.opacity(0.2))
          .frame(width: 150, height: 150)
          .scaleEffect(breathingScale)

        Text(breathingScale > 1.1 ? "Inhale..." : "Exhale...")
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(.white)
      }

      Text("Slow, gentle breaths")
        .font(.body)
        .foregroundColor(.white.opacity(0.6))
    }
    .onAppear {
      startBreathingAnimation()
    }
  }

  // MARK: - Body Scan View

  private var bodyScanView: some View {
    VStack(spacing: 30) {
      // Body part indicator
      Text("🧘")
        .font(.system(size: 60))

      Text("Relax your \(bodyParts[currentBodyPart])")
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundColor(.white)

      Text("Notice any tension and let it dissolve")
        .font(.body)
        .foregroundColor(.white.opacity(0.7))

      // Progress through body parts
      HStack(spacing: 4) {
        ForEach(0..<bodyParts.count, id: \.self) { index in
          Circle()
            .fill(index <= currentBodyPart ? Color.white : Color.white.opacity(0.3))
            .frame(width: 8, height: 8)
        }
      }
    }
  }

  // MARK: - Gratitude View

  private var gratitudeView: some View {
    VStack(spacing: 24) {
      Text("✨")
        .font(.system(size: 50))

      Text("Three things you're grateful for today")
        .font(.title3)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .multilineTextAlignment(.center)

      VStack(spacing: 12) {
        ForEach(0..<3, id: \.self) { index in
          HStack {
            Text("\(index + 1).")
              .foregroundColor(.white.opacity(0.5))

            TextField("", text: $gratitudeItems[index])
              .foregroundColor(.white)
              .placeholder(when: gratitudeItems[index].isEmpty) {
                Text("Something you appreciate...")
                  .foregroundColor(.white.opacity(0.3))
              }
          }
          .padding()
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(Color.white.opacity(0.1))
          )
        }
      }
      .padding(.horizontal, 30)
    }
  }

  // MARK: - Completion View

  private var completionView: some View {
    VStack(spacing: 40) {
      Spacer()

      // Moon and stars
      ZStack {
        Circle()
          .fill(Color.white.opacity(0.1))
          .frame(width: 150, height: 150)

        Text("😴")
          .font(.system(size: 70))
      }

      VStack(spacing: 16) {
        Text("Sweet Dreams")
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundColor(.white)

        Text("Your mind and body are ready for rest.")
          .font(.body)
          .foregroundColor(.white.opacity(0.7))

        Text("Sleep well.")
          .font(.title3)
          .foregroundColor(.white.opacity(0.5))
      }

      Spacer()

      Button(action: {
        presentationMode.wrappedValue.dismiss()
      }) {
        Text("Close")
          .font(.headline)
          .foregroundColor(Color(hex: "#1a1a2e"))
          .padding(.vertical, 16)
          .padding(.horizontal, 48)
          .background(
            RoundedRectangle(cornerRadius: 30)
              .fill(Color.white.opacity(0.9))
          )
      }
      .padding(.bottom, 60)
    }
  }

  // MARK: - Helper Properties

  private var overallProgress: Double {
    let phases = SleepRoutinePhase.allCases
    guard let currentIndex = phases.firstIndex(of: currentPhase) else { return 0 }

    let completedDuration = phases.prefix(currentIndex).reduce(0) { $0 + $1.duration }
    let currentProgress = currentPhase.duration - phaseTimeRemaining
    let totalDuration = phases.reduce(0) { $0 + $1.duration }

    return Double(completedDuration + currentProgress) / Double(totalDuration)
  }

  // MARK: - Helper Methods

  private func formatTime(_ seconds: Int) -> String {
    let mins = seconds / 60
    let secs = seconds % 60
    return String(format: "%d:%02d", mins, secs)
  }

  private func checkPremiumAccess() {
    Task {
      let hasAccess = await paywallManager.requestAIAccess()
      if !hasAccess {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          if !paywallManager.shouldShowPaywall {
            presentationMode.wrappedValue.dismiss()
          }
        }
      }
    }
  }

  private func startRoutine() {
    isRunning = true
    phaseTimeRemaining = currentPhase.duration

    if voiceGuidanceEnabled {
      speechService.speak(
        "Let's begin your sleep routine. Find a comfortable position and close your eyes.",
        rate: 0.4, pitch: 0.9)
    }

    if hapticsEnabled {
      HapticManager.shared.softImpact()
    }

    startPhaseTimer()
  }

  private func startPhaseTimer() {
    timer?.invalidate()

    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      if phaseTimeRemaining > 1 {
        phaseTimeRemaining -= 1

        // Body scan progression
        if currentPhase == .bodyScan {
          let partDuration = SleepRoutinePhase.bodyScan.duration / bodyParts.count
          let elapsed = SleepRoutinePhase.bodyScan.duration - phaseTimeRemaining
          let newPart = min(elapsed / partDuration, bodyParts.count - 1)

          if newPart != currentBodyPart {
            currentBodyPart = newPart
            if voiceGuidanceEnabled {
              speechService.speak("Now, relax your \(bodyParts[currentBodyPart])", rate: 0.4, pitch: 0.9)
            }
          }
        }
      } else {
        advanceToNextPhase()
      }
    }
  }

  private func advanceToNextPhase() {
    let phases = SleepRoutinePhase.allCases
    guard let currentIndex = phases.firstIndex(of: currentPhase),
      currentIndex < phases.count - 1
    else {
      // Complete routine
      showCompletion = true
      timer?.invalidate()

      if voiceGuidanceEnabled {
        speechService.speak("Your sleep routine is complete. Sweet dreams.", rate: 0.4, pitch: 0.9)
      }

      if hapticsEnabled {
        HapticManager.shared.success()
      }
      return
    }

    currentPhase = phases[currentIndex + 1]
    phaseTimeRemaining = currentPhase.duration
    currentBodyPart = 0

    if hapticsEnabled {
      HapticManager.shared.softImpact()
    }

    // Voice prompts for each phase
    if voiceGuidanceEnabled {
      speakPhaseIntro()
    }
  }

  private func skipToNextPhase() {
    timer?.invalidate()
    advanceToNextPhase()
    if currentPhase != .completion {
      startPhaseTimer()
    }
  }

  private func speakPhaseIntro() {
    switch currentPhase {
    case .breathing:
      speechService.speak(
        "Now, let's slow your breathing. Breathe in slowly, and breathe out slowly.", rate: 0.4,
        pitch: 0.9)
    case .bodyScan:
      speechService.speak(
        "Time for a gentle body scan. We'll relax each part of your body, starting with your feet.",
        rate: 0.4, pitch: 0.9)
    case .gratitude:
      speechService.speak(
        "Think of three things you're grateful for today. Let these positive thoughts settle your mind.",
        rate: 0.4, pitch: 0.9)
    default:
      break
    }
  }

  private func startBreathingAnimation() {
    withAnimation(
      Animation.easeInOut(duration: 4)
        .repeatForever(autoreverses: true)
    ) {
      breathingScale = 1.3
    }
  }

  private func cleanup() {
    timer?.invalidate()
    timer = nil
    speechService.stopAll()
    isRunning = false
  }
}

// MARK: - Stars Background View

struct StarsView: View {
  var body: some View {
    GeometryReader { geometry in
      ForEach(0..<30, id: \.self) { _ in
        Circle()
          .fill(Color.white.opacity(Double.random(in: 0.3...0.7)))
          .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
          .position(
            x: CGFloat.random(in: 0...geometry.size.width),
            y: CGFloat.random(in: 0...geometry.size.height)
          )
      }
    }
  }
}

// MARK: - Placeholder Extension

extension View {
  func placeholder<Content: View>(
    when shouldShow: Bool,
    alignment: Alignment = .leading,
    @ViewBuilder placeholder: () -> Content
  ) -> some View {
    ZStack(alignment: alignment) {
      placeholder().opacity(shouldShow ? 1 : 0)
      self
    }
  }
}

#Preview {
  SleepRoutineView()
}
