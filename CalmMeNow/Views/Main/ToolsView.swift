import SwiftUI

struct ToolsView: View {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  @StateObject private var paywallManager = PaywallManager.shared

  @State private var selectedButton: String? = nil
  @State private var showingBreathingLibrary = false
  @State private var showingBreathingChallenge = false
  @State private var showingGrounding = false
  @State private var showingPMRExercise = false
  @State private var showingGameSelection = false
  @State private var showingBubbleGame = false
  @State private var showingMemoryGame = false
  @State private var showingColoringGame = false
  @State private var showingNightProtocol = false
  @State private var showingPositiveQuotes = false
  @State private var showingThoughtChallenge = false

  var body: some View {
    NavigationView {
      ZStack {
        LinearGradient(
          gradient: Gradient(colors: [
            Color(hex: "#A0C4FF"),
            Color(hex: "#98D8C8"),
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
                emoji: "🫁",
                emotion: "Slow my heart",
                subtext: "Breathing techniques to calm you down",
                isSelected: selectedButton == "breathing_library",
                onTap: {
                  HapticManager.shared.softImpact()
                  selectedButton = "breathing_library"
                  showingBreathingLibrary = true
                }
              )
              EmotionCard(
                emoji: "🔥",
                emotion: "Challenge",
                subtext: "7 or 21-day breathing habit builder",
                isSelected: selectedButton == "breathing_challenge",
                onTap: {
                  HapticManager.shared.softImpact()
                  selectedButton = "breathing_challenge"
                  Task {
                    let hasAccess = await paywallManager.requestAIAccess()
                    if hasAccess {
                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showingBreathingChallenge = true
                      }
                    }
                  }
                },
                isPremium: true,
                hasAccess: paywallManager.hasAIAccess
              )
              EmotionCard(
                emoji: "🌱",
                emotion: "Stop the spiral",
                subtext: "5-4-3-2-1 sensory grounding",
                isSelected: selectedButton == "grounding",
                onTap: {
                  HapticManager.shared.emotionButtonTap()
                  selectedButton = "grounding"
                  FirebaseAnalyticsService.shared.trackEmotionSelected(emotion: "grounding")
                  showingGrounding = true
                }
              )
              EmotionCard(
                emoji: "💪",
                emotion: "Release tension",
                subtext: "Progressive muscle relaxation",
                isSelected: selectedButton == "pmr",
                onTap: {
                  HapticManager.shared.emotionButtonTap()
                  selectedButton = "pmr"
                  FirebaseAnalyticsService.shared.trackEmotionSelected(emotion: "pmr")
                  showingPMRExercise = true
                }
              )
              EmotionCard(
                emoji: "🎮",
                emotion: "Distract my mind",
                subtext: "Calming mini-games to break the cycle",
                isSelected: selectedButton == "games",
                onTap: {
                  HapticManager.shared.emotionButtonTap()
                  selectedButton = "games"
                  FirebaseAnalyticsService.shared.trackEmotionSelected(emotion: "games")
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showingGameSelection = true
                  }
                }
              )
              EmotionCard(
                emoji: "🌙",
                emotion: "Help me sleep",
                subtext: "For nighttime panic, PTSD & insomnia",
                isSelected: selectedButton == "night_protocol",
                onTap: {
                  HapticManager.shared.softImpact()
                  selectedButton = "night_protocol"
                  showingNightProtocol = true
                }
              )
              EmotionCard(
                emoji: "✨",
                emotion: "Lift my mood",
                subtext: "Uplifting quotes to shift your headspace",
                isSelected: selectedButton == "positive_quotes",
                onTap: {
                  HapticManager.shared.emotionButtonTap()
                  selectedButton = "positive_quotes"
                  showingPositiveQuotes = true
                }
              )
              EmotionCard(
                emoji: "🧠",
                emotion: "Challenge a thought",
                subtext: "CBT evidence technique for anxious thinking",
                isSelected: selectedButton == "thought_challenge",
                onTap: {
                  HapticManager.shared.softImpact()
                  selectedButton = "thought_challenge"
                  showingThoughtChallenge = true
                }
              )
            }
            .padding(.horizontal, horizontalSizeClass == .regular ? 60 : 20)
          }
          .padding(.top, 20)
          .padding(.bottom, 40)
        }
      }
      .navigationTitle("Tools")
      .navigationBarTitleDisplayMode(.large)
    }
    .navigationViewStyle(.stack)
    .sheet(isPresented: $showingBreathingLibrary) { BreathingLibraryView() }
    .sheet(isPresented: $showingBreathingChallenge) { BreathingChallengeView() }
    .sheet(isPresented: $showingGrounding) { SomaticGroundingView() }
    .sheet(isPresented: $showingPMRExercise) { PMRExerciseView() }
    .sheet(isPresented: $showingGameSelection) {
      GameSelectionView(
        showingBubbleGame: $showingBubbleGame,
        showingMemoryGame: $showingMemoryGame,
        showingColoringGame: $showingColoringGame
      )
    }
    .sheet(isPresented: $showingBubbleGame) { BubbleGameView() }
    .sheet(isPresented: $showingMemoryGame) { MemoryGameView() }
    .sheet(isPresented: $showingColoringGame) { ColoringPageWithTraceView() }
    .sheet(isPresented: $showingNightProtocol) { NightProtocolView() }
    .sheet(isPresented: $showingPositiveQuotes) { PositiveQuotesView() }
    .fullScreenCover(isPresented: $showingThoughtChallenge) { CBTThoughtChallengeView() }
  }
}
