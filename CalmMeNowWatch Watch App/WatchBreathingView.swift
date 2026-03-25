import SwiftUI
import WatchKit

private enum BreathPhase: String {
  case inhale = "Breathe in..."
  case hold = "Hold..."
  case exhale = "Breathe out..."
  var duration: TimeInterval { self == .inhale ? 4 : (self == .hold ? 2 : 6) }
  func next() -> BreathPhase { self == .inhale ? .hold : (self == .hold ? .exhale : .inhale) }
  var haptic: WKHapticType { self == .inhale ? .start : (self == .hold ? .click : .stop) }
}

struct WatchBreathingView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var inSession = false
  @State private var elapsed: TimeInterval = 0
  @State private var phase: BreathPhase = .inhale
  @State private var phaseElapsed: TimeInterval = 0
  @State private var bearScale: CGFloat = 0.94
  @State private var progress: Double = 0
  @State private var timer: Timer?
  @State private var showPostSession = false

  private let sessionLength: TimeInterval = 60

  var body: some View {
    ZStack {
      Color(hex: "#0A1628").ignoresSafeArea()

      if showPostSession {
        WatchPostSessionView(duration: Int(elapsed)) {
          dismiss()
        }
      } else if !inSession {
        // Pre-session
        VStack(spacing: 12) {
          Image("bear_mascot")
            .resizable()
            .scaledToFit()
            .frame(width: 60, height: 60)
            .blendMode(.screen)

          Text("Stay with me.")
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.white)

          Button("Start") {
            startSession()
          }
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 9)
          .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#3A6ED4")))
          .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
      } else {
        // Active session
        GeometryReader { geo in
          let D = min(geo.size.width, geo.size.height) * 0.9
          let ringW: CGFloat = 6

          ZStack {
            // Track ring
            Circle()
              .stroke(Color.white.opacity(0.1), lineWidth: ringW)
              .frame(width: D, height: D)

            // Progress ring
            Circle()
              .trim(from: 0, to: progress)
              .stroke(
                Color(hex: "#6AB0FF"),
                style: StrokeStyle(lineWidth: ringW, lineCap: .round)
              )
              .rotationEffect(.degrees(-90))
              .frame(width: D, height: D)
              .animation(.linear(duration: 0.1), value: progress)

            VStack(spacing: 4) {
              Image("bear_mascot")
                .resizable()
                .scaledToFit()
                .frame(width: D * 0.48, height: D * 0.48)
                .scaleEffect(bearScale)
                .blendMode(.screen)
                .animation(.easeInOut(duration: phase == .inhale ? 4 : 6), value: bearScale)

              Text(phase.rawValue)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

              Text("\(Int(max(0, sessionLength - elapsed)))s")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(6)

        VStack {
          Spacer()
          Button("Stop") { endSession() }
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.4))
            .padding(.bottom, 4)
        }
      }
    }
  }

  private func startSession() {
    inSession = true
    elapsed = 0
    progress = 0
    phase = .inhale
    phaseElapsed = 0
    WKInterfaceDevice.current().play(phase.haptic)
    updateBearScale()

    timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
      elapsed += 0.1
      phaseElapsed += 0.1
      progress = min(1, elapsed / sessionLength)
      advancePhaseIfNeeded()
      if elapsed >= sessionLength { endSession() }
    }
  }

  private func endSession() {
    timer?.invalidate()
    timer = nil
    WKInterfaceDevice.current().play(.success)
    withAnimation { showPostSession = true }
  }

  private func advancePhaseIfNeeded() {
    if phaseElapsed >= phase.duration {
      phaseElapsed = 0
      phase = phase.next()
      WKInterfaceDevice.current().play(phase.haptic)
      updateBearScale()
    }
  }

  private func updateBearScale() {
    withAnimation(.easeInOut(duration: phase.duration)) {
      bearScale = phase == .inhale ? 1.06 : (phase == .exhale ? 0.94 : bearScale)
    }
  }
}
