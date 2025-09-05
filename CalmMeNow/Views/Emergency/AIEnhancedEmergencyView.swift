//
//  AIEnhancedEmergencyView.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import SwiftUI

struct AIEnhancedEmergencyView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var audioManager = AudioManager.shared
  @StateObject private var progressTracker = ProgressTracker.shared
  @StateObject private var openAIService = OpenAIService.shared
  @AppStorage("prefSounds") private var prefSounds = true

  @State private var currentMessage = ""
  @State private var messages: [CompanionMessage] = []
  @State private var isTyping = false
  @State private var showingCrisisResources = false
  @State private var showingBreathingGuide = false
  @State private var selectedEmotion = ""
  @State private var selectedIntensity = ""
  @State private var showingEmotionSelector = false

  private let emotions = [
    "Anxious", "Stressed", "Overwhelmed", "Sad", "Angry", "Panicked", "Lonely", "Frustrated",
  ]
  private let intensities = ["Mild", "Moderate", "High", "Severe"]

  var body: some View {
    NavigationView {
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

        VStack(spacing: 0) {
          // Header
          VStack(spacing: 12) {
            Text("🤖")
              .font(.system(size: 50))

            Text("AI Emergency Companion")
              .font(.title)
              .fontWeight(.bold)
              .foregroundColor(.primary)

            Text("I'm here to help you through this moment with personalized guidance")
              .font(.body)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 20)
          }
          .padding(.top, 20)
          .padding(.bottom, 20)

          // AI is automatically configured - no user setup needed

          // Messages
          ScrollViewReader { proxy in
            ScrollView {
              LazyVStack(spacing: 16) {
                // Welcome message
                if messages.isEmpty {
                  CompanionMessageView(
                    message: CompanionMessage(
                      id: UUID().uuidString,
                      text:
                        "Hi there! I'm your AI companion here to help you through this difficult moment. How are you feeling right now?",
                      isFromUser: false,
                      timestamp: Date()
                    )
                  )
                }

                // Existing messages
                ForEach(messages) { message in
                  CompanionMessageView(message: message)
                }

                // Typing indicator
                if isTyping {
                  HStack {
                    Text("🤖")
                      .font(.title2)

                    HStack(spacing: 4) {
                      ForEach(0..<3) { index in
                        Circle()
                          .fill(Color.gray.opacity(0.6))
                          .frame(width: 8, height: 8)
                          .scaleEffect(isTyping ? 1.2 : 0.8)
                          .animation(
                            Animation.easeInOut(duration: 0.6)
                              .repeatForever()
                              .delay(Double(index) * 0.2),
                            value: isTyping
                          )
                      }
                    }

                    Spacer()
                  }
                  .padding(.horizontal, 20)
                }
              }
              .padding(.horizontal, 20)
              .padding(.bottom, 100)  // Space for input
            }
            .onChange(of: messages.count) { _ in
              withAnimation {
                proxy.scrollTo(messages.last?.id, anchor: .bottom)
              }
            }
          }

          // Quick Emotion Selection (AI Enhanced)
          if messages.isEmpty {
            VStack(spacing: 12) {
              Text("Quick Start - How are you feeling?")
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
            .padding(.bottom, 20)
          }

          // Input area
          VStack(spacing: 12) {
            HStack(spacing: 12) {
              TextField("Type your message...", text: $currentMessage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isTyping)

              Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                  .foregroundColor(.white)
                  .padding(12)
                  .background(
                    Circle()
                      .fill(currentMessage.isEmpty ? Color.gray : Color.blue)
                  )
              }
              .disabled(currentMessage.isEmpty || isTyping)
            }
            .padding(.horizontal, 20)

            // Quick action buttons
            HStack(spacing: 16) {
              Button(action: { showingBreathingGuide = true }) {
                HStack {
                  Image(systemName: "lungs.fill")
                  Text("Breathing")
                }
                .font(.caption)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                  RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.8))
                )
              }

              Button(action: { showingCrisisResources = true }) {
                HStack {
                  Image(systemName: "phone.fill")
                  Text("Crisis Help")
                }
                .font(.caption)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                  RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.8))
                )
              }
            }
          }
          .padding(.bottom, 20)
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarBackButtonHidden(true)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Close") {
            presentationMode.wrappedValue.dismiss()
          }
        }
      }
    }
    .sheet(isPresented: $showingEmotionSelector) {
      IntensitySelectionSheet(
        emotion: selectedEmotion,
        onIntensitySelected: { intensity in
          selectedIntensity = intensity
          showingEmotionSelector = false
          generateAICalmingAdvice(emotion: selectedEmotion, intensity: intensity)
        }
      )
    }
    .sheet(isPresented: $showingBreathingGuide) {
      BreathingExerciseView()
    }
    .sheet(isPresented: $showingCrisisResources) {
      CrisisResourcesView()
    }
  }

  // MARK: - Private Methods
  private func sendMessage() {
    guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

    let userMessage = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
    let message = CompanionMessage(
      id: UUID().uuidString,
      text: userMessage,
      isFromUser: true,
      timestamp: Date()
    )

    messages.append(message)
    currentMessage = ""

    // Generate AI response
    generateAIResponse(to: userMessage)
  }

  private func generateAICalmingAdvice(emotion: String, intensity: String) {
    isTyping = true

    Task {
      do {
        let advice = try await openAIService.generateCalmingAdvice(
          for: emotion, intensity: intensity)

        await MainActor.run {
          let aiMessage = CompanionMessage(
            id: UUID().uuidString,
            text:
              "I understand you're feeling \(emotion.lowercased()) with \(intensity.lowercased()) intensity. \(advice)",
            isFromUser: false,
            timestamp: Date()
          )
          messages.append(aiMessage)
          isTyping = false
        }
      } catch {
        await MainActor.run {
          let fallbackMessage = CompanionMessage(
            id: UUID().uuidString,
            text: "I'm here for you. Let's try some deep breathing together.",
            isFromUser: false,
            timestamp: Date()
          )
          messages.append(fallbackMessage)
          isTyping = false
        }
      }
    }
  }

  private func generateAIResponse(to message: String) {
    isTyping = true

    Task {
      do {
        let systemPrompt = """
          You are a compassionate mental health companion. The user is in crisis and needs immediate support.
          Provide gentle, practical, and supportive responses. Keep responses under 2 sentences.
          Focus on immediate calming techniques and emotional support.
          """

        let response = try await openAIService.sendMessage(message, systemPrompt: systemPrompt)

        await MainActor.run {
          let aiMessage = CompanionMessage(
            id: UUID().uuidString,
            text: response,
            isFromUser: false,
            timestamp: Date()
          )
          messages.append(aiMessage)
          isTyping = false
        }
      } catch {
        await MainActor.run {
          let fallbackMessage = CompanionMessage(
            id: UUID().uuidString,
            text:
              "I'm here to listen and support you. Would you like to try some breathing exercises?",
            isFromUser: false,
            timestamp: Date()
          )
          messages.append(fallbackMessage)
          isTyping = false
        }
      }
    }
  }

  private func generateFallbackResponse(to message: String) {
    isTyping = true

    // Simple fallback responses
    let fallbackResponses = [
      "I'm here to listen. Can you tell me more about what's happening?",
      "That sounds really difficult. I'm here to support you.",
      "I understand this is hard. Let's work through it together.",
      "You're not alone in this. I'm here for you.",
    ]

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      let randomResponse = fallbackResponses.randomElement() ?? "I'm here for you."
      let aiMessage = CompanionMessage(
        id: UUID().uuidString,
        text: randomResponse,
        isFromUser: false,
        timestamp: Date()
      )
      messages.append(aiMessage)
      isTyping = false
    }
  }
}

