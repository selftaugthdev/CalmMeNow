import SwiftUI

struct AngryView: View {
  @StateObject private var audioManager = AudioManager.shared
  @State private var isAnimating = false
  @State private var vibrationIntensity: CGFloat = 1.0
  @State private var colorTransition: Double = 0.0

  var body: some View {
    ZStack {
      // Background gradient that transitions from angry to calm colors
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "#FF6B6B"),  // Angry red-orange
          Color(hex: "#4ECDC4"),  // Calm blue
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
      .opacity(1 - colorTransition)
      .ignoresSafeArea()

      // Calm gradient that fades in
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "#B5D8F6"),
          Color(hex: "#D7CFF5"),
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
      .opacity(colorTransition)
      .ignoresSafeArea()

      VStack {
        Spacer()

        // Anger dissipating visualization
        ZStack {
          // Outer circle
          Circle()
            .stroke(Color.white.opacity(0.3), lineWidth: 2)
            .frame(width: 300, height: 300)

          // Vibrating circle
          Circle()
            .fill(Color.white.opacity(0.4))
            .frame(width: 200, height: 200)
            .scaleEffect(isAnimating ? 1.1 : 0.9)
            .rotationEffect(.degrees(isAnimating ? 5 : -5))
            .offset(x: isAnimating ? 5 : -5, y: isAnimating ? -5 : 5)
            .animation(
              Animation.easeInOut(duration: 0.2)
                .repeatForever(autoreverses: true)
                .speed(vibrationIntensity),
              value: isAnimating
            )

          // Calming text
          Text("Let it go...")
            .font(.title2)
            .foregroundColor(.white)
            .opacity(0.9)
        }
        .onAppear {
          isAnimating = true
          startCalmingAnimation()
        }

        // Calming text
        Text("Take deep breaths and feel the anger dissolve")
          .font(.title3)
          .multilineTextAlignment(.center)
          .foregroundColor(.white)
          .padding(.horizontal, 40)
          .padding(.top, 100)
          .padding(.bottom, 20)
          .fixedSize(horizontal: false, vertical: true)

        Text("Click the button below for a calming sound")
          .font(.body)
          .foregroundColor(.white.opacity(0.9))
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
            audioManager.playSound("mixkit-just-chill-angry")
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
  }

  private func startCalmingAnimation() {
    // Gradually slow down the vibration
    withAnimation(.easeOut(duration: 10)) {
      vibrationIntensity = 0.2
    }

    // Gradually transition the colors
    withAnimation(.easeInOut(duration: 10)) {
      colorTransition = 1.0
    }
  }

  private func timeString(from timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }
}
