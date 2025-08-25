import SwiftUI
import WatchConnectivity
import WatchKit

private enum BreathPhase: String {
  case inhale = "Inhale"
  case hold = "Hold"
  case exhale = "Exhale"
  var duration: TimeInterval { self == .inhale ? 4 : (self == .hold ? 2 : 6) }
  func next() -> BreathPhase { self == .inhale ? .hold : (self == .hold ? .exhale : .inhale) }
}

struct WatchCalmView: View {
  @State private var inSession = false
  @State private var totalLength: TimeInterval = 60
  @State private var elapsed: TimeInterval = 0
  @State private var progress: Double = 0
  @State private var phase: BreathPhase = .inhale
  @State private var phaseElapsed: TimeInterval = 0
  @State private var catScale: CGFloat = 1.0
  @State private var timer: Timer?

  var body: some View {
    VStack(spacing: 8) {
      if !inSession {
        Picker("Length", selection: $totalLength) {
          Text("60s").tag(60.0)
          Text("120s").tag(120.0)
        }
        .pickerStyle(.segmented)

        Button {
          startSession()
        } label: {
          Text("Calm Now").font(.headline)
        }
        // If you still want a tiny mascot here, uncomment:
        // CatMascotWatch(scale: .constant(1.0))
        //     .frame(width: 68, height: 68)
      } else {
        GeometryReader { geo in
          let D = min(geo.size.width, geo.size.height)  // ring diameter
          let ringWidth: CGFloat = 8
          let safeInset = D * 0.18  // space from ring to mascot
          // Base mascot size chosen so max scale (~1.08) still fits inside ring:
          let mascotSize = D - (2 * safeInset)

          ZStack {
            Circle()
              .stroke(.gray.opacity(0.25), lineWidth: ringWidth)
              .frame(width: D, height: D)

            Circle()
              .trim(from: 0, to: progress)
              .stroke(.green, style: .init(lineWidth: ringWidth, lineCap: .round))
              .rotationEffect(.degrees(-90))
              .frame(width: D, height: D)
              .animation(.linear(duration: 0.1), value: progress)

            VStack(spacing: 6) {
              CatMascotWatch(scale: $catScale)
                .frame(width: mascotSize, height: mascotSize)

              Text(phase.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)

              Text("\(Int(max(0, totalLength - elapsed)))s")
                .font(.headline)
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 190)

        Button("Stop") { endSession() }.padding(.top, 4)
      }
    }
    .onAppear { WCSessionDelegateHelper.shared.activate() }
  }

  private func startSession() {
    inSession = true
    elapsed = 0
    progress = 0
    phase = .inhale
    phaseElapsed = 0
    setScale(for: .inhale, animated: false)
    playHaptic(for: .inhale)

    // optional: trigger iPhone audio
    WCSessionDelegateHelper.shared.sendStartAudio(length: Int(totalLength))

    timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
      elapsed += 0.1
      progress = min(1, elapsed / totalLength)
      phaseElapsed += 0.1
      advancePhaseIfNeeded()
      if elapsed >= totalLength { endSession() }
    }
  }

  private func endSession() {
    timer?.invalidate()
    timer = nil
    inSession = false
    progress = 0
    elapsed = 0
    phaseElapsed = 0
    catScale = 1.0
    WKInterfaceDevice.current().play(.success)

    // Stop audio on iPhone
    WCSessionDelegateHelper.shared.sendStopAudio()
  }

  private func advancePhaseIfNeeded() {
    if phaseElapsed >= phase.duration {
      phaseElapsed = 0
      phase = phase.next()
      setScale(for: phase, animated: true)
      playHaptic(for: phase)
    } else {
      let p = CGFloat(phaseElapsed / phase.duration)
      switch phase {
      case .inhale: catScale = 1.0 + 0.08 * p
      case .exhale: catScale = 1.08 - 0.10 * p
      case .hold: break
      }
    }
  }

  private func setScale(for phase: BreathPhase, animated: Bool) {
    let target: CGFloat = (phase == .inhale) ? 1.08 : (phase == .exhale ? 0.98 : catScale)
    if animated {
      withAnimation(.easeInOut(duration: 0.2)) { catScale = target }
    } else {
      catScale = target
    }
  }

  private func playHaptic(for phase: BreathPhase) {
    switch phase {
    case .inhale: WKInterfaceDevice.current().play(.start)
    case .hold: WKInterfaceDevice.current().play(.click)
    case .exhale: WKInterfaceDevice.current().play(.stop)
    }
  }
}
