import AVFoundation
import SwiftUI

struct EmergencyStepRunnerView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var speechService = SpeechService()
  private let hapticManager = HapticManager.shared

  let script: [String: Any]

  @State private var currentStepIndex = 0
  @State private var isActive = false
  @State private var showingCompletion = false
  @State private var showingGrounding = false
  @State private var showingCallHelp = false

  private var steps: [String] {
    if let plan = script["plan"] as? [String: Any],
      let steps = plan["steps"] as? [String]
    {
      return steps
    }
    return ["Take a deep breath", "Ground yourself", "You are safe"]
  }

  private var currentStep: String {
    guard currentStepIndex < steps.count else { return "" }
    return steps[currentStepIndex]
  }

  private var stepGuidanceText: String {
    let step = currentStep.lowercased()

    if step.contains("breathe") || step.contains("breath") {
      return
        "Follow the gentle rhythm of the circle. Inhale as it expands, exhale as it contracts. Focus on slow, deep breathing."
    } else if step.contains("ground") || step.contains("grounding") {
      return
        "Look around and name 5 things you see, 4 things you can touch, 3 things you hear, 2 things you smell, and 1 thing you taste. This helps bring you back to the present moment."
    } else if step.contains("calming phrase") || step.contains("phrase") {
      let userPhrase =
        UserDefaults.standard.string(forKey: "userCalmingPhrase")
        ?? "This feeling will pass, I am safe"
      return
        "Repeat your calming phrase silently or aloud 3 times: \"\(userPhrase)\". Feel the words bring you peace and safety."
    } else if step.contains("safe") || step.contains("safety") {
      return
        "You are safe right now. This feeling is temporary and will pass. You have the strength to get through this moment."
    } else {
      return
        "Take your time with this step. Focus on the instruction and allow yourself to feel calmer with each moment."
    }
  }

  private var stepIcon: String {
    let step = currentStep.lowercased()

    if step.contains("breathe") || step.contains("breath") {
      return "🫁"
    } else if step.contains("ground") || step.contains("grounding") {
      return "🌱"
    } else if step.contains("calming phrase") || step.contains("phrase") {
      return "💭"
    } else if step.contains("safe") || step.contains("safety") {
      return "🛡️"
    } else {
      return "📋"
    }
  }

  private var showStepVisuals: Bool {
    let step = currentStep.lowercased()
    return step.contains("ground") || step.contains("grounding") || step.contains("calming phrase")
      || step.contains("phrase")
  }

  @ViewBuilder
  private var stepVisualElements: some View {
    let step = currentStep.lowercased()

    if step.contains("ground") || step.contains("grounding") {
      // Grounding visual elements
      HStack(spacing: 20) {
        VStack(spacing: 4) {
          Text("👀")
            .font(.title2)
          Text("5 things")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        VStack(spacing: 4) {
          Text("✋")
            .font(.title2)
          Text("4 things")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        VStack(spacing: 4) {
          Text("👂")
            .font(.title2)
          Text("3 things")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        VStack(spacing: 4) {
          Text("👃")
            .font(.title2)
          Text("2 things")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        VStack(spacing: 4) {
          Text("👅")
            .font(.title2)
          Text("1 thing")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }
      .padding(.top, 8)
    } else if step.contains("calming phrase") || step.contains("phrase") {
      // Calming phrase visual
      let userPhrase =
        UserDefaults.standard.string(forKey: "userCalmingPhrase")
        ?? "This feeling will pass, I am safe"
      Text("\"\(userPhrase)\"")
        .font(.title3)
        .fontWeight(.medium)
        .foregroundColor(.blue)
        .italic()
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
  }

  var body: some View {
    ZStack {
      // Background gradient
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "#FFF5F5"),
          Color(hex: "#FEF2F2"),
          Color(hex: "#FEE2E2"),
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 30) {
        // Header
        VStack(spacing: 16) {
          Text("🚨")
            .font(.system(size: 50))

          Text("Emergency Plan")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.primary)

          Text("Step \(currentStepIndex + 1) of \(steps.count)")
            .font(.headline)
            .foregroundColor(.red)
        }
        .padding(.top, 40)

        Spacer()

        // Current Step Display
        VStack(spacing: 24) {
          ZStack {
            Circle()
              .stroke(Color.red.opacity(0.3), lineWidth: 6)
              .frame(width: 200, height: 200)

            Circle()
              .fill(Color.red.opacity(0.1))
              .frame(width: 200, height: 200)
              .scaleEffect(isActive ? 1.1 : 0.9)
              .animation(
                Animation.easeInOut(duration: 2.0)
                  .repeatForever(autoreverses: true),
                value: isActive
              )

            VStack(spacing: 16) {
              // Step-specific icon
              Text(stepIcon)
                .font(.system(size: 40))

              Text(currentStep)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .lineLimit(nil)

              // Step-specific visual elements
              if showStepVisuals {
                stepVisualElements
              }
            }
          }

          // Progress indicator
          ProgressView(value: Double(currentStepIndex), total: Double(steps.count - 1))
            .progressViewStyle(LinearProgressViewStyle(tint: .red))
            .padding(.horizontal, 40)

          // Step-specific guidance text
          if isActive {
            VStack(spacing: 8) {
              // Step-specific instructions
              Text(stepGuidanceText)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .lineLimit(nil)

              // General guidance
              Text("Take your time. Click 'Next' when ready.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            }
            .padding(.top, 8)
          }
        }

        Spacer()

        // Control Buttons
        VStack(spacing: 16) {
          if !isActive {
            Button(action: startPlan) {
              HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                  .font(.title2)
                Text("Start Emergency Plan")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              .foregroundColor(.white)
              .padding(.vertical, 16)
              .padding(.horizontal, 32)
              .background(
                RoundedRectangle(cornerRadius: 25)
                  .fill(Color.red)
              )
            }
          } else {
            // Navigation Controls - Top Row
            HStack(spacing: 12) {
              Button(action: previousStep) {
                HStack(spacing: 6) {
                  Image(systemName: "backward.fill")
                    .font(.system(size: 14))
                  Text("Prev")
                    .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(
                  RoundedRectangle(cornerRadius: 18)
                    .fill(Color.blue)
                )
              }
              .disabled(currentStepIndex == 0)

              Button(action: nextStep) {
                HStack(spacing: 6) {
                  Text("Next")
                    .font(.system(size: 14, weight: .medium))
                  Image(systemName: "forward.fill")
                    .font(.system(size: 14))
                }
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(
                  RoundedRectangle(cornerRadius: 18)
                    .fill(Color.green)
                )
              }
              .disabled(currentStepIndex == steps.count - 1)
            }

            // Repeat Button - Centered below
            Button(action: repeatStep) {
              HStack(spacing: 8) {
                Image(systemName: "repeat")
                  .font(.system(size: 16))
                Text("Repeat Step")
                  .font(.system(size: 16, weight: .medium))
              }
              .foregroundColor(.white)
              .padding(.vertical, 12)
              .padding(.horizontal, 24)
              .background(
                RoundedRectangle(cornerRadius: 20)
                  .fill(Color.orange)
              )
            }
          }

          // Emergency Shortcuts
          HStack(spacing: 12) {
            Button(action: { showingGrounding = true }) {
              HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                  .font(.system(size: 14))
                Text("Ground Me")
                  .font(.system(size: 14, weight: .medium))
              }
              .foregroundColor(.white)
              .padding(.vertical, 10)
              .padding(.horizontal, 16)
              .background(
                RoundedRectangle(cornerRadius: 18)
                  .fill(Color.green)
              )
            }

            Button(action: { showingCallHelp = true }) {
              HStack(spacing: 6) {
                Image(systemName: "phone.fill")
                  .font(.system(size: 14))
                Text("Call Help")
                  .font(.system(size: 14, weight: .medium))
              }
              .foregroundColor(.white)
              .padding(.vertical, 10)
              .padding(.horizontal, 16)
              .background(
                RoundedRectangle(cornerRadius: 18)
                  .fill(Color.blue)
              )
            }
          }

          if isActive {
            Button(action: endPlan) {
              HStack(spacing: 6) {
                Image(systemName: "stop.circle.fill")
                  .font(.system(size: 14))
                Text("End Plan")
                  .font(.system(size: 14, weight: .medium))
              }
              .foregroundColor(.white)
              .padding(.vertical, 10)
              .padding(.horizontal, 16)
              .background(
                RoundedRectangle(cornerRadius: 18)
                  .fill(Color.gray)
              )
            }
          }
        }
        .padding(.bottom, 40)
      }
      .padding(.horizontal, 20)
    }
    .navigationBarHidden(true)
    .onAppear {
      startPlan()
    }
    .onDisappear {
      stopPlan()
    }
    .sheet(isPresented: $showingCompletion) {
      EmergencyCompletionView {
        presentationMode.wrappedValue.dismiss()
      }
    }
    .sheet(isPresented: $showingGrounding) {
      GroundingExerciseView()
    }
    .sheet(isPresented: $showingCallHelp) {
      CallHelpView()
    }
  }

  private func startPlan() {
    isActive = true
    currentStepIndex = 0
    executeCurrentStep()
  }

  private func stopPlan() {
    isActive = false
    speechService.stopAll()
  }

  private func endPlan() {
    stopPlan()
    showingCompletion = true
  }

  private func nextStep() {
    if currentStepIndex < steps.count - 1 {
      currentStepIndex += 1
      executeCurrentStep()
    } else {
      endPlan()
    }
  }

  private func previousStep() {
    if currentStepIndex > 0 {
      currentStepIndex -= 1
      executeCurrentStep()
    }
  }

  private func repeatStep() {
    executeCurrentStep()
  }

  private func executeCurrentStep() {
    // Speak the instruction
    speechService.speak(currentStep, rate: 0.4, pitch: 0.9)

    // Soft haptic feedback
    hapticManager.lightImpact()

    // Check if this is a breathing step
    if currentStep.lowercased().contains("breathe") || currentStep.lowercased().contains("inhale")
      || currentStep.lowercased().contains("exhale")
    {
      // Stronger haptic for breathing cues
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        hapticManager.mediumImpact()
      }
    }
  }
}

// MARK: - Emergency Completion View

struct EmergencyCompletionView: View {
  let onDismiss: () -> Void

  var body: some View {
    VStack(spacing: 30) {
      Text("✅")
        .font(.system(size: 60))

      Text("Emergency Plan Complete!")
        .font(.title)
        .fontWeight(.bold)
        .foregroundColor(.primary)

      Text("You've successfully completed your emergency plan. How are you feeling now?")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)

      VStack(spacing: 16) {
        Button("I feel better") {
          onDismiss()
        }
        .foregroundColor(.white)
        .padding(.vertical, 12)
        .padding(.horizontal, 32)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(Color.green)
        )

        Button("I need more help") {
          onDismiss()
        }
        .foregroundColor(.blue)
        .padding(.vertical, 12)
        .padding(.horizontal, 32)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .stroke(Color.blue, lineWidth: 2)
        )
      }
    }
    .padding(40)
  }
}

