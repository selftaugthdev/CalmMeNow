import SwiftUI

struct PanicFlowView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var audioManager = AudioManager.shared
  @StateObject private var progressTracker = ProgressTracker.shared
  @AppStorage("prefSounds") private var prefSounds = true

  // MARK: - Timing state

  @State private var elapsed: Int = 0
  @State private var sessionId: String = ""
  private let sessionStart = Date()

  // MARK: - Bear breathing animation

  @State private var bearScale: CGFloat = 0.92
  @State private var bearBrightness: Double = -0.05
  @State private var bearGlow: CGFloat = 12
  @State private var breatheIn: Bool = true

  // MARK: - Reassurance messages

  @State private var messageIndex: Int = 0
  @State private var messageOpacity: Double = 0

  private let messages = [
    "This will pass.",
    "Your body is reacting, not failing.",
    "You're not in danger.",
    "You've handled this before.",
    "You are safe right now.",
  ]

  // MARK: - Downstream sheets

  @State private var showingBreathwork = false
  @State private var showingGrounding = false
  @State private var showingPMR = false
  @State private var showingGames = false
  @State private var showTriggerLog = false
  @State private var showPostRecovery = false
  @State private var showAdditionalHelp = false
  @State private var sessionDuration: Int = 0

  // MARK: - Phase helpers

  private var phase: Int {
    if elapsed < 10 { return 1 }
    if elapsed < 35 { return 2 }
    return 3
  }

  // MARK: - Body

  var body: some View {
    ZStack {
      // Background
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "#0A1628"),
          Color(hex: "#112244"),
          Color(hex: "#1A3560"),
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack(spacing: 0) {

        // Exit button — unobtrusive, top left
        HStack {
          Button(action: endSession(outcome: "early_exit")) {
            Text("Exit")
              .font(.subheadline)
              .foregroundColor(.white.opacity(0.4))
              .padding(.horizontal, 16)
              .padding(.vertical, 10)
          }
          Spacer()
        }
        .padding(.top, 8)

        Spacer()

        // Bear mascot — breathes via scale + brightness
        ZStack {
          // Soft ambient glow behind bear
          Circle()
            .fill(Color(hex: "#6AB0FF").opacity(0.12))
            .frame(width: 260, height: 260)
            .blur(radius: bearGlow)
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: bearGlow)

          Image("bear_mascot")
            .resizable()
            .scaledToFit()
            .frame(width: 260, height: 260)
            .scaleEffect(bearScale)
            .brightness(bearBrightness)
            .blendMode(.screen)
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: bearScale)
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: bearBrightness)
        }

        // Breathing instruction
        Text(breatheIn ? "Breathe in..." : "Breathe out...")
          .font(.title3)
          .fontWeight(.light)
          .foregroundColor(.white.opacity(0.7))
          .padding(.top, 24)
          .animation(.easeInOut(duration: 0.6), value: breatheIn)

        Spacer().frame(height: 40)

        // Phase 1: Anchor message
        if phase == 1 {
          VStack(spacing: 8) {
            Text("You're safe.")
              .font(.system(size: 32, weight: .bold, design: .rounded))
              .foregroundColor(.white)
            Text("Stay with me.")
              .font(.title3)
              .fontWeight(.light)
              .foregroundColor(.white.opacity(0.7))
          }
          .transition(.opacity)
        }

        // Phase 2+: Rotating reassurance
        if phase >= 2 {
          Text(messages[messageIndex])
            .font(.title3)
            .fontWeight(.light)
            .foregroundColor(.white.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .opacity(messageOpacity)
            .transition(.opacity)
        }

        Spacer()

        // Phase 3: Outcome cards
        if phase >= 3 {
          VStack(spacing: 12) {
            Text("If you need more, try one of these:")
              .font(.caption)
              .foregroundColor(.white.opacity(0.45))
              .padding(.bottom, 4)

            LazyVGrid(
              columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
              spacing: 12
            ) {
              PanicActionCard(emoji: "💙", title: "Slow my heart") {
                showingBreathwork = true
              }
              PanicActionCard(emoji: "🌿", title: "Stop the spiral") {
                showingGrounding = true
              }
              PanicActionCard(emoji: "💪", title: "Release tension") {
                showingPMR = true
              }
              PanicActionCard(emoji: "🎮", title: "Distract my mind") {
                showingGames = true
              }
            }

            Button(action: endSession(outcome: "better_now")) {
              Text("I'm okay now")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.6))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                  RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
            .padding(.top, 4)
          }
          .padding(.horizontal, 24)
          .transition(.move(edge: .bottom).combined(with: .opacity))
          .animation(.easeOut(duration: 0.6), value: phase)
        }

        Spacer().frame(height: 40)
      }
    }
    .onAppear {
      setup()
    }
    .onDisappear {
      audioManager.stopSoundImmediately()
    }
    .sheet(isPresented: $showingBreathwork) { BreathingLibraryView() }
    .sheet(isPresented: $showingGrounding) { SomaticGroundingView() }
    .sheet(isPresented: $showingPMR) { PMRExerciseView() }
    .sheet(isPresented: $showingGames) { GameSelectionView(
      showingBubbleGame: .constant(false),
      showingMemoryGame: .constant(false),
      showingColoringGame: .constant(false)
    )}
    .sheet(
      isPresented: $showTriggerLog,
      onDismiss: {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          showPostRecovery = true
        }
      }
    ) {
      TriggerLogSheet(outcome: "better_now")
    }
    .sheet(isPresented: $showPostRecovery) {
      PostPanicRecoveryView(
        sessionDuration: sessionDuration,
        onReturnToHome: { dismiss() }
      )
    }
    .sheet(isPresented: $showAdditionalHelp) {
      AdditionalHelpView()
    }
  }

  // MARK: - Setup

  private func setup() {
    progressTracker.recordUsage()
    sessionId = AnalyticsLogger.shared.emergencyCalmStart(source: "panic_flow")

    if prefSounds {
      audioManager.playSound("ethereal-night-loop")
    }

    startBreathingCycle()
    startElapsedTimer()
  }

  // MARK: - Breathing cycle (4s in / 4s out)

  private func startBreathingCycle() {
    withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
      bearScale = 1.06
      bearBrightness = 0.08
      bearGlow = 28
    }
    scheduleBreathToggle()
  }

  private func scheduleBreathToggle() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
      withAnimation(.easeInOut(duration: 0.5)) {
        breatheIn.toggle()
      }
      scheduleBreathToggle()
    }
  }

  // MARK: - Elapsed timer — drives phase transitions and message rotation

  private func startElapsedTimer() {
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
      elapsed += 1

      // Start reassurance messages at phase 2
      if elapsed == 10 {
        withAnimation { messageOpacity = 1 }
      }

      // Rotate message every 7s during phase 2+
      if elapsed >= 10 && (elapsed - 10) % 7 == 0 {
        withAnimation(.easeOut(duration: 0.4)) { messageOpacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          messageIndex = (messageIndex + 1) % messages.count
          withAnimation(.easeIn(duration: 0.4)) { messageOpacity = 1 }
        }
      }
    }
  }

  // MARK: - End session

  private func endSession(outcome: String) -> () -> Void {
    {
      sessionDuration = Int(Date().timeIntervalSince(sessionStart))
      AnalyticsLogger.shared.emergencyCalmComplete(sessionId: sessionId, completed: outcome == "better_now")

      if outcome == "better_now" {
        progressTracker.recordReliefOutcome(.betterNow)
        audioManager.stopSound()
        showTriggerLog = true
      } else {
        audioManager.stopSound()
        dismiss()
      }
    }
  }
}

// MARK: - Action card

struct PanicActionCard: View {
  let emoji: String
  let title: String
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(spacing: 6) {
        Text(emoji)
          .font(.title2)
        Text(title)
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundColor(.white)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color.white.opacity(0.08))
          .overlay(
            RoundedRectangle(cornerRadius: 16)
              .stroke(Color.white.opacity(0.12), lineWidth: 1)
          )
      )
    }
    .buttonStyle(.plain)
  }
}
