import SwiftUI

struct EmergencyCalmView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var audioManager = AudioManager.shared
  @StateObject private var progressTracker = ProgressTracker.shared
  @State private var isAnimating = false
  @State private var timeRemaining: Int = 60
  @State private var showCompletionOptions = false
  @State private var showSuccessView = false

  var body: some View {
    ZStack {
      // Emergency calming background
      LinearGradient(
        gradient: Gradient(colors: [
          Color(red: 0.9, green: 0.95, blue: 1.0),
          Color(red: 0.85, green: 0.9, blue: 0.95),
          Color(red: 0.8, green: 0.85, blue: 0.9),
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack {
        // Header with exit option
        HStack {
          Button("Exit") {
            audioManager.stopSound()
            presentationMode.wrappedValue.dismiss()
          }
          .foregroundColor(.black)
          .padding()

          Spacer()

          if timeRemaining > 0 {
            Text("\(timeRemaining)s")
              .font(.title2)
              .fontWeight(.bold)
              .foregroundColor(.black)
              .padding()
          }
        }

        Spacer()

        // Emergency calming content
        VStack(spacing: 40) {
          // Large breathing circle
          ZStack {
            // Outer calming circle
            Circle()
              .stroke(Color.blue.opacity(0.3), lineWidth: 4)
              .frame(width: 320, height: 320)

            // Breathing circle
            Circle()
              .fill(
                LinearGradient(
                  gradient: Gradient(colors: [
                    Color.blue.opacity(0.6),
                    Color.purple.opacity(0.4),
                  ]),
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .frame(width: 240, height: 240)
              .scaleEffect(isAnimating ? 1.4 : 0.8)
              .animation(
                Animation.easeInOut(duration: 5)
                  .repeatForever(autoreverses: true),
                value: isAnimating
              )

            // Breathing text
            Text(breathingText)
              .font(.largeTitle)
              .fontWeight(.bold)
              .foregroundColor(.black)
              .opacity(isAnimating ? 1.0 : 0.8)
              .animation(
                Animation.easeInOut(duration: 2.5)
                  .repeatForever(autoreverses: true),
                value: isAnimating
              )
              .padding(.horizontal, 20)
              .padding(.vertical, 12)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color.white.opacity(0.9))
              )
          }

          // Emergency calming message
          VStack(spacing: 16) {
            Text("Emergency Calm")
              .font(.title)
              .fontWeight(.bold)
              .foregroundColor(.black)

            Text("You're safe. Focus on your breath. This moment will pass.")
              .font(.title2)
              .fontWeight(.medium)
              .foregroundColor(.black)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 40)
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 16)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(Color.white.opacity(0.9))
          )
        }

        Spacer()

        // Bottom controls
        if showCompletionOptions {
          VStack(spacing: 16) {
            Text("How are you feeling?")
              .font(.title3)
              .fontWeight(.medium)
              .foregroundColor(.black)
              .padding(.horizontal, 16)
              .padding(.vertical, 8)
              .background(
                RoundedRectangle(cornerRadius: 8)
                  .fill(Color.white.opacity(0.9))
              )

            HStack(spacing: 20) {
              Button("Better now") {
                progressTracker.recordUsage()
                showSuccessView = true
              }
              .foregroundColor(.white)
              .padding(.vertical, 12)
              .padding(.horizontal, 24)
              .background(
                RoundedRectangle(cornerRadius: 20)
                  .fill(Color.green.opacity(0.8))
              )

              Button("Need more help") {
                presentationMode.wrappedValue.dismiss()
              }
              .foregroundColor(.white)
              .padding(.vertical, 12)
              .padding(.horizontal, 24)
              .background(
                RoundedRectangle(cornerRadius: 20)
                  .fill(Color.blue.opacity(0.8))
              )
            }
          }
          .padding(.bottom, 40)
        }
      }
    }
    .onAppear {
      startEmergencyCalm()
    }
    .onDisappear {
      audioManager.stopSound()
    }
    .sheet(isPresented: $showSuccessView) {
      SuccessView(onReturnToHome: {
        presentationMode.wrappedValue.dismiss()
      })
    }
  }

  // MARK: - Computed Properties

  private var breathingText: String {
    let prompts = ["Breathe in...", "Hold...", "Breathe out..."]
    let index = (timeRemaining / 2) % prompts.count
    return prompts[index]
  }

  // MARK: - Helper Functions

  private func startEmergencyCalm() {
    isAnimating = true
    progressTracker.recordUsage()

    // Start the emergency calming sound
    audioManager.playSound("perfect-beauty-1-min")

    // Start countdown timer
    startCountdown()
  }

  private func startCountdown() {
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
      if timeRemaining > 0 {
        timeRemaining -= 1
      } else {
        timer.invalidate()
        showCompletionOptions = true
        audioManager.stopSound()
      }
    }
  }
}
