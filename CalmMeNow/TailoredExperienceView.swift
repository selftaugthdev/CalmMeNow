import SwiftUI

struct TailoredExperienceView: View {
  let emotion: String
  let intensity: IntensityLevel
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var audioManager = AudioManager.shared
  @StateObject private var progressTracker = ProgressTracker.shared
  @State private var isAnimating = false
  @State private var showCompletionOptions = false
  @State private var timeRemaining: Int = 60

  var body: some View {
    ZStack {
      // Background based on intensity
      backgroundGradient
        .ignoresSafeArea()

      VStack {
        // Header with exit option
        HStack {
          Button("Exit") {
            audioManager.stopSound()
            presentationMode.wrappedValue.dismiss()
          }
          .foregroundColor(.white)
          .padding()

          Spacer()

          if timeRemaining > 0 {
            Text("\(timeRemaining)s")
              .font(.title2)
              .fontWeight(.bold)
              .foregroundColor(.white)
              .padding()
          }
        }

        Spacer()

        // Main content based on intensity
        if intensity == .mild {
          mildExperience
        } else {
          severeExperience
        }

        Spacer()

        // Bottom controls
        if showCompletionOptions {
          completionOptions
        }
      }
    }
    .onAppear {
      startExperience()
    }
    .onDisappear {
      audioManager.stopSound()
    }
  }

  // MARK: - Background Gradients

  private var backgroundGradient: LinearGradient {
    switch emotion.lowercased() {
    case "anxious":
      return LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "#B5D8F6"),
          Color(hex: "#D7CFF5"),
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    case "angry":
      return LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "#FF6B6B"),
          Color(hex: "#4ECDC4"),
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    case "sad":
      return LinearGradient(
        gradient: Gradient(colors: [
          Color(red: 0.95, green: 0.90, blue: 0.98),
          Color(red: 0.98, green: 0.85, blue: 0.90),
          Color(red: 0.98, green: 0.95, blue: 0.90),
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    case "frustrated":
      return LinearGradient(
        gradient: Gradient(colors: [
          Color(red: 0.85, green: 0.95, blue: 0.85),
          Color(red: 0.70, green: 0.90, blue: 0.90),
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    default:
      return LinearGradient(
        gradient: Gradient(colors: [Color.blue, Color.purple]),
        startPoint: .top,
        endPoint: .bottom
      )
    }
  }

  // MARK: - Mild Experience

  private var mildExperience: some View {
    VStack(spacing: 40) {
      // Breathing bubble animation
      Circle()
        .fill(Color.white.opacity(0.3))
        .frame(width: 200, height: 200)
        .scaleEffect(isAnimating ? 1.2 : 0.8)
        .animation(
          Animation.easeInOut(duration: 4)
            .repeatForever(autoreverses: true),
          value: isAnimating
        )

      // Instructions
      Text(mildInstructions)
        .font(.title2)
        .fontWeight(.medium)
        .foregroundColor(.black)  // Darker text for better readability
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.8))
            .padding(.horizontal, 20)
        )

      // Tap to slow game
      Button(action: {
        // Simple tap interaction
        withAnimation(.easeInOut(duration: 0.3)) {
          // Visual feedback
        }
      }) {
        Text("Tap to slow down")
          .font(.title3)
          .fontWeight(.semibold)
          .foregroundColor(.white)
          .padding(.vertical, 16)
          .padding(.horizontal, 32)
          .background(
            RoundedRectangle(cornerRadius: 25)
              .fill(Color.black.opacity(0.6))
          )
      }
    }
  }

  // MARK: - Severe Experience

  private var severeExperience: some View {
    VStack(spacing: 30) {
      // Large breathing visual
      ZStack {
        // Outer circle
        Circle()
          .stroke(Color.white.opacity(0.3), lineWidth: 3)
          .frame(width: 300, height: 300)

        // Breathing circle
        Circle()
          .fill(Color.white.opacity(0.6))
          .frame(width: 200, height: 200)
          .scaleEffect(isAnimating ? 1.3 : 0.7)
          .animation(
            Animation.easeInOut(duration: 6)
              .repeatForever(autoreverses: true),
            value: isAnimating
          )

        // Breathing text
        Text(breathingText)
          .font(.title)
          .fontWeight(.bold)
          .foregroundColor(.black)  // Darker text
          .opacity(isAnimating ? 1.0 : 0.7)
          .animation(
            Animation.easeInOut(duration: 3)
              .repeatForever(autoreverses: true),
            value: isAnimating
          )
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.white.opacity(0.8))
              .padding(.horizontal, 10)
          )
      }

      // Grounding message
      Text(severeInstructions)
        .font(.title2)
        .fontWeight(.medium)
        .foregroundColor(.black)  // Darker text for better readability
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.8))
            .padding(.horizontal, 20)
        )
    }
  }

  // MARK: - Completion Options

  private var completionOptions: some View {
    VStack(spacing: 16) {
      Text("How are you feeling now?")
        .font(.title3)
        .fontWeight(.medium)
        .foregroundColor(.black)  // Darker text
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.8))
            .padding(.horizontal, 10)
        )

      HStack(spacing: 20) {
        Button("I feel better") {
          progressTracker.recordUsage()
          presentationMode.wrappedValue.dismiss()
        }
        .foregroundColor(.white)
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(Color.green.opacity(0.8))
        )

        Button("Try something else") {
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

  // MARK: - Computed Properties

  private var mildInstructions: String {
    switch emotion.lowercased() {
    case "anxious":
      return "Take gentle breaths. You're safe here."
    case "angry":
      return "Feel the tension release with each breath."
    case "sad":
      return "It's okay to feel this way. You're not alone."
    case "frustrated":
      return "Step back and find your center."
    default:
      return "Breathe deeply and find your calm."
    }
  }

  private var severeInstructions: String {
    switch emotion.lowercased() {
    case "anxious":
      return "You're safe. Focus on your breath. This will pass."
    case "angry":
      return "Let the anger flow through you. Don't hold onto it."
    case "sad":
      return "Your feelings are valid. Let them be without judgment."
    case "frustrated":
      return "This moment is temporary. Find your inner strength."
    default:
      return "Stay present. This too shall pass."
    }
  }

  private var breathingText: String {
    // Cycle through breathing prompts
    let prompts = ["Breathe in...", "Hold...", "Breathe out..."]
    let index = (timeRemaining / 2) % prompts.count
    return prompts[index]
  }

  // MARK: - Helper Functions

  private func startExperience() {
    isAnimating = true
    progressTracker.recordUsage()

    // Start audio based on emotion and intensity
    let soundName = getSoundForExperience()
    audioManager.playSound(soundName)

    // Start countdown timer
    startCountdown()
  }

  private func getSoundForExperience() -> String {
    switch emotion.lowercased() {
    case "anxious":
      return "mixkit-serene-anxious"
    case "angry":
      return "mixkit-just-chill-angry"
    case "sad":
      return "mixkit-jazz-sad"
    case "frustrated":
      return "perfect-beauty-1-min"
    default:
      return "perfect-beauty-1-min"
    }
  }

  private func startCountdown() {
    let duration = intensity == .mild ? 60 : 90  // Longer for severe

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
