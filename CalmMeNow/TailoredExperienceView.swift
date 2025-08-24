import SwiftUI

struct TailoredExperienceView: View {
  let emotion: String
  let intensity: IntensityLevel
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var audioManager = AudioManager.shared
  @StateObject private var progressTracker = ProgressTracker.shared
  @State private var isAnimating = false
  @State private var showCompletionOptions = false
  @State private var showSuccessView = false
  @State private var showAdditionalHelp = false
  @State private var timeRemaining: Int = 60
  @State private var currentPhase: ExperiencePhase = .intro
  @State private var breathingCycle: Int = 0
  @State private var guidanceIndex: Int = 0
  @State private var showControls: Bool = false
  @State private var phaseTimer: Timer?
  @State private var hasStartedExperience = false

  private var program: ReliefProgram? {
    // Ensure we have valid data
    guard !emotion.isEmpty else { return nil }
    guard let emotionEnum = Emotion(rawValue: emotion.lowercased()) else { return nil }
    return ReliefProgram.program(for: emotionEnum, intensity: intensity)
  }

  enum ExperiencePhase {
    case intro
    case breathing
    case guidance
    case stabilize
    case complete
  }

  var body: some View {
    ZStack {
      // Background based on program theme
      backgroundGradient
        .ignoresSafeArea()

      VStack {
        // Header with exit option (only show after delay for severe)
        if showControls {
          HStack {
            Button("Exit") {
              audioManager.stopSound()
              presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.black)
            .padding()

            Spacer()

            if timeRemaining > 0 {
              Text("\(timeRemaining)s")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding()
            }
          }
        }

        Spacer()

        // Main content based on program
        if let program = program {
          programContent(program)
        } else {
          fallbackContent
        }

        Spacer()

        // Bottom controls
        if showCompletionOptions {
          completionOptions
        }
      }
    }
    .onAppear {
      // Delay the start to ensure the view is fully loaded
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        if !hasStartedExperience && !emotion.isEmpty {
          hasStartedExperience = true
          startExperience()
        }
      }
    }
    .onChange(of: emotion) { newEmotion in
      // If emotion becomes available after onAppear, start the experience
      if !hasStartedExperience && !newEmotion.isEmpty {
        hasStartedExperience = true
        startExperience()
      }
    }
    .onDisappear {
      audioManager.stopSound()
      phaseTimer?.invalidate()
      hasStartedExperience = false
    }
    .sheet(isPresented: $showSuccessView) {
      SuccessView(
        onReturnToHome: {
          presentationMode.wrappedValue.dismiss()
        },
        emotionContext: emotion,
        intensityContext: intensity == .mild ? "a little" : "full"
      )
    }
    .sheet(isPresented: $showAdditionalHelp) {
      AdditionalHelpView()
    }
  }

  // MARK: - Background Gradients

  private var backgroundGradient: LinearGradient {
    guard let program = program else {
      return LinearGradient(
        gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }

    // Emotion-specific gradients
    switch program.emotion {
    case .anxious:
      return LinearGradient(
        gradient: Gradient(colors: [
          Color(red: 0.85, green: 0.85, blue: 0.95),  // Soft blue
          Color(red: 0.80, green: 0.90, blue: 0.95),  // Light cyan
          Color(red: 0.85, green: 0.95, blue: 0.85),  // Mint
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .angry:
      return LinearGradient(
        gradient: Gradient(colors: [
          Color(red: 0.95, green: 0.85, blue: 0.85),  // Soft pink
          Color(red: 0.90, green: 0.80, blue: 0.90),  // Lavender
          Color(red: 0.85, green: 0.85, blue: 0.95),  // Soft blue
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .sad:
      return LinearGradient(
        gradient: Gradient(colors: [
          Color(red: 0.95, green: 0.90, blue: 0.98),  // Soft purple
          Color(red: 0.98, green: 0.85, blue: 0.90),  // Rose
          Color(red: 0.98, green: 0.95, blue: 0.90),  // Cream
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .frustrated:
      return LinearGradient(
        gradient: Gradient(colors: [
          Color(red: 0.85, green: 0.95, blue: 0.85),  // Mint
          Color(red: 0.70, green: 0.90, blue: 0.90),  // Teal
          Color(red: 0.85, green: 0.85, blue: 0.95),  // Soft blue
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }
  }

  // MARK: - Program Content

  private func programContent(_ program: ReliefProgram) -> some View {
    VStack(spacing: 40) {
      // Header text
      VStack(spacing: 16) {
        Text(program.headerText)
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundColor(.black)
          .multilineTextAlignment(.center)

        Text(program.subtext)
          .font(.title3)
          .foregroundColor(.black.opacity(0.8))
          .multilineTextAlignment(.center)
      }
      .padding(.horizontal, 40)
      .padding(.vertical, 20)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color.white.opacity(0.8))
      )

      // Main content based on phase
      switch currentPhase {
      case .intro:
        introPhase(program)
      case .breathing:
        breathingPhase(program)
      case .guidance:
        guidancePhase(program)
      case .stabilize:
        stabilizePhase(program)
      case .complete:
        completePhase(program)
      }
    }
  }

  // MARK: - Phase Views

  private func introPhase(_ program: ReliefProgram) -> some View {
    VStack(spacing: 30) {
      // Cat mascot for intro
      CatMascot()
        .frame(width: 180, height: 220)
        .padding(.vertical, 20)

      Text("You're safe. I'm with you.")
        .font(.title2)
        .fontWeight(.medium)
        .foregroundColor(.black)
        .multilineTextAlignment(.center)
    }
  }

  private func breathingPhase(_ program: ReliefProgram) -> some View {
    VStack(spacing: 30) {
      // Breathing sloth mascot
      ZStack {
        // Cat mascot with breathing speed
        CatMascot()
          .frame(width: 250, height: 250)
          .padding(.vertical, 30)

        // Breathing text overlay
        VStack {
          Spacer()
          Text(getCurrentBreathingInstruction(program))
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.black)
            .opacity(isAnimating ? 1.0 : 0.7)
            .animation(
              Animation.easeInOut(duration: getBreathingDuration(program.breathing) / 2)
                .repeatForever(autoreverses: true),
              value: isAnimating
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.8))
            )
        }
      }
    }
  }

  private func guidancePhase(_ program: ReliefProgram) -> some View {
    VStack(spacing: 30) {
      // Guidance sloth mascot
      VStack(spacing: 20) {
        CatMascot()
          .frame(width: 180, height: 220)
          .padding(.vertical, 20)

        Text(getCurrentGuidanceInstruction(program))
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(.black)
          .multilineTextAlignment(.center)
          .padding(20)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(Color.white.opacity(0.8))
          )
      }

      // Progress indicator
      HStack(spacing: 8) {
        ForEach(0..<program.getGuidanceInstructions().count, id: \.self) { index in
          Circle()
            .fill(index <= guidanceIndex ? Color.white : Color.white.opacity(0.3))
            .frame(width: 12, height: 12)
        }
      }
    }
  }

  private func stabilizePhase(_ program: ReliefProgram) -> some View {
    VStack(spacing: 30) {
      // Stabilizing cat mascot
      CatMascot()
        .frame(width: 180, height: 220)
        .padding(.vertical, 20)

      Text("Let your body settle...")
        .font(.title2)
        .fontWeight(.medium)
        .foregroundColor(.black)
        .multilineTextAlignment(.center)
    }
  }

  private func completePhase(_ program: ReliefProgram) -> some View {
    VStack(spacing: 30) {
      // Completion cat mascot
      CatMascot()
        .frame(width: 180, height: 220)
        .padding(.vertical, 20)
        .overlay(
          Text("✓")
            .font(.system(size: 60))
            .foregroundColor(.green)
            .background(
              Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 80, height: 80)
            )
        )

      Text("You've done it.")
        .font(.title2)
        .fontWeight(.medium)
        .foregroundColor(.black)
        .multilineTextAlignment(.center)
    }
  }

  // MARK: - Fallback Content

  private var fallbackContent: some View {
    VStack(spacing: 40) {
      Text("Finding your calm...")
        .font(.title2)
        .fontWeight(.medium)
        .foregroundColor(.black)
        .multilineTextAlignment(.center)
    }
  }

  // MARK: - Completion Options

  private var completionOptions: some View {
    VStack(spacing: 16) {
      Text("How are you feeling now?")
        .font(.title3)
        .fontWeight(.medium)
        .foregroundColor(.black)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.8))
        )

      HStack(spacing: 20) {
        Button("I feel better") {
          progressTracker.recordUsage()
          progressTracker.recordReliefOutcome(.betterNow)
          showSuccessView = true
        }
        .foregroundColor(.white)
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(Color.green.opacity(0.8))
        )

        Button("I still need help") {
          progressTracker.recordReliefOutcome(.stillNeedHelp)
          showAdditionalHelp = true
        }
        .foregroundColor(.white)
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(Color.blue.opacity(0.8))
        )
      }
    }
    .padding(.bottom, 40)
  }

  // MARK: - Helper Functions

  private func startExperience() {
    print("🎯 DEBUG: startExperience() called")
    print("   - emotion: '\(emotion)'")
    print("   - intensity: \(intensity)")
    print("   - program available: \(program != nil)")

    // Try to get program immediately
    if let program = program {
      print("   ✅ Starting program immediately")
      startProgram(program)
    } else {
      print("   ⏳ Program not ready, retrying...")
      // Retry with increasing delays
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        print("   🔄 Retry 1 - program available: \(self.program != nil)")
        if let program = self.program {
          print("   ✅ Starting program on retry 1")
          self.startProgram(program)
        } else {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("   🔄 Retry 2 - program available: \(self.program != nil)")
            if let program = self.program {
              print("   ✅ Starting program on retry 2")
              self.startProgram(program)
            } else {
              print("   ❌ Failed to start program after all retries")
            }
          }
        }
      }
    }
  }

  private func startProgram(_ program: ReliefProgram) {
    isAnimating = true
    progressTracker.recordUsage()

    // Start audio with looping for severe intensity
    let shouldLoop = program.intensity == .severe
    audioManager.playSound(program.audio, loop: shouldLoop)

    // Set initial duration
    timeRemaining = Int(program.duration)

    // Show controls after delay for severe
    if program.showControlsAfter > 0 {
      DispatchQueue.main.asyncAfter(deadline: .now() + program.showControlsAfter) {
        showControls = true
      }
    } else {
      showControls = true
    }

    // Start phase progression
    startPhaseProgression(program)
  }

  private func startPhaseProgression(_ program: ReliefProgram) {
    if program.intensity == .mild {
      // Simple 60-second experience for mild
      phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
        if timeRemaining > 0 {
          timeRemaining -= 1
        } else {
          timer.invalidate()
          showCompletionOptions = true
          audioManager.stopSound()
        }
      }
    } else {
      // Complex phase progression for severe
      let introDuration: TimeInterval = 5
      let breathingDuration: TimeInterval = 50
      let guidanceDuration: TimeInterval = 35
      let stabilizeDuration: TimeInterval = 30

      // Intro phase
      DispatchQueue.main.asyncAfter(deadline: .now() + introDuration) {
        currentPhase = .breathing
      }

      // Breathing phase
      DispatchQueue.main.asyncAfter(deadline: .now() + introDuration + breathingDuration) {
        currentPhase = .guidance
        startGuidanceProgression(program)
      }

      // Guidance phase
      DispatchQueue.main.asyncAfter(
        deadline: .now() + introDuration + breathingDuration + guidanceDuration
      ) {
        currentPhase = .stabilize
      }

      // Stabilize phase
      DispatchQueue.main.asyncAfter(
        deadline: .now() + introDuration + breathingDuration + guidanceDuration + stabilizeDuration
      ) {
        currentPhase = .complete
        showCompletionOptions = true
        audioManager.stopSound()
      }

      // Countdown timer
      phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
        if timeRemaining > 0 {
          timeRemaining -= 1
        } else {
          timer.invalidate()
        }
      }
    }
  }

  private func startGuidanceProgression(_ program: ReliefProgram) {
    let guidanceInstructions = program.getGuidanceInstructions()
    let interval = 6.0  // 6 seconds per instruction

    for (index, _) in guidanceInstructions.enumerated() {
      DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(index)) {
        guidanceIndex = index
      }
    }
  }

  private func getBreathingDuration(_ pattern: BreathingPattern) -> Double {
    switch pattern {
    case .fiveFive:
      return 10.0  // 5s inhale + 5s exhale
    case .fourSix:
      return 10.0  // 4s inhale + 6s exhale
    case .box:
      return 16.0  // 4s inhale + 4s hold + 4s exhale + 4s hold
    case .physiologicalSigh:
      return 8.0  // 2s inhale + 2s inhale + 4s exhale
    case .none:
      return 10.0
    }
  }

  private func getCurrentBreathingInstruction(_ program: ReliefProgram) -> String {
    let instructions = program.getBreathingInstructions()
    let cycleDuration = getBreathingDuration(program.breathing)
    let currentTime = program.duration - TimeInterval(timeRemaining)
    let cycleTime = currentTime.truncatingRemainder(dividingBy: cycleDuration)
    let instructionIndex = Int(cycleTime / (cycleDuration / Double(instructions.count)))

    return instructions[min(instructionIndex, instructions.count - 1)]
  }

  private func getCurrentGuidanceInstruction(_ program: ReliefProgram) -> String {
    let instructions = program.getGuidanceInstructions()
    return instructions[min(guidanceIndex, instructions.count - 1)]
  }

  private func getBreathingSpeed(_ pattern: BreathingPattern) -> CGFloat {
    switch pattern {
    case .fiveFive:
      return 0.6  // Slower for 5-5 breathing
    case .fourSix:
      return 0.7  // Medium for 4-6 breathing
    case .box:
      return 0.5  // Slowest for box breathing
    case .physiologicalSigh:
      return 0.8  // Faster for physiological sigh
    case .none:
      return 0.6  // Default speed
    }
  }
}
