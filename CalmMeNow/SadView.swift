import SwiftUI

struct SadView: View {
  @StateObject private var audioManager = AudioManager.shared
  @State private var isHugging = false

  var body: some View {
    ZStack {
      // Background gradient
      LinearGradient(
        gradient: Gradient(colors: [
          Color(red: 0.95, green: 0.90, blue: 0.98),  // Lavender
          Color(red: 0.98, green: 0.85, blue: 0.90),  // Pink
          Color(red: 0.98, green: 0.95, blue: 0.90),  // Cream
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack {
        Spacer()

        // Hugging animation
        ZStack {
          // Left arm
          Circle()
            .trim(from: 0.5, to: 1.0)
            .stroke(Color.black.opacity(0.3), lineWidth: 8)
            .frame(width: 200, height: 200)
            .rotationEffect(.degrees(isHugging ? -30 : -10))
            .offset(x: -50)

          // Right arm
          Circle()
            .trim(from: 0, to: 0.5)
            .stroke(Color.black.opacity(0.3), lineWidth: 8)
            .frame(width: 200, height: 200)
            .rotationEffect(.degrees(isHugging ? 30 : 10))
            .offset(x: 50)

          // Heart
          Image(systemName: "heart.fill")
            .resizable()
            .frame(width: 60, height: 60)
            .foregroundColor(.pink.opacity(0.8))
            .scaleEffect(isHugging ? 1.2 : 1.0)
        }
        .animation(
          Animation.easeInOut(duration: 2)
            .repeatForever(autoreverses: true),
          value: isHugging
        )
        .onAppear {
          isHugging = true
        }

        // Calming text
        Text("It's okay to feel sad. Let's find comfort together.")
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
            audioManager.playSound("mixkit-jazz-sad")
          }
        }) {
          Text(audioManager.isPlaying ? "⏹ Stop" : "▶️ Start")
            .font(.title)
            .padding()
            .frame(maxWidth: .infinity)
            .background(audioManager.isPlaying ? Color.red.opacity(0.8) : Color.pink.opacity(0.8))
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
