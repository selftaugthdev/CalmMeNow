import SwiftUI

struct CooldownView: View {
  let model: CooldownModel
  @StateObject private var audioManager = AudioManager.shared
  @State private var isAnimating = false
  @State private var vibrationIntensity: CGFloat = 1.0
  @State private var colorTransition: Double = 0.0
  @State private var pulseDuration: Double = 0.5
  @State private var pulseToggle = false

  var body: some View {
    ZStack {
      // Background gradient
      LinearGradient(
        gradient: Gradient(colors: model.backgroundColors),
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack {
        Spacer()

        // Animation container
        ZStack {
          // Outer circle
          Circle()
            .stroke(Color.white.opacity(0.3), lineWidth: 2)
            .frame(width: 300, height: 300)

          // Animation content
          Group {
            switch model.animationType {
            case .breathing:
              breathingAnimation
            case .vibrating:
              vibratingAnimation
            case .pulsing:
              pulsingAnimation
            case .hugging:
              huggingAnimation
            }
          }
        }
        .onAppear {
          isAnimating = true
          if model.animationType == .vibrating {
            startCalmingAnimation()
          }
        }

        // Calming text
        if let text = model.optionalText {
          Text(text)
            .font(.title3)
            .multilineTextAlignment(.center)
            .foregroundColor(.black)
            .padding(.horizontal, 40)
            .padding(.top, 100)
            .padding(.bottom, 20)
            .fixedSize(horizontal: false, vertical: true)
        }

        Text("Click the button below for a soothing sound")
          .font(.body)
          .foregroundColor(.black.opacity(0.9))
          .padding(.bottom, 40)

        if audioManager.isPlaying {
          Text(timeString(from: audioManager.remainingTime))
            .font(.title)
            .foregroundColor(.white)
            .padding(.bottom, 20)
        }

        Button(action: {
          if audioManager.isPlaying {
            audioManager.stopSound()
          } else {
            audioManager.playSound(model.soundFileName)
          }
        }) {
          Text(audioManager.isPlaying ? "⏹ Stop" : "▶️ Start")
            .font(.title)
            .padding()
            .frame(maxWidth: .infinity)
            .background(audioManager.isPlaying ? Color.red.opacity(0.8) : Color.blue.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 40)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .onDisappear {
      audioManager.stopSound()
    }
  }

  // MARK: - Animation Views

  private var breathingAnimation: some View {
    VStack {
      Circle()
        .fill(Color.white.opacity(0.6))
        .frame(width: 200, height: 200)
        .scaleEffect(isAnimating ? 1.5 : 0.8)
        .animation(
          Animation.easeInOut(duration: 6)
            .repeatForever(autoreverses: true),
          value: isAnimating
        )

      Text("Let it go...")
        .font(.title2)
        .foregroundColor(.black)
        .opacity(0.9)
    }
  }

  private var vibratingAnimation: some View {
    Circle()
      .fill(Color.white.opacity(0.6))
      .frame(width: 200, height: 200)
      .scaleEffect(pulseToggle ? 1.15 : 0.85)
      .rotationEffect(.degrees(pulseToggle ? 5 : -5))
      .offset(x: pulseToggle ? 5 : -5, y: pulseToggle ? -5 : 5)
      .animation(
        Animation.easeInOut(duration: pulseDuration)
          .repeatForever(autoreverses: true),
        value: pulseToggle
      )
  }

  private var pulsingAnimation: some View {
    Circle()
      .fill(Color.white.opacity(0.4))
      .frame(width: 250, height: 250)
      .scaleEffect(isAnimating ? 1.3 : 0.7)
      .animation(
        Animation.easeInOut(duration: 2.5)
          .repeatForever(autoreverses: true),
        value: isAnimating
      )
  }

  private var huggingAnimation: some View {
    ZStack {
      // Left arm
      Circle()
        .trim(from: 0.5, to: 1.0)
        .stroke(Color.blue.opacity(0.5), lineWidth: 10)
        .frame(width: 200, height: 200)
        .rotationEffect(.degrees(isAnimating ? -30 : -10))
        .offset(x: -50)
        .animation(
          Animation.easeInOut(duration: 2)
            .repeatForever(autoreverses: true),
          value: isAnimating
        )

      // Right arm
      Circle()
        .trim(from: 0, to: 0.5)
        .stroke(Color.blue.opacity(0.5), lineWidth: 10)
        .frame(width: 200, height: 200)
        .rotationEffect(.degrees(isAnimating ? 30 : 10))
        .offset(x: 50)
        .animation(
          Animation.easeInOut(duration: 2)
            .repeatForever(autoreverses: true),
          value: isAnimating
        )

      // Heart
      Image(systemName: "heart.fill")
        .resizable()
        .frame(width: 70, height: 70)
        .foregroundColor(.pink.opacity(0.9))
        .scaleEffect(isAnimating ? 1.2 : 1.0)
        .animation(
          Animation.easeInOut(duration: pulseDuration)
            .repeatForever(autoreverses: true),
          value: isAnimating
        )
    }
  }

  // MARK: - Helper Functions

  private func startCalmingAnimation() {
    // Start with a faster pulse
    pulseDuration = 0.5

    // Start the animation toggler
    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
      withAnimation {
        pulseToggle.toggle()
      }
    }

    // Gradually slow down the animation duration
    Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
      if pulseDuration >= 2.5 {
        timer.invalidate()
      } else {
        pulseDuration += 0.3
      }
    }
  }

  private func timeString(from timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }
}
