//
//  ContentView.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var audioManager = AudioManager.shared
  @StateObject private var progressTracker = ProgressTracker.shared
  @State private var selectedButton: String? = nil
  @State private var isQuickCalmPressed = false
  @State private var isBreathing = false
  // Modal presentation states
  @State private var showingIntensitySelection = false
  @State private var showingTailoredExperience = false
  @State private var showingEmergencyCalm = false

  @State private var selectedEmotion = ""
  @State private var selectedEmoji = ""
  @State private var selectedIntensity: IntensityLevel = .mild

  var body: some View {
    NavigationView {
      ZStack {
        // Background gradient - Teal to Soft Purple (stability + healing)
        LinearGradient(
          gradient: Gradient(colors: [
            Color(hex: "#A0C4FF"),  // Teal
            Color(hex: "#D0BFFF"),  // Soft Purple
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        // Add a subtle overlay to soften the gradient
        Color.white.opacity(0.1)
          .ignoresSafeArea()

        ScrollView {
          VStack(spacing: 0) {
            // Emergency Quick Calm Button at TOP - instant relief
            VStack(spacing: 8) {
              Text("🚨 EMERGENCY CALM")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.red)
                .opacity(0.9)

              Button(action: {
                isQuickCalmPressed = true
                progressTracker.recordUsage()
                showingEmergencyCalm = true
              }) {
                HStack(spacing: 10) {
                  Text("🕊️")
                    .font(.title2)
                  Text("CALM ME DOWN NOW")
                    .font(.title3)
                    .fontWeight(.bold)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(
                  LinearGradient(
                    gradient: Gradient(colors: [
                      Color.red.opacity(0.9),
                      Color.orange.opacity(0.8),
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  )
                )
                .foregroundColor(.white)
                .cornerRadius(25)
                .overlay(
                  RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.red.opacity(0.5), lineWidth: 2)
                )
                .shadow(color: .red.opacity(0.4), radius: 12, x: 0, y: 6)
                .scaleEffect(isQuickCalmPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isQuickCalmPressed)
              }

              Text("For immediate relief from panic attacks")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 30)
            .padding(.top, 60)  // Add top padding to avoid Dynamic Island
            .padding(.bottom, 50)  // Breathing room after emergency button

            // Logo with breathing animation
            Image("CalmMeNow Logo Homepage")
              .resizable()
              .scaledToFit()
              .frame(height: 80)
              .scaleEffect(isBreathing ? 1.05 : 1.0)
              .opacity(isBreathing ? 0.9 : 1.0)
              .animation(
                Animation.easeInOut(duration: 4)
                  .repeatForever(autoreverses: true),
                value: isBreathing
              )
              .onAppear {
                isBreathing = true
              }
              .padding(.bottom, 40)  // Breathing room after logo

            Text("Tap how you feel.")
              .font(.title2)
              .fontWeight(.medium)
              .padding(.bottom, 30)

            Text("We'll help you feel better in 60 seconds.")
              .font(.body)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 40)
              .padding(.bottom, 50)  // More breathing room before cards
              .foregroundColor(.secondary)

            // Clean Emotion Cards - 4 cards in 2x2 grid
            VStack(spacing: 20) {  // Increased spacing between rows
              // Top row - 2 cards
              HStack(spacing: 20) {  // Increased spacing between cards
                // Anxious Card
                EmotionCard(
                  emoji: "😰",
                  emotion: "Anxious",
                  subtext: "Tap to feel better in 60 seconds",
                  isSelected: selectedButton == "anxious",
                  onTap: {
                    selectedEmotion = "anxious"
                    selectedEmoji = "😰"
                    // Force state synchronization with delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                      showingIntensitySelection = true
                    }
                  }
                )

                // Angry Card
                EmotionCard(
                  emoji: "😡",
                  emotion: "Angry",
                  subtext: "Tap to feel better in 60 seconds",
                  isSelected: selectedButton == "angry",
                  onTap: {
                    selectedEmotion = "angry"
                    selectedEmoji = "😡"
                    // Force state synchronization with delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                      showingIntensitySelection = true
                    }
                  }
                )
              }

              // Bottom row - 2 cards
              HStack(spacing: 20) {  // Increased spacing between cards
                // Sad Card
                EmotionCard(
                  emoji: "😢",
                  emotion: "Sad",
                  subtext: "Tap to feel better in 60 seconds",
                  isSelected: selectedButton == "sad",
                  onTap: {
                    selectedEmotion = "sad"
                    selectedEmoji = "😢"
                    // Force state synchronization with delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                      showingIntensitySelection = true
                    }
                  }
                )

                // Frustrated Card
                EmotionCard(
                  emoji: "😖",
                  emotion: "Frustrated",
                  subtext: "Tap to feel better in 60 seconds",
                  isSelected: selectedButton == "frustrated",
                  onTap: {
                    selectedEmotion = "frustrated"
                    selectedEmoji = "😖"
                    // Force state synchronization with delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                      showingIntensitySelection = true
                    }
                  }
                )
              }
            }
            .padding(.horizontal, 40)  // Increased horizontal padding for breathing room
            .padding(.bottom, 40)  // Breathing room before achievement card

            // Streak tracking and gamification
            StreakCardView(progressTracker: progressTracker)
              .padding(.horizontal, 40)
              .padding(.bottom, 60)  // Add bottom padding for scroll space
          }
        }
      }
      .navigationBarHidden(true)
      .sheet(isPresented: $showingIntensitySelection) {
        IntensitySelectionView(
          emotion: selectedEmotion,
          emoji: selectedEmoji,
          isPresented: $showingIntensitySelection,
          onIntensitySelected: { intensity in
            selectedIntensity = intensity
            // Force state synchronization with delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              showingTailoredExperience = true
            }
          }
        )
      }
      .sheet(isPresented: $showingTailoredExperience) {
        TailoredExperienceView(
          emotion: selectedEmotion,
          intensity: selectedIntensity
        )
        .id("\(selectedEmotion)-\(selectedIntensity)")  // Force recreation when values change
      }

      .sheet(isPresented: $showingEmergencyCalm) {
        EmergencyCalmView()
      }

    }
  }

  private func timeString(from timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }
}

// MARK: - Emotion Card Component
struct EmotionCard: View {
  let emoji: String
  let emotion: String
  let subtext: String
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(spacing: 12) {
        // Emoji on top
        Text(emoji)
          .font(.system(size: 40))  // Larger emoji
          .padding(.top, 20)

        // Emotion name
        Text(emotion)
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundColor(.primary)

        // Tiny subtext
        Text(subtext)
          .font(.caption)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 16)
          .padding(.bottom, 20)
      }
      .frame(maxWidth: .infinity, minHeight: 140)  // Taller cards for better proportions
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(Color.white)
          .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
      )
      .scaleEffect(isSelected ? 0.98 : 1.0)
      .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
    .buttonStyle(PlainButtonStyle())
  }
}
