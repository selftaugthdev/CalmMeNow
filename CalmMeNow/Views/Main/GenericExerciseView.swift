import SwiftUI

/// View for displaying and running non-breathing exercises (like stretches, movement, etc.)
struct GenericExerciseView: View {
  let exercise: Exercise
  @Environment(\.presentationMode) var presentationMode
  @State private var currentStep = 0
  @State private var isRunning = false
  @State private var timeRemaining: Int
  @State private var timer: Timer?
  @StateObject private var speechService = SpeechService()
  @AppStorage("prefVoice") private var voiceGuidanceEnabled = false
  @AppStorage("prefHaptics") private var hapticsEnabled = true

  // Haptic feedback
  let impactFeedback = UIImpactFeedbackGenerator(style: .light)

  init(exercise: Exercise) {
    self.exercise = exercise
    self._timeRemaining = State(initialValue: exercise.duration)
  }

  var body: some View {
    NavigationView {
      ZStack {
        // Calming gradient background
        LinearGradient(
          gradient: Gradient(colors: [
            Color.blue.opacity(0.1),
            Color.green.opacity(0.1),
            Color.mint.opacity(0.2),
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        ScrollView {
          VStack(spacing: 30) {
            // Exercise Title
            VStack(spacing: 12) {
              Text(exercise.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

              Text("\(exercise.duration) seconds")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.top, 20)

            if !isRunning {
              // Exercise Preview
              VStack(alignment: .leading, spacing: 16) {
                Text("Exercise Steps:")
                  .font(.headline)
                  .fontWeight(.semibold)

                ForEach(Array(exercise.steps.enumerated()), id: \.offset) { index, step in
                  HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                      .font(.headline)
                      .fontWeight(.bold)
                      .foregroundColor(.white)
                      .frame(width: 30, height: 30)
                      .background(Circle().fill(Color.blue))

                    Text(step)
                      .font(.body)
                      .foregroundColor(.primary)

                    Spacer()
                  }
                }
              }
              .padding(.horizontal, 20)
              .padding(.vertical, 16)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color(.systemBackground))
                  .shadow(radius: 2)
              )
              .padding(.horizontal, 20)

              // Voice guidance toggle
              HStack {
                Image(
                  systemName: voiceGuidanceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill"
                )
                .foregroundColor(voiceGuidanceEnabled ? .blue : .gray)

                Text("Voice guidance")
                  .font(.subheadline)
                  .foregroundColor(.primary)

                Spacer()

                Toggle("", isOn: $voiceGuidanceEnabled)
                  .toggleStyle(SwitchToggleStyle(tint: .blue))
              }
              .padding(.horizontal, 20)
              .padding(.vertical, 12)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color(.systemBackground))
                  .overlay(
                    RoundedRectangle(cornerRadius: 12)
                      .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                  )
              )
              .padding(.horizontal, 20)

              // Start Button
              Button(action: startExercise) {
                Text("Start Exercise")
                  .font(.headline)
                  .fontWeight(.semibold)
                  .foregroundColor(.white)
                  .padding(.horizontal, 32)
                  .padding(.vertical, 12)
                  .background(
                    RoundedRectangle(cornerRadius: 25)
                      .fill(Color.blue)
                  )
              }
              .padding(.top, 20)
            } else {
              // Exercise Running
              VStack(spacing: 30) {
                // Timer
                Text("\(timeRemaining)s")
                  .font(.system(size: 60, weight: .bold, design: .rounded))
                  .foregroundColor(.blue)

                // Current Step
                if currentStep < exercise.steps.count {
                  VStack(spacing: 16) {
                    Text("Step \(currentStep + 1)")
                      .font(.headline)
                      .foregroundColor(.secondary)

                    Text(exercise.steps[currentStep])
                      .font(.title2)
                      .fontWeight(.medium)
                      .foregroundColor(.primary)
                      .multilineTextAlignment(.center)
                      .padding(.horizontal, 20)
                  }
                  .padding(.vertical, 20)
                  .background(
                    RoundedRectangle(cornerRadius: 16)
                      .fill(Color(.systemBackground))
                      .shadow(radius: 4)
                  )
                  .padding(.horizontal, 20)
                }

                // Control Buttons
                HStack(spacing: 20) {
                  Button(action: previousStep) {
                    Image(systemName: "backward.fill")
                      .font(.title2)
                      .foregroundColor(.blue)
                  }
                  .disabled(currentStep == 0)

                  Button(action: stopExercise) {
                    Text("Stop")
                      .font(.headline)
                      .foregroundColor(.red)
                      .padding(.horizontal, 20)
                      .padding(.vertical, 8)
                      .background(
                        RoundedRectangle(cornerRadius: 12)
                          .stroke(Color.red, lineWidth: 2)
                      )
                  }

                  Button(action: nextStep) {
                    Image(systemName: "forward.fill")
                      .font(.title2)
                      .foregroundColor(.blue)
                  }
                  .disabled(currentStep >= exercise.steps.count - 1)
                }
              }
            }

            Spacer()
          }
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Close") {
            cleanup()
            presentationMode.wrappedValue.dismiss()
          }
        }
      }
    }
    .onDisappear {
      cleanup()
    }
  }

  // MARK: - Exercise Logic

  private func startExercise() {
    isRunning = true
    currentStep = 0
    timeRemaining = exercise.duration

    // Welcome message
    if voiceGuidanceEnabled {
      let welcomeMessage = "Starting \(exercise.title). Follow along with the steps."
      speechService.speak(welcomeMessage, rate: 0.4, pitch: 0.9)

      // Read first step after welcome
      DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        self.speakCurrentStep()
      }
    }

    // Start timer
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      if timeRemaining > 0 {
        timeRemaining -= 1
      } else {
        completeExercise()
      }
    }

    // Auto-advance steps based on duration
    if exercise.steps.count > 1 {
      let stepDuration = Double(exercise.duration) / Double(exercise.steps.count)
      autoAdvanceSteps(stepDuration: stepDuration)
    }
  }

  private func stopExercise() {
    cleanup()
    presentationMode.wrappedValue.dismiss()
  }

  private func completeExercise() {
    cleanup()

    if voiceGuidanceEnabled {
      speechService.speak("Exercise complete. Great job!", rate: 0.4, pitch: 0.9)
    }

    // Show completion for a moment, then dismiss
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      presentationMode.wrappedValue.dismiss()
    }
  }

  private func nextStep() {
    if currentStep < exercise.steps.count - 1 {
      currentStep += 1
      speakCurrentStep()

      if hapticsEnabled {
        impactFeedback.impactOccurred()
      }
    }
  }

  private func previousStep() {
    if currentStep > 0 {
      currentStep -= 1
      speakCurrentStep()

      if hapticsEnabled {
        impactFeedback.impactOccurred()
      }
    }
  }

  private func speakCurrentStep() {
    guard voiceGuidanceEnabled && currentStep < exercise.steps.count else { return }
    speechService.speak(exercise.steps[currentStep], rate: 0.4, pitch: 0.9)
  }

  private func autoAdvanceSteps(stepDuration: TimeInterval) {
    guard stepDuration > 0 else { return }

    for stepIndex in 1..<exercise.steps.count {
      DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(stepIndex)) {
        if self.isRunning && self.currentStep == stepIndex - 1 {
          self.nextStep()
        }
      }
    }
  }

  private func cleanup() {
    print("GenericExerciseView cleanup called")  // Debug logging

    isRunning = false
    timer?.invalidate()
    timer = nil

    // Stop speech service multiple times to be extra sure
    speechService.stop()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.speechService.stop()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      self.speechService.stop()
    }

    // Stop haptic feedback generation
    impactFeedback.prepare()  // Reset haptic engine

    // Reset state
    currentStep = 0
    timeRemaining = exercise.duration
  }
}

#Preview {
  GenericExerciseView(
    exercise: Exercise(
      id: UUID(),
      title: "Family Connection Stretch",
      duration: 90,
      steps: [
        "Sit comfortably and think of someone you love",
        "Take a deep breath and smile",
        "Stretch your arms wide as if giving them a hug",
        "Hold this position and feel the warmth",
        "Lower your arms and send them loving thoughts",
      ],
      prompt: "A gentle stretch exercise to connect with loved ones"
    ))
}
