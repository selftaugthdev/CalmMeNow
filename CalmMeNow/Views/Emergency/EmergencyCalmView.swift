import SwiftUI

struct EmergencyCalmView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var audioManager = AudioManager.shared
  @StateObject private var progressTracker = ProgressTracker.shared
  @AppStorage("prefSounds") private var prefSounds = true
  @State private var isAnimating = false
  @State private var timeRemaining: Int = 60
  @State private var showCompletionOptions = false
  @State private var showSuccessView = false
  @State private var showAdditionalHelp = false
  @State private var sessionId: String = ""

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
            // Track early exit
            AnalyticsLogger.shared.emergencyCalmComplete(sessionId: sessionId, completed: false)
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
          // Large breathing cat
          ZStack {
            // Cat mascot for emergency calm
            CatMascot()
              .frame(width: 240, height: 240)
              .padding(.vertical, 30)

            // Breathing text overlay
            VStack {
              Spacer()
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
                HapticManager.shared.success()
                progressTracker.recordUsage()
                progressTracker.recordReliefOutcome(.betterNow)
                // Track successful completion
                AnalyticsLogger.shared.emergencyCalmComplete(sessionId: sessionId, completed: true)
                showSuccessView = true
              }
              .foregroundColor(.white)
              .padding(.vertical, 12)
              .padding(.horizontal, 24)
              .background(
                RoundedRectangle(cornerRadius: 20)
                  .fill(Color.green.opacity(0.8))
              )

              Button("I still need help") {
                HapticManager.shared.mediumImpact()
                progressTracker.recordReliefOutcome(.stillNeedHelp)
                // Track completion but still needing help
                AnalyticsLogger.shared.emergencyCalmComplete(sessionId: sessionId, completed: true)
                showAdditionalHelp = true
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
      audioManager.stopSoundImmediately()
    }
    .sheet(isPresented: $showSuccessView) {
      SuccessView(onReturnToHome: {
        presentationMode.wrappedValue.dismiss()
      })
    }
    .sheet(isPresented: $showAdditionalHelp) {
      AdditionalHelpView()
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

    // Start analytics tracking
    sessionId = AnalyticsLogger.shared.emergencyCalmStart(source: "emergency")

    // Start the emergency calming sound (only if sounds are enabled)
    if prefSounds {
      audioManager.playSound("perfect-beauty-1-min")
    }

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