// MARK: - Grounding Exercise View

struct GroundingExerciseView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var speechService = SpeechService()
  private let hapticManager = HapticManager.shared

  @State private var currentExercise = 0
  @State private var isActive = false

  private let groundingExercises = [
    "Name 5 things you can see",
    "Name 4 things you can touch",
    "Name 3 things you can hear",
    "Name 2 things you can smell",
    "Name 1 thing you can taste",
  ]

  var body: some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#E8F4FD"), Color(hex: "#F0F8FF")]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 30) {
        Text("🌱")
          .font(.system(size: 60))

        Text("Grounding Exercise")
          .font(.title)
          .fontWeight(.bold)

        Text(groundingExercises[currentExercise])
          .font(.title2)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 20)

        Spacer()

        HStack(spacing: 20) {
          Button("Previous") {
            if currentExercise > 0 {
              currentExercise -= 1
              speakCurrentExercise()
            }
          }
          .disabled(currentExercise == 0)

          Button("Next") {
            if currentExercise < groundingExercises.count - 1 {
              currentExercise += 1
              speakCurrentExercise()
            }
          }
          .disabled(currentExercise == groundingExercises.count - 1)
        }

        Button("Done") {
          presentationMode.wrappedValue.dismiss()
        }
        .foregroundColor(.white)
        .padding(.vertical, 12)
        .padding(.horizontal, 32)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(Color.blue)
        )
      }
      .padding(40)
    }
    .onAppear {
      speakCurrentExercise()
    }
  }

  private func speakCurrentExercise() {
    speechService.speak(groundingExercises[currentExercise])
    hapticManager.lightImpact()
  }
}

