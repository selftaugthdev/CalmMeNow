import SwiftUI

struct AnxiousView: View {
  @StateObject private var audioManager = AudioManager.shared
  @State private var isBreathing = false
  @State private var breathingText = "Inhale... 2... 3..."
  @State private var textOpacity = 1.0

  var body: some View {
    ZStack {
      // Background gradient
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "#B5D8F6"),
          Color(hex: "#D7CFF5"),
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack {
        Spacer()

        // Breathing circle
        ZStack {
          // Outer circle
          Circle()
            .stroke(Color.white.opacity(0.3), lineWidth: 2)
            .frame(width: 300, height: 300)

          // Breathing circle
          Circle()
            .fill(Color.white.opacity(0.4))
            .frame(width: 200, height: 200)
            .scaleEffect(isBreathing ? 1.5 : 0.8)
            .animation(
              Animation.easeInOut(duration: 6)
                .repeatForever(autoreverses: true),
              value: isBreathing
            )

          // Breathing text
          Text(breathingText)
            .font(.title2)
            .foregroundColor(.black)
            .opacity(textOpacity)
            .animation(.easeInOut(duration: 0.5), value: textOpacity)
        }
        .onAppear {
          isBreathing = true
          startBreathingTextAnimation()
        }

        // Calming text
        Text("Take a moment to breathe. Let's find your calm together.")
          .font(.title3)
          .multilineTextAlignment(.center)
          .foregroundColor(.black)
          .padding(.horizontal, 40)
          .padding(.top, 100)
          .padding(.bottom, 20)
          .fixedSize(horizontal: false, vertical: true)

        Text("Click the button below for a soothing sound")
          .font(.body)
          .foregroundColor(.black.opacity(0.9))
          .padding(.bottom, 40)

        if audioManager.isPlaying {
          Text(timeString(from: audioManager.remainingTime))
            .font(.title)
            .foregroundColor(.black)
            .padding(.bottom, 20)
        }

        Button(action: {
          if audioManager.isPlaying {
            audioManager.stopSound()
          } else {
            audioManager.playSound("mixkit-serene-anxious")
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

  private func startBreathingTextAnimation() {
    // Create a repeating timer for the breathing text
    Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { _ in
      // Fade out
      withAnimation {
        textOpacity = 0
      }

      // After fade out, change text and fade in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        breathingText = "Inhale... 2... 3..."
        withAnimation {
          textOpacity = 1
        }
      }

      // After 3 seconds, fade out again
      DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        withAnimation {
          textOpacity = 0
        }

        // After fade out, change text and fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          breathingText = "Exhale... 2... 3... 4..."
          withAnimation {
            textOpacity = 1
          }
        }
      }
    }
  }

  private func timeString(from timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }
}
