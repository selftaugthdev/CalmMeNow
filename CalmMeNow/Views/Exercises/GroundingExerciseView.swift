//
//  GroundingExerciseView.swift
//  CalmMeNow
//
//  5-4-3-2-1 Grounding Technique
//

import SwiftUI

struct GroundingStep: Identifiable {
  let id = UUID()
  let count: Int
  let sense: String
  let emoji: String
  let prompt: String
  let voicePrompt: String
}

struct GroundingExerciseView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var speechService = SpeechService()
  @AppStorage("prefVoice") private var voiceGuidanceEnabled = false
  @AppStorage("prefHaptics") private var hapticsEnabled = true

  @State private var currentStepIndex = 0
  @State private var isAnimating = false
  @State private var showCompletion = false
  @State private var stepProgress: CGFloat = 0

  private let steps: [GroundingStep] = [
    GroundingStep(
      count: 5,
      sense: "SEE",
      emoji: "👁️",
      prompt: "Name 5 things you can SEE",
      voicePrompt: "Look around you. Name five things you can see."
    ),
    GroundingStep(
      count: 4,
      sense: "HEAR",
      emoji: "👂",
      prompt: "Name 4 things you can HEAR",
      voicePrompt: "Listen carefully. Name four things you can hear."
    ),
    GroundingStep(
      count: 3,
      sense: "TOUCH",
      emoji: "✋",
      prompt: "Name 3 things you can TOUCH",
      voicePrompt: "Feel around you. Name three things you can touch."
    ),
    GroundingStep(
      count: 2,
      sense: "SMELL",
      emoji: "👃",
      prompt: "Name 2 things you can SMELL",
      voicePrompt: "Breathe in gently. Name two things you can smell."
    ),
    GroundingStep(
      count: 1,
      sense: "TASTE",
      emoji: "👅",
      prompt: "Name 1 thing you can TASTE",
      voicePrompt: "Finally, name one thing you can taste."
    ),
  ]

  var body: some View {
    ZStack {
      // Calming gradient background
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "#E8F4F8"),
          Color(hex: "#B8D4E3"),
          Color(hex: "#7FB3D3"),
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 0) {
        // Header
        HStack {
          Button(action: {
            cleanup()
            presentationMode.wrappedValue.dismiss()
          }) {
            Image(systemName: "xmark.circle.fill")
              .font(.title2)
              .foregroundColor(.gray)
          }

          Spacer()

          Text("5-4-3-2-1 Grounding")
            .font(.headline)
            .foregroundColor(.primary)

          Spacer()

          // Placeholder for alignment
          Image(systemName: "xmark.circle.fill")
            .font(.title2)
            .foregroundColor(.clear)
        }
        .padding()

        if showCompletion {
          completionView
        } else {
          exerciseContent
        }
      }
    }
    .onAppear {
      startExercise()
    }
    .onDisappear {
      cleanup()
    }
  }

  // MARK: - Exercise Content

  private var exerciseContent: some View {
    VStack(spacing: 30) {
      Spacer()

      // Progress dots
      HStack(spacing: 12) {
        ForEach(0..<steps.count, id: \.self) { index in
          Circle()
            .fill(index <= currentStepIndex ? Color.blue : Color.gray.opacity(0.3))
            .frame(width: index == currentStepIndex ? 14 : 10, height: index == currentStepIndex ? 14 : 10)
            .animation(.easeInOut(duration: 0.3), value: currentStepIndex)
        }
      }
      .padding(.top, 20)

      Spacer()

      // Current step display
      VStack(spacing: 24) {
        // Large emoji with count badge
        ZStack(alignment: .topTrailing) {
          Text(steps[currentStepIndex].emoji)
            .font(.system(size: 100))
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .animation(
              Animation.easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true),
              value: isAnimating
            )

          // Count badge
          ZStack {
            Circle()
              .fill(Color.blue)
              .frame(width: 50, height: 50)

            Text("\(steps[currentStepIndex].count)")
              .font(.title)
              .fontWeight(.bold)
              .foregroundColor(.white)
          }
          .offset(x: 10, y: -10)
        }

        // Sense label
        Text(steps[currentStepIndex].sense)
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundColor(.primary)

        // Prompt
        Text(steps[currentStepIndex].prompt)
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(.primary.opacity(0.8))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)
      }
      .padding(.vertical, 30)
      .padding(.horizontal, 20)
      .background(
        RoundedRectangle(cornerRadius: 24)
          .fill(Color.white.opacity(0.9))
          .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
      )
      .padding(.horizontal, 30)

      Spacer()

      // Instruction text
      Text("Take your time. When you're ready, tap Next.")
        .font(.subheadline)
        .foregroundColor(.primary.opacity(0.6))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)

      // Next button
      Button(action: {
        advanceStep()
      }) {
        HStack {
          Text(currentStepIndex == steps.count - 1 ? "Complete" : "Next")
            .font(.headline)
            .fontWeight(.semibold)

          Image(systemName: currentStepIndex == steps.count - 1 ? "checkmark.circle.fill" : "arrow.right.circle.fill")
        }
        .foregroundColor(.white)
        .padding(.vertical, 16)
        .padding(.horizontal, 48)
        .background(
          RoundedRectangle(cornerRadius: 30)
            .fill(Color.blue)
        )
        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
      }
      .padding(.bottom, 40)

      Spacer()
    }
  }

  // MARK: - Completion View

  private var completionView: some View {
    VStack(spacing: 40) {
      Spacer()

      // Success animation
      ZStack {
        Circle()
          .fill(Color.green.opacity(0.2))
          .frame(width: 180, height: 180)
          .scaleEffect(isAnimating ? 1.2 : 1.0)
          .animation(
            Animation.easeInOut(duration: 2)
              .repeatForever(autoreverses: true),
            value: isAnimating
          )

        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 100))
          .foregroundColor(.green)
      }

      VStack(spacing: 16) {
        Text("Well Done!")
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundColor(.primary)

        Text("You've completed the grounding exercise.")
          .font(.title3)
          .foregroundColor(.primary.opacity(0.8))
          .multilineTextAlignment(.center)

        Text("You are present. You are safe.")
          .font(.body)
          .foregroundColor(.primary.opacity(0.6))
          .multilineTextAlignment(.center)
      }
      .padding(.horizontal, 40)

      Spacer()

      // Return button
      Button(action: {
        presentationMode.wrappedValue.dismiss()
      }) {
        Text("Return to Home")
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(.white)
          .padding(.vertical, 16)
          .padding(.horizontal, 48)
          .background(
            RoundedRectangle(cornerRadius: 30)
              .fill(Color.blue)
          )
          .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
      }
      .padding(.bottom, 60)
    }
  }

  // MARK: - Helper Methods

  private func startExercise() {
    isAnimating = true

    // Track grounding exercise access
    FirebaseAnalyticsService.shared.trackEmotionSelected(emotion: "grounding_exercise")

    // Speak introduction if voice is enabled
    if voiceGuidanceEnabled {
      let intro =
        "Let's ground yourself using your five senses. Take your time with each step."
      speechService.speak(intro, rate: 0.45, pitch: 1.0)

      // Speak first step after intro
      DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
        speakCurrentStep()
      }
    }

    if hapticsEnabled {
      HapticManager.shared.mediumImpact()
    }
  }

  private func advanceStep() {
    if hapticsEnabled {
      HapticManager.shared.lightImpact()
    }

    if currentStepIndex < steps.count - 1 {
      withAnimation(.easeInOut(duration: 0.3)) {
        currentStepIndex += 1
      }

      if voiceGuidanceEnabled {
        speakCurrentStep()
      }
    } else {
      // Complete the exercise
      withAnimation(.easeInOut(duration: 0.5)) {
        showCompletion = true
      }

      if hapticsEnabled {
        HapticManager.shared.success()
      }

      if voiceGuidanceEnabled {
        speechService.speak(
          "Excellent. You've completed the grounding exercise. You are present and safe.",
          rate: 0.45, pitch: 1.0)
      }
    }
  }

  private func speakCurrentStep() {
    speechService.speak(steps[currentStepIndex].voicePrompt, rate: 0.45, pitch: 1.0)
  }

  private func cleanup() {
    speechService.stopAll()
    isAnimating = false
  }
}

#Preview {
  GroundingExerciseView()
}
