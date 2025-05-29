import SwiftUI

struct FrustratedView: View {
  @StateObject private var audioManager = AudioManager.shared
  @State private var isPulsing = false

  var body: some View {
    ZStack {
      // Background gradient
      LinearGradient(
        gradient: Gradient(colors: [
          Color(red: 0.85, green: 0.95, blue: 0.85),  // Mint green
          Color(red: 0.70, green: 0.90, blue: 0.90),  // Teal blue
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack {
        Spacer()

        // Pulsing light
        Circle()
          .fill(Color.white.opacity(0.4))
          .frame(width: 250, height: 250)
          .scaleEffect(isPulsing ? 1.3 : 0.7)
          .animation(
            Animation.easeInOut(duration: 2.5)
              .repeatForever(autoreverses: true),
            value: isPulsing
          )
          .onAppear {
            isPulsing = true
          }

        // Calming text
        Text("Take a step back. Let's find clarity together.")
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
            .foregroundColor(.white)
            .padding(.bottom, 20)
        }

        Button(action: {
          if audioManager.isPlaying {
            audioManager.stopSound()
          } else {
            audioManager.playSound("perfect-beauty-1-min")
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

  private func timeString(from timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }
}
