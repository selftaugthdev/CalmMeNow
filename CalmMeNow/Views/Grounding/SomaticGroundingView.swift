import SwiftUI

// MARK: - Sense Step Model

private struct SenseStep {
  let number: Int
  let sense: String
  let prompt: String
  let icon: String
  let topColor: Color
  let bottomColor: Color
}

// MARK: - Somatic Grounding View

struct SomaticGroundingView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var speechService = SpeechService()
  @AppStorage("prefSounds") private var prefSounds = true

  enum Phase: Equatable {
    case intro
    case sense(Int)
    case complete
  }

  @State private var phase: Phase = .intro
  @State private var tappedItems: Set<Int> = []
  @State private var isTransitioning = false

  private let senses: [SenseStep] = [
    SenseStep(
      number: 5, sense: "SEE",
      prompt: "Look around you.\nName 5 things you can see.",
      icon: "eye.fill",
      topColor: Color(hex: "#1B4F8A"),
      bottomColor: Color(hex: "#4A90D9")
    ),
    SenseStep(
      number: 4, sense: "TOUCH",
      prompt: "Feel 4 things you can\nphysically touch right now.",
      icon: "hand.raised.fill",
      topColor: Color(hex: "#3D1F7A"),
      bottomColor: Color(hex: "#7B68EE")
    ),
    SenseStep(
      number: 3, sense: "HEAR",
      prompt: "Listen carefully.\nName 3 things you can hear.",
      icon: "ear.fill",
      topColor: Color(hex: "#1A5C50"),
      bottomColor: Color(hex: "#3AAA8C")
    ),
    SenseStep(
      number: 2, sense: "SMELL",
      prompt: "Notice 2 things you can\nsmell around you.",
      icon: "nose.fill",
      topColor: Color(hex: "#7A4A10"),
      bottomColor: Color(hex: "#D4882A")
    ),
    SenseStep(
      number: 1, sense: "TASTE",
      prompt: "Notice 1 thing you can\ntaste right now.",
      icon: "mouth.fill",
      topColor: Color(hex: "#6B1E1E"),
      bottomColor: Color(hex: "#C0514F")
    ),
  ]

  var body: some View {
    ZStack {
      backgroundGradient
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.7), value: phase)

      switch phase {
      case .intro:
        introView
          .transition(.opacity)
      case .sense(let i):
        senseView(for: senses[i], index: i)
          .transition(
            .asymmetric(
              insertion: .move(edge: .trailing).combined(with: .opacity),
              removal: .move(edge: .leading).combined(with: .opacity)
            ))
      case .complete:
        completionView
          .transition(.opacity)
      }
    }
    .onDisappear {
      speechService.stop()
    }
  }

  // MARK: - Background

  private var backgroundGradient: some View {
    let (top, bottom): (Color, Color) = {
      switch phase {
      case .intro:
        return (Color(hex: "#2D6B5E"), Color(hex: "#4A9B8C"))
      case .sense(let i):
        return (senses[i].topColor, senses[i].bottomColor)
      case .complete:
        return (Color(hex: "#1A3A2E"), Color(hex: "#2D6B5E"))
      }
    }()
    return LinearGradient(colors: [top, bottom], startPoint: .topLeading, endPoint: .bottomTrailing)
  }

  // MARK: - Intro

  private var introView: some View {
    VStack(spacing: 32) {
      Spacer()

      Text("🌱")
        .font(.system(size: 80))

      VStack(spacing: 10) {
        Text("5-4-3-2-1")
          .font(.system(size: 44, weight: .bold, design: .rounded))
          .foregroundColor(.white)

        Text("Grounding")
          .font(.system(size: 30, weight: .semibold, design: .rounded))
          .foregroundColor(.white.opacity(0.85))
      }

      Text("Use your 5 senses to anchor yourself to this moment and return to the present.")
        .font(.title3)
        .foregroundColor(.white.opacity(0.85))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)

      Spacer()

      VStack(spacing: 16) {
        Button(action: startGrounding) {
          Text("Begin")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(Color(hex: "#2D6B5E"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.white)
            .cornerRadius(16)
        }
        .padding(.horizontal, 40)

        Button("Maybe later") {
          presentationMode.wrappedValue.dismiss()
        }
        .font(.subheadline)
        .foregroundColor(.white.opacity(0.7))
      }
      .padding(.bottom, 50)
    }
  }

  // MARK: - Sense Screen

  private func senseView(for step: SenseStep, index: Int) -> some View {
    VStack(spacing: 0) {
      // Close button + progress bar
      HStack(alignment: .center, spacing: 12) {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
          Image(systemName: "xmark")
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white.opacity(0.7))
            .padding(10)
            .background(Circle().fill(Color.white.opacity(0.15)))
        }

        progressBar(currentIndex: index)
      }
      .padding(.horizontal, 24)
      .padding(.top, 56)

      Spacer()

      VStack(spacing: 28) {
        // Sense badge circle
        ZStack {
          Circle()
            .fill(Color.white.opacity(0.15))
            .frame(width: 130, height: 130)

          VStack(spacing: 6) {
            Text("\(step.number)")
              .font(.system(size: 56, weight: .bold, design: .rounded))
              .foregroundColor(.white)

            Image(systemName: step.icon)
              .font(.system(size: 20, weight: .semibold))
              .foregroundColor(.white.opacity(0.85))
          }
        }

        // Sense label + prompt
        VStack(spacing: 10) {
          Text(step.sense)
            .font(.system(size: 13, weight: .bold))
            .tracking(5)
            .foregroundColor(.white.opacity(0.65))

          Text(step.prompt)
            .font(.system(size: 22, weight: .semibold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
        }

        // Tappable dots
        tapDots(count: step.number, accentColor: step.bottomColor)
          .padding(.top, 8)

        // Helper hint
        Text(
          tappedItems.count < step.number
            ? "Tap each dot as you notice one"
            : "All found — moving on..."
        )
        .font(.caption)
        .foregroundColor(.white.opacity(0.65))
        .animation(.easeInOut, value: tappedItems.count)
      }

      Spacer()

      Button("Skip this sense") {
        advancePhase(from: index)
      }
      .font(.caption)
      .foregroundColor(.white.opacity(0.4))
      .padding(.bottom, 50)
    }
  }

  // MARK: - Tappable Dots

  private func tapDots(count: Int, accentColor: Color) -> some View {
    let dotSize: CGFloat = count == 5 ? 50 : 56
    let spacing: CGFloat = count == 5 ? 10 : 14

    return HStack(spacing: spacing) {
      ForEach(0..<count, id: \.self) { i in
        Button(action: { tapItem(i) }) {
          ZStack {
            Circle()
              .fill(tappedItems.contains(i) ? Color.white : Color.white.opacity(0.2))
              .frame(width: dotSize, height: dotSize)

            if tappedItems.contains(i) {
              Image(systemName: "checkmark")
                .font(.system(size: dotSize * 0.38, weight: .bold))
                .foregroundColor(accentColor)
            }
          }
        }
        .scaleEffect(tappedItems.contains(i) ? 1.12 : 1.0)
        .animation(
          .spring(response: 0.3, dampingFraction: 0.5), value: tappedItems.contains(i))
      }
    }
  }

  // MARK: - Progress Bar

  private func progressBar(currentIndex: Int) -> some View {
    HStack(spacing: 6) {
      ForEach(0..<senses.count, id: \.self) { i in
        Capsule()
          .fill(i <= currentIndex ? Color.white : Color.white.opacity(0.3))
          .frame(height: 4)
      }
    }
  }

  // MARK: - Completion

  private var completionView: some View {
    VStack(spacing: 32) {
      Spacer()

      ZStack {
        Circle()
          .fill(Color.white.opacity(0.15))
          .frame(width: 150, height: 150)

        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 80))
          .foregroundColor(.white)
      }

      VStack(spacing: 10) {
        Text("You're here.")
          .font(.system(size: 38, weight: .bold, design: .rounded))
          .foregroundColor(.white)

        Text("You're now.")
          .font(.system(size: 30, weight: .semibold, design: .rounded))
          .foregroundColor(.white.opacity(0.85))
      }

      Text(
        "You've anchored yourself to the present moment.\nWell done."
      )
      .font(.title3)
      .foregroundColor(.white.opacity(0.85))
      .multilineTextAlignment(.center)
      .padding(.horizontal, 40)

      Spacer()

      VStack(spacing: 16) {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
          Text("I feel grounded  🌱")
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundColor(Color(hex: "#1A3A2E"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.white)
            .cornerRadius(16)
        }
        .padding(.horizontal, 40)

        Button("Go again") {
          tappedItems = []
          withAnimation { phase = .intro }
        }
        .font(.subheadline)
        .foregroundColor(.white.opacity(0.7))
      }
      .padding(.bottom, 50)
    }
  }

  // MARK: - Actions

  private func startGrounding() {
    HapticManager.shared.mediumImpact()
    tappedItems = []
    withAnimation { phase = .sense(0) }
    if prefSounds {
      speechService.speak(senses[0].prompt.replacingOccurrences(of: "\n", with: " "))
    }
  }

  private func tapItem(_ index: Int) {
    guard !tappedItems.contains(index), !isTransitioning else { return }
    tappedItems.insert(index)
    HapticManager.shared.lightImpact()

    if case .sense(let senseIndex) = phase, tappedItems.count >= senses[senseIndex].number {
      isTransitioning = true
      HapticManager.shared.success()
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
        advancePhase(from: senseIndex)
      }
    }
  }

  private func advancePhase(from index: Int) {
    tappedItems = []
    isTransitioning = false
    let next = index + 1
    if next < senses.count {
      withAnimation { phase = .sense(next) }
      if prefSounds {
        speechService.speak(senses[next].prompt.replacingOccurrences(of: "\n", with: " "))
      }
    } else {
      withAnimation { phase = .complete }
      HapticManager.shared.success()
      if prefSounds {
        speechService.speak("Well done. You are here. You are grounded.")
      }
    }
  }
}

#Preview {
  SomaticGroundingView()
}
