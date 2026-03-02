import SwiftUI
import UIKit

// MARK: - Night Protocol View

struct NightProtocolView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var speechService = SpeechService()
  @AppStorage("prefSounds") private var prefSounds = true

  // MARK: - Phase

  enum NightPhase: Equatable {
    case landing, breathe, ground, release, rest
  }

  private enum BreathPhase478: Equatable {
    case inhale, hold, exhale

    var duration: TimeInterval {
      switch self {
      case .inhale: return 4
      case .hold: return 7
      case .exhale: return 8
      }
    }

    var label: String {
      switch self {
      case .inhale: return "breathe in…"
      case .hold: return "hold…"
      case .exhale: return "let it go…"
      }
    }

    var next: BreathPhase478 {
      switch self {
      case .inhale: return .hold
      case .hold: return .exhale
      case .exhale: return .inhale
      }
    }
  }

  // MARK: - State

  @State private var currentPhase: NightPhase = .landing

  // Landing
  @State private var landingOpacity: Double = 0
  @State private var landingOrbPulse: Bool = false

  // Breathe
  @State private var breathPhase: BreathPhase478 = .inhale
  @State private var breathPhaseElapsed: TimeInterval = 0
  @State private var breathCycle: Int = 0
  @State private var breathTimer: Timer?
  @State private var breathOrbScale: CGFloat = 0.6
  @State private var breathCountdown: Int = 4
  @State private var hasSpokenBreatheTTS: Bool = false

  // Ground
  @State private var tappedGroundItems: Set<Int> = []
  @State private var isGroundTransitioning: Bool = false

  // Release
  @State private var releaseOpacities: [Double] = [0, 0, 0]

  // Rest
  @State private var restOrbPulse: Bool = false
  @State private var originalBrightness: CGFloat = 0.5

  // MARK: - Data

  private let groundItems: [(emoji: String, text: String)] = [
    ("🛏️", "Feel the bed beneath you"),
    ("🌡️", "Notice the air on your skin"),
    ("👂", "Hear the sounds around you"),
  ]

  private let releaseLines: [String] = [
    "The nightmare is over.",
    "What you felt was your nervous system protecting you.",
    "You are safe. Right here. Right now.",
  ]

  // MARK: - Body

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color(hex: "#0A0E1A"), Color(hex: "#1A2340")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      Group {
        switch currentPhase {
        case .landing:
          landingView.transition(.opacity)
        case .breathe:
          breatheView.transition(.opacity)
        case .ground:
          groundView.transition(.opacity)
        case .release:
          releaseView.transition(.opacity)
        case .rest:
          restView.transition(.opacity)
        }
      }
      .animation(.easeInOut(duration: 0.6), value: currentPhase)
    }
    .onAppear {
      originalBrightness = UIScreen.main.brightness
      startLanding()
    }
    .onDisappear {
      cleanUp()
    }
  }

  // MARK: - Orb Helper

  private func nightOrb(scale: CGFloat, opacity: Double = 0.15) -> some View {
    Circle()
      .fill(Color(red: 180 / 255, green: 200 / 255, blue: 255 / 255).opacity(opacity))
      .frame(width: 220, height: 220)
      .scaleEffect(scale)
      .blur(radius: 20)
  }

  // MARK: - Landing View

  private var landingView: some View {
    VStack(spacing: 32) {
      Spacer()

      nightOrb(scale: landingOrbPulse ? 1.05 : 0.9)
        .animation(
          .easeInOut(duration: 3).repeatForever(autoreverses: true),
          value: landingOrbPulse
        )
        .onAppear { landingOrbPulse = true }

      VStack(spacing: 16) {
        Text("You're safe.")
          .font(.system(size: 38, weight: .bold, design: .rounded))
          .foregroundColor(.white)

        Text("You're home.")
          .font(.system(size: 30, weight: .semibold, design: .rounded))
          .foregroundColor(.white.opacity(0.85))
      }

      Spacer()

      pillButton(label: "I'm ready", action: advanceToBreathe)
        .padding(.bottom, 60)
    }
    .opacity(landingOpacity)
  }

  // MARK: - Breathe View

  private var breatheView: some View {
    VStack(spacing: 0) {
      Spacer()

      Text("Come Back to Now")
        .font(.system(size: 22, weight: .semibold, design: .rounded))
        .foregroundColor(.white.opacity(0.6))
        .padding(.bottom, 40)

      ZStack {
        nightOrb(scale: breathOrbScale, opacity: 0.18)

        VStack(spacing: 8) {
          Text(breathPhase.label)
            .font(.system(size: 28, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .animation(.easeInOut(duration: 0.3), value: breathPhase.label)

          if breathPhase != .hold {
            Text("\(breathCountdown)")
              .font(.system(size: 48, weight: .bold, design: .rounded))
              .foregroundColor(.white.opacity(0.8))
              .monospacedDigit()
          }
        }
      }

      Text("Cycle \(min(breathCycle + 1, 4)) of 4")
        .font(.system(size: 14, weight: .medium, design: .rounded))
        .foregroundColor(.white.opacity(0.35))
        .padding(.top, 32)

      Spacer()

      skipButton(label: "Skip breathing", action: advanceToGround)
        .padding(.bottom, 60)
    }
  }

  // MARK: - Ground View

  private var groundView: some View {
    VStack(spacing: 0) {
      Spacer()

      Text("Notice 3 things\nright now.")
        .font(.system(size: 32, weight: .bold, design: .rounded))
        .foregroundColor(.white)
        .multilineTextAlignment(.center)
        .padding(.bottom, 48)

      VStack(spacing: 16) {
        ForEach(0..<groundItems.count, id: \.self) { i in
          groundItemRow(index: i)
        }
      }
      .padding(.horizontal, 32)

      Spacer()

      skipButton(label: "Skip grounding", action: advanceToRelease)
        .padding(.bottom, 60)
    }
  }

  private func groundItemRow(index: Int) -> some View {
    let item = groundItems[index]
    let isTapped = tappedGroundItems.contains(index)

    return Button(action: { tapGroundItem(index) }) {
      HStack(spacing: 16) {
        Text(item.emoji)
          .font(.system(size: 28))

        Text(item.text)
          .font(.system(size: 18, weight: .medium, design: .rounded))
          .foregroundColor(isTapped ? .white.opacity(0.5) : .white)

        Spacer()

        if isTapped {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 22))
            .foregroundColor(.white.opacity(0.6))
            .transition(.scale.combined(with: .opacity))
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(isTapped ? Color.white.opacity(0.06) : Color.white.opacity(0.1))
          .overlay(
            RoundedRectangle(cornerRadius: 16)
              .stroke(Color.white.opacity(0.15), lineWidth: 1)
          )
      )
    }
    .buttonStyle(PlainButtonStyle())
    .animation(.easeInOut(duration: 0.2), value: isTapped)
  }

  // MARK: - Release View

  private var releaseView: some View {
    VStack(spacing: 0) {
      Spacer()

      VStack(spacing: 24) {
        ForEach(0..<releaseLines.count, id: \.self) { i in
          Text(releaseLines[i])
            .font(
              .system(
                size: i == 0 ? 28 : 18,
                weight: i == 0 ? .bold : .regular,
                design: .rounded
              )
            )
            .foregroundColor(i == 0 ? .white : .white.opacity(0.75))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .opacity(releaseOpacities[i])
        }
      }

      Spacer()

      pillButton(label: "I know", action: advanceToRest)
        .opacity(releaseOpacities.last ?? 0)
        .padding(.bottom, 60)
    }
  }

  // MARK: - Rest View

  private var restView: some View {
    VStack(spacing: 0) {
      Spacer()

      nightOrb(scale: restOrbPulse ? 1.02 : 0.95, opacity: 0.1)
        .animation(
          .easeInOut(duration: 4).repeatForever(autoreverses: true),
          value: restOrbPulse
        )
        .onAppear { restOrbPulse = true }

      Text("You can rest now 🌙")
        .font(.system(size: 28, weight: .semibold, design: .rounded))
        .foregroundColor(.white.opacity(0.6))
        .padding(.top, 40)

      Spacer()

      VStack(spacing: 16) {
        Button(action: {}) {
          Text("Stay here")
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.8))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
              Capsule()
                .fill(Color.white.opacity(0.08))
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
            )
        }

        Button(action: dismiss) {
          Text("Close")
            .font(.system(size: 16, design: .rounded))
            .foregroundColor(.white.opacity(0.35))
        }
      }
      .padding(.horizontal, 48)
      .padding(.bottom, 60)
    }
  }

  // MARK: - Shared Button Components

  private func pillButton(label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(label)
        .font(.system(size: 20, weight: .semibold, design: .rounded))
        .foregroundColor(.white.opacity(0.9))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
          Capsule()
            .fill(Color.white.opacity(0.12))
            .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
        )
    }
    .padding(.horizontal, 48)
  }

  private func skipButton(label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(label)
        .font(.system(size: 15, design: .rounded))
        .foregroundColor(.white.opacity(0.3))
    }
  }

  // MARK: - Phase Actions

  private func startLanding() {
    AudioManager.shared.playSound("ethereal-night-loop", loop: true)
    withAnimation(.easeIn(duration: 1.5)) {
      landingOpacity = 1.0
    }
    if prefSounds {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
        speechService.speak("You're safe. You're home. Take a breath.", rate: 0.4)
      }
    }
  }

  private func advanceToBreathe() {
    HapticManager.shared.softImpact()
    withAnimation(.easeInOut(duration: 0.6)) {
      currentPhase = .breathe
    }
    startBreathing()
  }

  private func startBreathing() {
    breathPhase = .inhale
    breathPhaseElapsed = 0
    breathCycle = 0
    breathOrbScale = 0.6
    breathCountdown = 4
    hasSpokenBreatheTTS = false

    if prefSounds {
      hasSpokenBreatheTTS = true
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        speechService.speak("Breathe in… hold… let it all go.", rate: 0.4)
      }
    }

    HapticManager.shared.softImpact()

    breathTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
      DispatchQueue.main.async { self.breathTick() }
    }
  }

  private func breathTick() {
    breathPhaseElapsed += 0.1

    // Update orb scale
    switch breathPhase {
    case .inhale:
      let progress = min(1.0, breathPhaseElapsed / breathPhase.duration)
      breathOrbScale = 0.6 + (0.5 * CGFloat(progress))
    case .hold:
      breathOrbScale = 1.1
    case .exhale:
      let progress = min(1.0, breathPhaseElapsed / breathPhase.duration)
      breathOrbScale = 1.1 - (0.5 * CGFloat(progress))
    }

    // Update countdown display for inhale/exhale phases
    if breathPhase != .hold {
      let remaining = max(1, Int(ceil(breathPhase.duration - breathPhaseElapsed)))
      if remaining != breathCountdown {
        breathCountdown = remaining
      }
    }

    // Advance to next phase when duration complete
    if breathPhaseElapsed >= breathPhase.duration {
      breathPhaseElapsed = 0
      breathPhase = breathPhase.next
      HapticManager.shared.softImpact()

      switch breathPhase {
      case .inhale:
        breathCountdown = 4
        breathCycle += 1
        if breathCycle >= 4 {
          breathTimer?.invalidate()
          breathTimer = nil
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.advanceToGround()
          }
        }
      case .hold:
        break
      case .exhale:
        breathCountdown = 8
      }
    }
  }

  private func advanceToGround() {
    guard currentPhase == .breathe else { return }
    breathTimer?.invalidate()
    breathTimer = nil
    HapticManager.shared.softImpact()
    withAnimation(.easeInOut(duration: 0.6)) {
      currentPhase = .ground
    }
  }

  private func tapGroundItem(_ index: Int) {
    guard !tappedGroundItems.contains(index), !isGroundTransitioning else { return }
    withAnimation { tappedGroundItems.insert(index) }
    HapticManager.shared.softImpact()

    if tappedGroundItems.count >= groundItems.count {
      isGroundTransitioning = true
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.advanceToRelease()
      }
    }
  }

  private func advanceToRelease() {
    guard currentPhase == .ground else { return }
    isGroundTransitioning = false
    HapticManager.shared.softImpact()
    withAnimation(.easeInOut(duration: 0.6)) {
      currentPhase = .release
    }
    for i in 0..<releaseLines.count {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + Double(i) * 1.2) {
        withAnimation(.easeIn(duration: 0.8)) {
          self.releaseOpacities[i] = 1.0
        }
      }
    }
  }

  private func advanceToRest() {
    HapticManager.shared.softImpact()
    withAnimation(.easeInOut(duration: 0.6)) {
      currentPhase = .rest
    }
    UIScreen.main.brightness = 0.1
  }

  private func dismiss() {
    cleanUp()
    presentationMode.wrappedValue.dismiss()
  }

  private func cleanUp() {
    breathTimer?.invalidate()
    breathTimer = nil
    speechService.stop()
    AudioManager.shared.stopSoundImmediately()
    UIScreen.main.brightness = originalBrightness
  }
}

#Preview {
  NightProtocolView()
}