// MARK: - Supporting Views
struct IntensitySelectionSheet: View {
  let emotion: String
  let onIntensitySelected: (String) -> Void

  private let intensities = ["Mild", "Moderate", "High", "Severe"]

  var body: some View {
    NavigationView {
      VStack(spacing: 24) {
        Text("How intense is your \(emotion.lowercased()) feeling?")
          .font(.title2)
          .fontWeight(.bold)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 20)

        VStack(spacing: 16) {
          ForEach(intensities, id: \.self) { intensity in
            Button(action: {
              onIntensitySelected(intensity)
            }) {
              HStack {
                Text(intensity)
                  .font(.headline)
                  .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                  .foregroundColor(.secondary)
              }
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
          }
        }
        .padding(.horizontal, 20)

        Spacer()
      }
      .padding(.top, 20)
      .navigationTitle("Intensity Level")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

// CrisisResourcesView is already defined in EmergencyCompanionView.swift

struct ResourceButton: View {
  let title: String
  let subtitle: String
  let icon: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        Image(systemName: icon)
          .foregroundColor(.white)
          .frame(width: 24, height: 24)

        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.headline)
            .foregroundColor(.primary)

          Text(subtitle)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .foregroundColor(.secondary)
      }
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
  }
}

#Preview {
  AIEnhancedEmergencyView()
}
