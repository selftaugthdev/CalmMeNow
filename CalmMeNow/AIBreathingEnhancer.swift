//
//  AIBreathingEnhancer.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import Foundation
import SwiftUI

class AIBreathingEnhancer: ObservableObject {
  static let shared = AIBreathingEnhancer()

  @Published var isGeneratingInstructions = false
  @Published var personalizedInstructions: String?
  @Published var lastError: String?

  private let openAIService = OpenAIService.shared

  private init() {}

  // MARK: - AI-Enhanced Breathing Instructions

  /// Generate personalized breathing instructions based on user's current emotional state
  func generatePersonalizedBreathingInstructions(
    for emotion: String,
    intensity: String,
    breathingType: BreathingType = .calming
  ) async {
    // AI is automatically configured - no user setup needed

    await MainActor.run {
      self.isGeneratingInstructions = true
      self.lastError = nil
    }

    do {
      let instructions = try await openAIService.generateBreathingInstructions(for: emotion)

      await MainActor.run {
        self.personalizedInstructions = instructions
        self.isGeneratingInstructions = false
      }
    } catch {
      await MainActor.run {
        self.lastError = error.localizedDescription
        self.personalizedInstructions = getDefaultInstructions(for: breathingType)
        self.isGeneratingInstructions = false
      }
    }
  }

  /// Generate breathing pattern based on emotional intensity
  func generateBreathingPattern(for intensity: String) -> AIBreathingPattern {
    switch intensity.lowercased() {
    case "mild", "low":
      return AIBreathingPattern(inhale: 4, hold: 4, exhale: 6, cycles: 5)
    case "moderate":
      return AIBreathingPattern(inhale: 4, hold: 6, exhale: 8, cycles: 6)
    case "high", "severe":
      return AIBreathingPattern(inhale: 3, hold: 5, exhale: 7, cycles: 8)
    default:
      return AIBreathingPattern(inhale: 4, hold: 4, exhale: 6, cycles: 5)
    }
  }

  /// Generate motivational breathing cues
  func generateBreathingCues(for emotion: String) async -> [String] {

    do {
      let prompt = """
        You are a breathing exercise coach. The user is feeling \(emotion).
        Generate 3-4 short, encouraging phrases (under 5 words each) to use during breathing exercises.
        Focus on calm, supportive language. Separate each phrase with a newline.
        """

      let response = try await openAIService.sendMessage(
        "I need breathing cues", systemPrompt: prompt)
      let cues = response.components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

      return cues.isEmpty ? getDefaultBreathingCues() : cues
    } catch {
      return getDefaultBreathingCues()
    }
  }

  // MARK: - Fallback Methods

  private func getDefaultInstructions(for type: BreathingType) -> String {
    switch type {
    case .calming:
      return
        "Take slow, deep breaths. Inhale for 4 counts, hold for 4, exhale for 6. Focus on the rhythm of your breath."
    case .energizing:
      return
        "Take quick, energizing breaths. Inhale for 2 counts, exhale for 2. Feel the energy flowing through you."
    case .grounding:
      return
        "Breathe deeply and feel your feet on the ground. Inhale for 5, hold for 3, exhale for 7. Stay present."
    case .sleep:
      return
        "Take slow, gentle breaths. Inhale for 4, hold for 7, exhale for 8. Let each breath relax you deeper."
    }
  }

  private func getDefaultBreathingCues() -> [String] {
    return [
      "Breathe in peace",
      "Let go of tension",
      "You're doing great",
      "Stay with your breath",
      "Feel the calm",
    ]
  }
}

// MARK: - Supporting Models

enum BreathingType {
  case calming
  case energizing
  case grounding
  case sleep
}

struct AIBreathingPattern {
  let inhale: Int
  let hold: Int
  let exhale: Int
  let cycles: Int

  var totalDuration: Int {
    return (inhale + hold + exhale) * cycles
  }

  var description: String {
    return "Inhale for \(inhale), hold for \(hold), exhale for \(exhale). Repeat \(cycles) times."
  }
}

// MARK: - AI-Enhanced Breathing View

struct AIEnhancedBreathingView: View {
  @StateObject private var breathingEnhancer = AIBreathingEnhancer.shared
  @State private var selectedEmotion = ""
  @State private var selectedIntensity = ""
  @State private var showingEmotionSelector = false
  @State private var breathingPattern: AIBreathingPattern?

  private let emotions = ["Anxious", "Stressed", "Overwhelmed", "Sad", "Angry", "Panicked"]
  private let intensities = ["Mild", "Moderate", "High", "Severe"]

  var body: some View {
    VStack(spacing: 24) {
      // Header
      VStack(spacing: 12) {
        Text("🧘‍♀️")
          .font(.system(size: 50))

        Text("AI-Enhanced Breathing")
          .font(.title)
          .fontWeight(.bold)
          .foregroundColor(.primary)

        Text("Get personalized breathing guidance based on how you're feeling")
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 20)
      }

      // Emotion Selection
      VStack(spacing: 16) {
        Text("How are you feeling right now?")
          .font(.headline)
          .foregroundColor(.primary)

        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
          ForEach(emotions, id: \.self) { emotion in
            Button(action: {
              selectedEmotion = emotion
              showingEmotionSelector = true
            }) {
              Text(emotion)
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                  RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.8))
                )
                .overlay(
                  RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
            }
          }
        }
      }
      .padding(.horizontal, 20)

      // AI is automatically configured - no user setup needed

      // Generated Instructions
      if let instructions = breathingEnhancer.personalizedInstructions {
        VStack(spacing: 12) {
          Text("Your Personalized Breathing Guide")
            .font(.headline)
            .foregroundColor(.primary)

          Text(instructions)
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding()
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.9))
            )
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
      }

      // Breathing Pattern
      if let pattern = breathingPattern {
        VStack(spacing: 12) {
          Text("Recommended Pattern")
            .font(.headline)
            .foregroundColor(.primary)

          Text(pattern.description)
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding()
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
            )
        }
        .padding(.horizontal, 20)
      }

      Spacer()
    }
    .padding(.top, 20)
    .sheet(isPresented: $showingEmotionSelector) {
      IntensitySelectionSheet(
        emotion: selectedEmotion,
        onIntensitySelected: { intensity in
          selectedIntensity = intensity
          showingEmotionSelector = false
          generateBreathingGuidance(emotion: selectedEmotion, intensity: intensity)
        }
      )
    }
  }

  private func generateBreathingGuidance(emotion: String, intensity: String) {
    // Generate AI instructions
    Task {
      await breathingEnhancer.generatePersonalizedBreathingInstructions(
        for: emotion,
        intensity: intensity
      )
    }

    // Generate breathing pattern
    breathingPattern = breathingEnhancer.generateBreathingPattern(for: intensity)
  }
}

#Preview {
  AIEnhancedBreathingView()
}
