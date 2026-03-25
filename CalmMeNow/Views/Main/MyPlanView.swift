import SwiftUI

struct MyPlanView: View {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  @StateObject private var paywallManager = PaywallManager.shared

  @State private var selectedButton: String? = nil
  @State private var showingEnhancedPanicPlan = false
  @State private var showingDailyCoach = false
  @State private var showingTriggerTracker = false
  @State private var showingPatternInsights = false
  @State private var showingSleepRoutine = false
  @State private var showingPaywall = false

  var body: some View {
    NavigationView {
      ZStack {
        LinearGradient(
          gradient: Gradient(colors: [
            Color(hex: "#F5D5E8"),
            Color(hex: "#E8C9D0"),
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        ScrollView {
          VStack(spacing: 20) {
            LazyVGrid(
              columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
              ],
              spacing: 16
            ) {
              EmotionCard(
                emoji: "🧠",
                emotion: "Personal Coach",
                subtext: "Your personalised plan with journal insights",
                isSelected: selectedButton == "enhanced_panic_plan",
                onTap: {
                  HapticManager.shared.emotionButtonTap()
                  selectedButton = "enhanced_panic_plan"
                  FirebaseAnalyticsService.shared.trackEmotionSelected(emotion: "enhanced_panic_plan")
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

              EmotionCard(
                emoji: "📅",
                emotion: "Daily Coach",
                subtext: "Daily check-ins and progress tracking",
                isSelected: selectedButton == "daily_coach",
                onTap: {
                  HapticManager.shared.emotionButtonTap()
                  selectedButton = "daily_coach"
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

              EmotionCard(
                emoji: "📊",
                emotion: "Trigger Tracker",
                subtext: "See what sets off your panic & spot patterns",
                isSelected: selectedButton == "trigger_tracker",
                onTap: {
                  HapticManager.shared.emotionButtonTap()
                  selectedButton = "trigger_tracker"
                  showingTriggerTracker = true
                }
              )

              EmotionCard(
                emoji: "📈",
                emotion: "Pattern Insights",
                subtext: "Discover trends in your mental health journey",
                isSelected: selectedButton == "pattern_insights",
                onTap: {
                  HapticManager.shared.emotionButtonTap()
                  selectedButton = "pattern_insights"
                  Task {
                    let hasAccess = await paywallManager.requestAIAccess()
                    if hasAccess {
                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showingPatternInsights = true
                      }
                    }
                  }
                },
                isPremium: true,
                hasAccess: paywallManager.hasAIAccess
              )

              EmotionCard(
                emoji: "💤",
                emotion: "Sleep Routine",
                subtext: "Wind-down routine for better sleep",
                isSelected: selectedButton == "sleep_routine",
                onTap: {
                  HapticManager.shared.emotionButtonTap()
                  selectedButton = "sleep_routine"
                  Task {
                    let hasAccess = await paywallManager.requestAIAccess()
                    if hasAccess {
                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showingSleepRoutine = true
                      }
                    }
                  }
                },
                isPremium: true,
                hasAccess: paywallManager.hasAIAccess
              )
            }
            .padding(.horizontal, horizontalSizeClass == .regular ? 60 : 20)
          }
          .padding(.top, 20)
          .padding(.bottom, 40)
        }
      }
      .navigationTitle("My Plan")
      .navigationBarTitleDisplayMode(.large)
    }
    .navigationViewStyle(.stack)
    .sheet(isPresented: $showingEnhancedPanicPlan) { EnhancedPanicPlanView() }
    .sheet(isPresented: $showingDailyCoach) { DailyCoachView() }
    .sheet(isPresented: $showingTriggerTracker) { TriggerTrackerView() }
    .sheet(isPresented: $showingPatternInsights) { PatternAnalyticsView() }
    .sheet(isPresented: $showingSleepRoutine) { SleepRoutineView() }
    .sheet(isPresented: $showingPaywall) { PaywallView() }
    .onReceive(paywallManager.$shouldShowPaywall) { shouldShow in
      showingPaywall = shouldShow
    }
  }
}
