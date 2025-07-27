//
//  ContentView.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var audioManager = AudioManager.shared
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

        VStack(spacing: 0) {
          Spacer()

          // Logo with breathing animation
          Image("CalmMeNow Logo Homepage")
            .resizable()
            .scaledToFit()
            .frame(height: 80)  // Reduced from 120 to 80
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
            .padding(.top, 45)  // Add top padding to avoid Dynamic Island
            .padding(.bottom, 40)  // Reduced from 50 to 40

          Text("Tap how you feel.")
            .font(.title2)
            .fontWeight(.medium)
            .padding(.bottom, 30)  // Increased spacing

          Text("We'll help you feel better in 60 seconds.")
            .font(.body)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)  // Reduced from 50 to 40
            .foregroundColor(.secondary)

          if audioManager.isPlaying {
            Text(timeString(from: audioManager.remainingTime))
              .font(.title)
              .foregroundColor(.blue)
              .padding(.bottom, 30)  // Increased spacing
          }

          // Enhanced Emotion Buttons Grid
          LazyVGrid(
            columns: [
              GridItem(.flexible()),
              GridItem(.flexible()),
            ], spacing: 15
          ) {
            ForEach(enhancedCooldowns, id: \.id) { cooldown in
              NavigationLink(destination: CooldownView(model: cooldown)) {
                VStack(spacing: 4) {
                  HStack {
                    Text(cooldown.emoji)
                      .font(.title2)
                    Text(cooldown.emotion)
                      .font(.headline)
                      .fontWeight(.medium)
                      .lineLimit(1)
                      .minimumScaleFactor(0.8)
                  }

                  // Intensity level
                  if let intensity = cooldown.intensity {
                    Text(intensity)
                      .font(.caption2)
                      .foregroundColor(.secondary)
                      .opacity(0.8)
                      .lineLimit(1)
                      .minimumScaleFactor(0.7)
                  }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 80)
                .background(
                  LinearGradient(
                    gradient: Gradient(colors: [
                      Color(red: 0.9, green: 0.92, blue: 0.98),
                      Color(red: 0.85, green: 0.88, blue: 0.95),
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  )
                )
                .foregroundColor(.blue)
                .cornerRadius(16)
                .overlay(
                  RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .blue.opacity(0.15), radius: 4, x: 0, y: 2)
                .scaleEffect(selectedButton == cooldown.id ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: selectedButton)
              }
              .onTapGesture {
                selectedButton = cooldown.id
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                  selectedButton = nil
                }
              }
            }
          }
          .padding(.horizontal, 30)

          Spacer()
            .frame(height: 60)  // Add specific spacing between grid and emergency button

          // Emergency Quick Calm Button at bottom
          VStack(spacing: 8) {
            Text("🚨 EMERGENCY CALM")
              .font(.caption)
              .fontWeight(.bold)
              .foregroundColor(.red)
              .opacity(0.8)

            Button(action: {
              isQuickCalmPressed = true
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
          .padding(.bottom, 40)
        }
      }
      .navigationBarHidden(true)
    }
  }

  // Enhanced cooldown models with intensity levels
  private var enhancedCooldowns: [CooldownModel] {
    [
      CooldownModel(
        id: "anxious",
        emotion: "Overwhelmed",
        emoji: "😰",
        soundFileName: "mixkit-serene-anxious",
        backgroundColors: [
          Color(hex: "#B5D8F6"),
          Color(hex: "#D7CFF5"),
        ],
        hasBreathingOrb: true,
        optionalText: "Take a moment to breathe. Let's find your calm together.",
        animationType: .breathing,
        intensity: "Mildly Anxious"
      ),
      CooldownModel(
        id: "very-anxious",
        emotion: "Panicky",
        emoji: "😱",
        soundFileName: "mixkit-serene-anxious",
        backgroundColors: [
          Color(hex: "#B5D8F6"),
          Color(hex: "#D7CFF5"),
        ],
        hasBreathingOrb: true,
        optionalText: "You're safe. Let's slow down together.",
        animationType: .breathing,
        intensity: "Very Anxious"
      ),
      CooldownModel(
        id: "angry",
        emotion: "Frustrated",
        emoji: "😠",
        soundFileName: "mixkit-just-chill-angry",
        backgroundColors: [
          Color(hex: "#FF6B6B"),
          Color(hex: "#4ECDC4"),
        ],
        hasBreathingOrb: false,
        optionalText: "Take deep breaths and feel the tension dissolve",
        animationType: .vibrating,
        intensity: "Mildly Angry"
      ),
      CooldownModel(
        id: "very-angry",
        emotion: "Raging",
        emoji: "🤬",
        soundFileName: "mixkit-just-chill-angry",
        backgroundColors: [
          Color(hex: "#FF6B6B"),
          Color(hex: "#4ECDC4"),
        ],
        hasBreathingOrb: false,
        optionalText: "Let's find your center and release this energy",
        animationType: .vibrating,
        intensity: "Very Angry"
      ),
      CooldownModel(
        id: "sad",
        emotion: "Down",
        emoji: "😢",
        soundFileName: "mixkit-jazz-sad",
        backgroundColors: [
          Color(red: 0.95, green: 0.90, blue: 0.98),
          Color(red: 0.98, green: 0.85, blue: 0.90),
          Color(red: 0.98, green: 0.95, blue: 0.90),
        ],
        hasBreathingOrb: false,
        optionalText: "It's okay to feel sad. Let's find comfort together.",
        animationType: .hugging,
        intensity: "Mildly Sad"
      ),
      CooldownModel(
        id: "very-sad",
        emotion: "Devastated",
        emoji: "💔",
        soundFileName: "mixkit-jazz-sad",
        backgroundColors: [
          Color(red: 0.95, green: 0.90, blue: 0.98),
          Color(red: 0.98, green: 0.85, blue: 0.90),
          Color(red: 0.98, green: 0.95, blue: 0.90),
        ],
        hasBreathingOrb: false,
        optionalText: "You're not alone. Let's hold space for your feelings.",
        animationType: .hugging,
        intensity: "Very Sad"
      ),
      CooldownModel(
        id: "frustrated",
        emotion: "Stuck",
        emoji: "😤",
        soundFileName: "perfect-beauty-1-min",
        backgroundColors: [
          Color(red: 0.85, green: 0.95, blue: 0.85),
          Color(red: 0.70, green: 0.90, blue: 0.90),
        ],
        hasBreathingOrb: false,
        optionalText: "Take a step back. Let's find clarity together.",
        animationType: .pulsing,
        intensity: "Mildly Frustrated"
      ),
      CooldownModel(
        id: "very-frustrated",
        emotion: "Quick Relief",
        emoji: "😫",
        soundFileName: "perfect-beauty-1-min",
        backgroundColors: [
          Color(red: 0.85, green: 0.95, blue: 0.85),
          Color(red: 0.70, green: 0.90, blue: 0.90),
        ],
        hasBreathingOrb: false,
        optionalText: "Let's break through this together.",
        animationType: .pulsing,
        intensity: "Very Frustrated"
      ),
    ]
  }

  private func timeString(from timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }
}
