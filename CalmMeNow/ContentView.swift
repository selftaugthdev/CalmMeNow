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
  @StateObject private var paywallManager = PaywallManager.shared
  @State private var showingPaywall = false
  @State private var selectedButton: String? = nil
  @State private var isQuickCalmPressed = false
  @State private var calmButtonPulse = false
  // Modal presentation states
  @State private var showingIntensitySelection = false
  @State private var showingTailoredExperience = false
  @State private var showingEmergencyCalm = false
  @State private var showingBubbleGame = false
  @State private var showingMemoryGame = false
  @State private var showingColoringGame = false
  @State private var showingGameSelection = false
  @State private var showingPersonalizedPlan = false
  @State private var showingDailyCoach = false
  @State private var showingEmergencyCompanion = false
  @State private var showingAIDebug = false

  @State private var selectedEmotion = ""
  @State private var selectedEmoji = ""
  @State private var selectedIntensity: IntensityLevel = .mild

  var body: some View {
    NavigationView {
      ZStack {
        // Background gradient - Teal to Mint (stability + healing)
        LinearGradient(
          gradient: Gradient(colors: [
            Color(hex: "#4A9B8C"),  // Deep Teal
            Color(hex: "#98D8C8"),  // Soft Mint
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
                HapticManager.shared.emergencyButtonTap()
                isQuickCalmPressed = true
                progressTracker.recordUsage()

                // Track emergency calm usage
                FirebaseAnalyticsService.shared.trackEmergencyCalmUsed()

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
                // Enhanced visual effects for more striking appearance
                .scaleEffect(1.0 + (calmButtonPulse ? 0.03 : 0.0))
                .shadow(
                  color: .red.opacity(calmButtonPulse ? 0.7 : 0.4),
                  radius: calmButtonPulse ? 20 : 12,
                  x: 0,
                  y: calmButtonPulse ? 10 : 6
                )
                .overlay(
                  RoundedRectangle(cornerRadius: 25)
                    .stroke(
                      Color.white.opacity(calmButtonPulse ? 0.8 : 0.4),
                      lineWidth: calmButtonPulse ? 3 : 2
                    )
                )
                .animation(
                  .easeInOut(duration: 2.5)
                    .repeatForever(autoreverses: true),
                  value: calmButtonPulse
                )
              }
              .onAppear {
                // Start the breathing/pulsing animation
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                  calmButtonPulse = true
                }
              }

              Text("For immediate relief from panic attacks")
                .font(.caption)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 30)
            .padding(.top, 60)  // Add top padding to avoid Dynamic Island
            .padding(.bottom, 50)  // Breathing room after emergency button

            // Hidden Debug Button (for testing AI service)
            #if DEBUG
              Button(action: {
                showingAIDebug = true
              }) {
                Text("🔧 AI Debug")
                  .font(.caption2)
                  .foregroundColor(.gray)
                  .padding(.horizontal, 12)
                  .padding(.vertical, 6)
                  .background(Color.gray.opacity(0.1))
                  .cornerRadius(8)
              }
              .padding(.bottom, 20)
            #endif

            Text("Choose your path to calm")
              .font(.title2)
              .fontWeight(.medium)
              .foregroundColor(.black)
              .padding(.bottom, 30)

            Text("Find the right tool for your moment.")
              .font(.body)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 40)
              .padding(.bottom, 50)  // More breathing room before cards
              .foregroundColor(.black.opacity(0.7))

            // Core Differentiators - 4 cards in 2x2 grid
            VStack(spacing: 20) {  // Increased spacing between rows
              // Top row - 2 cards
              HStack(spacing: 20) {  // Increased spacing between cards
                // Games Card
                EmotionCard(
                  emoji: "🎮",
                  emotion: "Games",
                  subtext: "Play calming mini-games to distract and relax",
                  isSelected: selectedButton == "games",
                  onTap: {
                    HapticManager.shared.emotionButtonTap()
                    selectedEmotion = "games"
                    selectedEmoji = "🎮"

                    // Track feature selection
                    FirebaseAnalyticsService.shared.trackEmotionSelected(emotion: "games")

                    // Show game selection menu
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                      showingGameSelection = true
                    }
                  }
                )

                // Personalized Panic Plan Card (AI Feature - Requires Subscription)
                EmotionCard(
                  emoji: "🧩",
                  emotion: "Panic Plan",
                  subtext: "Your personalized emergency response plan",
                  isSelected: selectedButton == "panic_plan",
                  onTap: {
                    HapticManager.shared.emotionButtonTap()
                    selectedEmotion = "panic_plan"
                    selectedEmoji = "🧩"

                    // Track feature selection
                    FirebaseAnalyticsService.shared.trackEmotionSelected(emotion: "panic_plan")

                    // Check paywall access for AI feature
                    Task {
                      let hasAccess = await paywallManager.requestAIAccess()
                      if hasAccess {
                        // Navigate to personalized plan
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                          showingPersonalizedPlan = true
                        }
                      }
                      // If no access, paywall will be shown automatically
                    }
                  }
                )
              }

              // Bottom row - 2 cards
              HStack(spacing: 20) {  // Increased spacing between cards
                // Daily Check-in Coach Card (AI Feature - Requires Subscription)
                EmotionCard(
                  emoji: "📅",
                  emotion: "Daily Coach",
                  subtext: "Daily check-ins and progress tracking",
                  isSelected: selectedButton == "daily_coach",
                  onTap: {
                    HapticManager.shared.emotionButtonTap()
                    selectedEmotion = "daily_coach"
                    selectedEmoji = "📅"

                    // Track feature selection
                    FirebaseAnalyticsService.shared.trackEmotionSelected(emotion: "daily_coach")

                    // Check paywall access for AI feature
                    Task {
                      let hasAccess = await paywallManager.requestAIAccess()
                      if hasAccess {
                        // Navigate to daily coach
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                          showingDailyCoach = true
                        }
                      }
                      // If no access, paywall will be shown automatically
                    }
                  }
                )

                // Emergency Companion Card (AI Feature - Requires Subscription)
                EmotionCard(
                  emoji: "🤖",
                  emotion: "Emergency",
                  subtext: "AI companion for crisis moments",
                  isSelected: selectedButton == "emergency_companion",
                  onTap: {
                    HapticManager.shared.emotionButtonTap()
                    selectedEmotion = "emergency_companion"
                    selectedEmoji = "🤖"

                    // Track feature selection
                    FirebaseAnalyticsService.shared.trackEmotionSelected(
                      emotion: "emergency_companion")

                    // Check paywall access for AI feature
                    Task {
                      let hasAccess = await paywallManager.requestAIAccess()
                      if hasAccess {
                        // Navigate to emergency companion
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                          showingEmergencyCompanion = true
                        }
                      }
                      // If no access, paywall will be shown automatically
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
              .onLongPressGesture(minimumDuration: 3) {
                // Debug: Reset streak data on long press
                progressTracker.resetStreakData()
              }
              .onTapGesture(count: 2) {
                // Debug: Add test usage for yesterday
                let calendar = Calendar.current
                if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) {
                  progressTracker.addUsageForDate(yesterday)
                }
              }
              .onTapGesture(count: 3) {
                // Debug: Add test usage for 5 consecutive days
                progressTracker.addUsageForConsecutiveDays(5)
              }
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
      .sheet(isPresented: $showingBubbleGame) {
        BubbleGameView()
      }
      .sheet(isPresented: $showingMemoryGame) {
        MemoryGameView()
      }
      .sheet(isPresented: $showingColoringGame) {
        ColoringPageWithTraceView()
      }
      .sheet(isPresented: $showingGameSelection) {
        GameSelectionView(
          showingBubbleGame: $showingBubbleGame,
          showingMemoryGame: $showingMemoryGame,
          showingColoringGame: $showingColoringGame
        )
      }
      .sheet(isPresented: $showingPersonalizedPlan) {
        PersonalizedPanicPlanGeneratorView()
      }
      .sheet(isPresented: $showingDailyCoach) {
        DailyCoachView()
      }
      .sheet(isPresented: $showingEmergencyCompanion) {
        EmergencyCompanionView()
      }
      #if DEBUG
        .sheet(isPresented: $showingAIDebug) {
          AIDebugView()
        }
      #endif

    }
    .sheet(isPresented: $showingPaywall) {
      PaywallView()
    }
    .onReceive(paywallManager.$shouldShowPaywall) { shouldShow in
      showingPaywall = shouldShow
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
          .foregroundColor(.black)

        // Tiny subtext
        Text(subtext)
          .font(.caption)
          .foregroundColor(.black.opacity(0.6))
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
