import SwiftUI

struct AdditionalHelpView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var audioManager = AudioManager.shared
  @StateObject private var progressTracker = ProgressTracker.shared
  @AppStorage("prefSounds") private var prefSounds = true
  @State private var selectedOption: HelpOption?
  @State private var showBubbleGame = false
  @State private var showBreathingExercise = false
  @State private var showJournaling = false

  // Completion handler to dismiss all the way back to home
  var onReturnHome: (() -> Void)?

  enum HelpOption: String, CaseIterable {
    case anotherSound = "Try another calming sound"
    case bubbleGame = "Play a relaxing game"
    case breathingExercise = "Do a breathing exercise"
    case journaling = "Write out what's bothering you"

    var emoji: String {
      switch self {
      case .anotherSound: return "🎧"
      case .bubbleGame: return "🫧"
      case .breathingExercise: return "🌬️"
      case .journaling: return "📝"
      }
    }

    var description: String {
      switch self {
      case .anotherSound: return "Listen to a different soothing sound"
      case .bubbleGame: return "Pop bubbles to release tension"
      case .breathingExercise: return "Follow guided breathing patterns"
      case .journaling: return "Express your thoughts and feelings"
      }
    }
  }

  var body: some View {
    ZStack {
      // Gentle background gradient
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "#A0C4FF"),  // Teal
          Color(hex: "#98D8C8"),  // Soft Mint
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 30) {
        // Header
        VStack(spacing: 16) {
          Text("No worries.")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.black)

          Text("Let's try something else to help you feel better.")
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.9))
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

        // Help options
        VStack(spacing: 16) {
          ForEach(HelpOption.allCases, id: \.self) { option in
            Button(action: {
              selectedOption = option
              handleOptionSelection(option)
            }) {
              HStack(spacing: 16) {
                Text(option.emoji)
                  .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                  Text(option.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)

                  Text(option.description)
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.7))
                }

                Spacer()

                Image(systemName: "chevron.right")
                  .font(.title3)
                  .foregroundColor(.black.opacity(0.5))
              }
              .padding(.horizontal, 20)
              .padding(.vertical, 16)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color.white.opacity(0.9))
              )
              .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(Color.black.opacity(0.1), lineWidth: 1)
              )
            }
            .buttonStyle(PlainButtonStyle())
          }
        }
        .padding(.horizontal, 20)

        Spacer()

        // Back to home option
        Button("Return to Home") {
          onReturnHome?() ?? presentationMode.wrappedValue.dismiss()
        }
        .foregroundColor(.black)
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.8))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 20)
            .stroke(Color.black.opacity(0.2), lineWidth: 1)
        )
        .padding(.bottom, 40)
      }
      .padding(.top, 60)
    }
    .navigationBarHidden(true)
    .sheet(isPresented: $showBubbleGame) {
      BubbleGameView()
    }
    .sheet(isPresented: $showBreathingExercise) {
      BreathingExerciseView()
    }
    .sheet(isPresented: $showJournaling) {
      JournalingView()
    }
  }

  private func handleOptionSelection(_ option: HelpOption) {
    progressTracker.recordStillNeedHelp(option: option.rawValue)

    switch option {
    case .anotherSound:
      // Play a different calming sound (only if sounds are enabled)
      if prefSounds {
        let sounds = [
          "ethereal-night-loop", "mixkit-serene-anxious", "mixkit-just-chill-angry",
          "mixkit-jazz-sad",
        ]
        let randomSound = sounds.randomElement() ?? "ethereal-night-loop"
        audioManager.playSound(randomSound)
      }

    case .bubbleGame:
      showBubbleGame = true

    case .breathingExercise:
      showBreathingExercise = true

    case .journaling:
      showJournaling = true
    }
  }
}

// MARK: - Placeholder Views (to be implemented later)

// JournalingView is now implemented in JournalingView.swift
