//
//  ContentView.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import SwiftUI

struct ContentView: View {
  @AppStorage("hasShownFirstLaunchOverlay") private var hasShownFirstLaunchOverlay = false
  @State private var showFirstLaunchOverlay = false
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  @StateObject private var audioManager = AudioManager.shared
  @StateObject private var progressTracker = ProgressTracker.shared
  @StateObject private var paywallManager = PaywallManager.shared
  @StateObject private var subscriptionSuccessManager = SubscriptionSuccessManager.shared
  @StateObject private var healthKit = HealthKitManager.shared
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
  @State private var showingEnhancedPanicPlan = false
  @State private var showingAIDebug = false
  @State private var showingPositiveQuotes = false
  @State private var showingGrounding = false
  @State private var showingPMRExercise = false
  @State private var showingCrisisResources = false
  @State private var showingTriggerTracker = false
  @State private var showingNightProtocol = false
  @State private var showingSafeCard = false
  @State private var showingSafePersonSetup = false
  @State private var showingBreathingLibrary = false
  @State private var healthSuggestedProgram: String? = nil

  @State private var selectedEmotion = ""
  @State private var selectedEmoji = ""
  @State private var selectedIntensity: IntensityLevel = .mild

  var body: some View {
    NavigationView {
      ZStack {
        LinearGradient(
          gradient: Gradient(colors: [
            Color(hex: "#C9B8E8"),  // Soft Lavender
            Color(hex: "#E8D5F5"),  // Pale Lilac
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

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
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
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
                .scaleEffect(isQuickCalmPressed ? 0.95 : (1.0 + (calmButtonPulse ? 0.03 : 0.0)))
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
                .animation(.easeInOut(duration: 0.1), value: isQuickCalmPressed)
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
            .padding(.horizontal, horizontalSizeClass == .regular ? 60 : 30)
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

            // Core Differentiators - Reordered with free features first
            VStack(spacing: 20) {
              // Heart Rate card
              HeartRateCard { programName in
                healthSuggestedProgram = programName
                showingBreathingLibrary = true
              }

              // Top row - Free features: Grounding and Body Relax
              HStack(spacing: 20) {
                // Grounding Exercise Card (FREE)
                EmotionCard(
                  emoji: "🌱",
                  emotion: "Grounding",
                  subtext: "5-4-3-2-1 sensory technique",
                  isSelected: selectedButton == "grounding",
                  onTap: {
                    HapticManager.shared.emotionButtonTap()
                    selectedEmotion = "grounding"
                    selectedEmoji = "🌱"

                    FirebaseAnalyticsService.shared.trackEmotionSelected(emotion: "grounding")

                    showingGrounding = true
                  }
                )

                // Progressive Muscle Relaxation Card (FREE)
                EmotionCard(
                  emoji: "💪",
                  emotion: "Body Relax",
                  subtext: "Progressive muscle relaxation",
                  isSelected: selectedButton == "pmr",
                  onTap: {
                    HapticManager.shared.emotionButtonTap()
                    selectedEmotion = "pmr"
                    selectedEmoji = "💪"

                    FirebaseAnalyticsService.shared.trackEmotionSelected(emotion: "pmr")

                    showingPMRExercise = true
                  }
                )
              }

              // Breathing Programs Card - full width
              EmotionCard(
                emoji: "🫁",
                emotion: "Breathing Programs",
                subtext: "5 clinically-backed techniques + custom",
                isSelected: selectedButton == "breathing_library",
                onTap: {
                  HapticManager.shared.softImpact()
                  selectedButton = "breathing_library"
                  showingBreathingLibrary = true
                }
              )

              // Second row - Games and Daily Coach
              HStack(spacing: 20) {
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

                    FirebaseAnalyticsService.shared.trackEmotionSelected(emotion: "games")

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                      showingGameSelection = true
                    }
                  }
                )

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

                    FirebaseAnalyticsService.shared.trackEmotionSelected(emotion: "daily_coach")

                    Task {
                      let hasAccess = await paywallManager.requestAIAccess()
                      if hasAccess {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                          showingDailyCoach = true
                        }
                      }
                    }
                  },
                  isPremium: true,
                  hasAccess: paywallManager.hasAIAccess
                )
              }

              // Third row - Panic Plan and Smart Plan
              HStack(spacing: 20) {
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

                    FirebaseAnalyticsService.shared.trackEmotionSelected(emotion: "panic_plan")

                    Task {
                      let hasAccess = await paywallManager.requestAIAccess()
                      if hasAccess {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                          showingPersonalizedPlan = true
                        }
                      }
                    }
                  },
                  isPremium: true,
                  hasAccess: paywallManager.hasAIAccess
                )

                // Enhanced Panic Plan Card (AI Feature - Requires Subscription)
                EmotionCard(
                  emoji: "🧠",
                  emotion: "Smart Plan",
                  subtext: "Personalized panic plan with insights",
                  isSelected: selectedButton == "enhanced_panic_plan",
                  onTap: {
                    HapticManager.shared.emotionButtonTap()
                    selectedEmotion = "enhanced_panic_plan"
                    selectedEmoji = "🧠"

                    FirebaseAnalyticsService.shared.trackEmotionSelected(
                      emotion: "enhanced_panic_plan")

                    Task {
                      let hasAccess = await paywallManager.requestAIAccess()
                      if hasAccess {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                          showingEnhancedPanicPlan = true
                        }
                      }
                    }
                  },
                  isPremium: true,
                  hasAccess: paywallManager.hasAIAccess
                )
              }

              // Positive Quotes Card - full width
              EmotionCard(
                emoji: "✨",
                emotion: "Positive Boost",
                subtext: "Uplifting quotes to brighten your moment",
                isSelected: selectedButton == "positive_quotes",
                onTap: {
                  HapticManager.shared.emotionButtonTap()
                  selectedEmotion = "positive_quotes"
                  selectedEmoji = "✨"
                  showingPositiveQuotes = true
                }
              )

              // Crisis Resources Card - full width (FREE)
              EmotionCard(
                emoji: "📞",
                emotion: "Crisis Help",
                subtext: "Local crisis hotlines & resources",
                isSelected: selectedButton == "crisis_resources",
                onTap: {
                  HapticManager.shared.emotionButtonTap()
                  selectedEmotion = "crisis_resources"
                  selectedEmoji = "📞"

                  FirebaseAnalyticsService.shared.trackCrisisResourcesViewed()

                  showingCrisisResources = true
                }
              )

              // Trigger Tracker Card - full width (FREE)
              EmotionCard(
                emoji: "📊",
                emotion: "Trigger Tracker",
                subtext: "See what sets off your panic & spot patterns",
                isSelected: selectedButton == "trigger_tracker",
                onTap: {
                  HapticManager.shared.emotionButtonTap()
                  selectedEmotion = "trigger_tracker"
                  selectedEmoji = "📊"
                  showingTriggerTracker = true
                }
              )

              // Night Protocol Card - full width (FREE)
              EmotionCard(
                emoji: "🌙",
                emotion: "Night Protocol",
                subtext: "For nighttime panic, PTSD & insomnia",
                isSelected: selectedButton == "night_protocol",
                onTap: {
                  HapticManager.shared.softImpact()
                  selectedEmotion = "night_protocol"
                  selectedEmoji = "🌙"
                  showingNightProtocol = true
                }
              )

              // Safe Person Card - full width (FREE)
              EmotionCard(
                emoji: "🆘",
                emotion: "Safe Person Card",
                subtext: "One tap to reach your safe network",
                isSelected: selectedButton == "safe_person",
                onTap: {
                  HapticManager.shared.softImpact()
                  selectedButton = "safe_person"
                  if TrustedContactService.shared.hasContacts() {
                    showingSafeCard = true
                  } else {
                    showingSafePersonSetup = true
                  }
                }
              )
            }
            .padding(.horizontal, horizontalSizeClass == .regular ? 80 : 40)
            .padding(.bottom, 40)

            // Streak tracking and gamification
            StreakCardView(progressTracker: progressTracker)
              .padding(.horizontal, horizontalSizeClass == .regular ? 80 : 40)
              .padding(.bottom, 60)
              .onLongPressGesture(minimumDuration: 3) {
                progressTracker.resetStreakData()
              }
              .onTapGesture(count: 2) {
                let calendar = Calendar.current
                if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) {
                  progressTracker.addUsageForDate(yesterday)
                }
              }
              .onTapGesture(count: 3) {
                progressTracker.addUsageForConsecutiveDays(5)
              }
          }
        }
      }
      .overlay(
        Group {
          if showFirstLaunchOverlay {
            FirstLaunchOverlay(isVisible: $showFirstLaunchOverlay)
          }
        }, alignment: .top
      )
      .navigationBarHidden(true)
    }
    .navigationViewStyle(.stack)
    .sheet(isPresented: $showingIntensitySelection) {
      IntensitySelectionView(
        emotion: selectedEmotion,
        emoji: selectedEmoji,
        isPresented: $showingIntensitySelection,
        onIntensitySelected: { intensity in
          selectedIntensity = intensity
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
      .id("\(selectedEmotion)-\(selectedIntensity)")
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
      PersonalizedPanicPlanView()
    }
    .sheet(isPresented: $showingDailyCoach) {
      DailyCoachView()
    }
    .sheet(isPresented: $showingEnhancedPanicPlan) {
      EnhancedPanicPlanView()
    }
    #if DEBUG
      .sheet(isPresented: $showingAIDebug) {
        AIDebugView()
      }
    #endif
    .sheet(isPresented: $showingPositiveQuotes) {
      PositiveQuotesView()
    }
    .sheet(isPresented: $showingGrounding) {
      SomaticGroundingView()
    }
    .sheet(isPresented: $showingPMRExercise) {
      PMRExerciseView()
    }
    .sheet(isPresented: $showingCrisisResources) {
      CrisisResourcesView()
    }
    .sheet(isPresented: $showingTriggerTracker) {
      TriggerTrackerView()
    }
    .sheet(isPresented: $showingNightProtocol) {
      NightProtocolView()
    }
    .fullScreenCover(isPresented: $showingSafeCard) {
      SafePersonCardView()
    }
    .sheet(isPresented: $showingSafePersonSetup) {
      TrustedContactView()
    }
    .sheet(isPresented: $showingBreathingLibrary, onDismiss: { healthSuggestedProgram = nil }) {
      BreathingLibraryView(preselectedProgramName: healthSuggestedProgram)
    }
    .fullScreenCover(isPresented: $subscriptionSuccessManager.shouldShowSuccessScreen) {
      SubscriptionSuccessView()
        .onDisappear {
          subscriptionSuccessManager.dismissSuccessScreen()
        }
    }
    .onAppear {
      if !hasShownFirstLaunchOverlay {
        showFirstLaunchOverlay = true
        hasShownFirstLaunchOverlay = true
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
  var isPremium: Bool = false
  var hasAccess: Bool = true

  var body: some View {
    Button(action: onTap) {
      VStack(spacing: 12) {
        // Emoji on top
        Text(emoji)
          .font(.system(size: 40))
          .padding(.top, 20)
          .opacity(hasAccess ? 1.0 : 0.5)

        // Emotion name
        Text(emotion)
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundColor(hasAccess ? .black : .gray)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
          .padding(.horizontal, 12)

        // Tiny subtext
        Text(subtext)
          .font(.caption)
          .foregroundColor(hasAccess ? .black.opacity(0.6) : .gray.opacity(0.5))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 16)
          .padding(.bottom, 20)
      }
      .frame(maxWidth: .infinity, minHeight: 140)
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(hasAccess ? Color.white : Color.gray.opacity(0.3))
          .shadow(
            color: hasAccess ? .black.opacity(0.1) : .black.opacity(0.05), radius: 8, x: 0, y: 4)
      )
      .scaleEffect(isSelected ? 0.98 : 1.0)
      .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
    .buttonStyle(PlainButtonStyle())
  }
}
