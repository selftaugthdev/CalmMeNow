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

  var body: some View {
    NavigationView {
      ZStack {
        // Background gradient
        LinearGradient(
          gradient: Gradient(colors: [
            Color(red: 0.85, green: 0.85, blue: 0.95),  // Deeper lavender
            Color(red: 0.80, green: 0.90, blue: 0.95),  // Richer blue
            Color(red: 0.85, green: 0.95, blue: 0.85),  // Deeper mint
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
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.red)
                .opacity(0.8)

              Button(action: {
                isQuickCalmPressed = true
                progressTracker.recordUsage()
                audioManager.playSound("perfect-beauty-1-min")
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

            if audioManager.isPlaying {
              Text(timeString(from: audioManager.remainingTime))
                .font(.title)
                .foregroundColor(.blue)
                .padding(.bottom, 30)
            }

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
                    selectedButton = "anxious"
                    progressTracker.recordUsage()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                      selectedButton = nil
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
                    selectedButton = "angry"
                    progressTracker.recordUsage()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                      selectedButton = nil
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
                    selectedButton = "sad"
                    progressTracker.recordUsage()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                      selectedButton = nil
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
                    selectedButton = "frustrated"
                    progressTracker.recordUsage()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                      selectedButton = nil
                    }
                  }
                )
              }
            }
            .padding(.horizontal, 40)  // Increased horizontal padding for breathing room
            .padding(.bottom, 40)  // Breathing room before achievement card

            // Progress tracking as achievement card
            VStack(spacing: 12) {
              // Achievement icon
              Text("🏆")
                .font(.system(size: 32))
                .padding(.top, 20)

              // Main usage message
              Text(progressTracker.getUsageMessage())
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

              // Total usage message
              Text(progressTracker.getTotalUsageMessage())
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
            .background(
              RoundedRectangle(cornerRadius: 20)
                .fill(
                  LinearGradient(
                    gradient: Gradient(colors: [
                      Color.white.opacity(0.9),
                      Color.white.opacity(0.7)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  )
                )
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
            )
            .overlay(
              RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 40)
            .padding(.bottom, 60) // Add bottom padding for scroll space
          }
        }
      }
      .navigationBarHidden(true)
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