// MARK: - Call Help View

struct CallHelpView: View {
  @Environment(\.presentationMode) var presentationMode

  private let emergencyContacts = [
    ("Crisis Hotline", "988"),
    ("Emergency Services", "911"),
    ("Crisis Text Line", "Text HOME to 741741"),
  ]

  var body: some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#FFF5F5"), Color(hex: "#FEE2E2")]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 30) {
        Text("📞")
          .font(.system(size: 60))

        Text("Call for Help")
          .font(.title)
          .fontWeight(.bold)

        Text("These resources are available 24/7")
          .font(.body)
          .foregroundColor(.secondary)

        VStack(spacing: 16) {
          ForEach(emergencyContacts, id: \.0) { contact in
            Button(action: {
              if contact.1.contains("Text") {
                // Handle text line
                if let url = URL(string: "sms:741741&body=HOME") {
                  UIApplication.shared.open(url)
                }
              } else {
                // Handle phone call
                if let url = URL(string: "tel:\(contact.1)") {
                  UIApplication.shared.open(url)
                }
              }
            }) {
              HStack {
                VStack(alignment: .leading) {
                  Text(contact.0)
                    .font(.headline)
                    .foregroundColor(.primary)
                  Text(contact.1)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "phone.fill")
                  .foregroundColor(.blue)
              }
              .padding()
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color.white)
                  .shadow(color: .black.opacity(0.1), radius: 4)
              )
            }
          }
        }

        Button("Done") {
          presentationMode.wrappedValue.dismiss()
        }
        .foregroundColor(.white)
        .padding(.vertical, 12)
        .padding(.horizontal, 32)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(Color.blue)
        )
      }
      .padding(40)
    }
  }
}

#Preview {
  EmergencyStepRunnerView(script: [
    "plan": [
      "steps": [
        "Take a deep breath",
        "Ground yourself with 5-4-3-2-1",
        "You are safe and this will pass",
      ]
    ]
  ])
}
