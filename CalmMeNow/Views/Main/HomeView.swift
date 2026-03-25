import SwiftUI

struct HomeView: View {
  @AppStorage("hasShownFirstLaunchOverlay") private var hasShownFirstLaunchOverlay = false
  @State private var showFirstLaunchOverlay = false
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  @StateObject private var progressTracker = ProgressTracker.shared
  @StateObject private var paywallManager = PaywallManager.shared
  @StateObject private var subscriptionSuccessManager = SubscriptionSuccessManager.shared

  @State private var isQuickCalmPressed = false
  @State private var calmButtonPulse = false
  @State private var selectedButton: String? = nil

  @State private var showingEmergencyCalm = false
  @State private var showingBreathingLibrary = false
  @State private var showingGrounding = false
  @State private var showingPMRExercise = false
  @State private var showingNightProtocol = false
  @State private var showingSafeCard = false
  @State private var showingSafePersonSetup = false
  @State private var showingCrisisResources = false
  @State private var showingSettings = false
  @State private var showingPaywall = false

  var body: some View {
    NavigationView {
      ZStack {
        LinearGradient(
          gradient: Gradient(colors: [
            Color(hex: "#C9B8E8"),
            Color(hex: "#E8D5F5"),
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 0) {
          // Section 1: Emergency Block
          VStack(spacing: 8) {
            Text("I need help right now")
              .font(.title3)
              .fontWeight(.semibold)
              .foregroundColor(.black.opacity(0.55))

            Button(action: {
              HapticManager.shared.emergencyButtonTap()
              isQuickCalmPressed = true
              progressTracker.recordUsage()
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
                .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                value: calmButtonPulse
              )
            }
            .onAppear {
              withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                calmButtonPulse = true
              }
            }

            // Secondary buttons: Safe Person Card + Crisis Help
            HStack(spacing: 12) {
              Button(action: {
                HapticManager.shared.softImpact()
                selectedButton = "safe_person"
                if TrustedContactService.shared.hasContacts() {
                  showingSafeCard = true
                } else {
                  showingSafePersonSetup = true
                }
              }) {
                HStack(spacing: 6) {
                  Text("🆘")
                    .font(.body)
                  Text("Safe Person Card")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }
                .foregroundColor(.black)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)
                .background(
                  RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                )
              }
              .buttonStyle(PlainButtonStyle())

              Button(action: {
                HapticManager.shared.emotionButtonTap()
                FirebaseAnalyticsService.shared.trackCrisisResourcesViewed()
                showingCrisisResources = true
              }) {
                HStack(spacing: 6) {
                  Text("📞")
                    .font(.body)
                  Text("Crisis Help")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }
                .foregroundColor(.black)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)
                .background(
                  RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                )
              }
              .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 16)
          }
          .padding(.horizontal, horizontalSizeClass == .regular ? 60 : 24)
          .padding(.top, 12)

          // Section 2: Quick Access 2x2 grid
          VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
              Text("Right here, right now")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.black)
              Text("Tap anything. You've got this.")
                .font(.caption)
                .foregroundColor(.black.opacity(0.6))
            }
            .padding(.horizontal, 4)

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
            }
          }
          .padding(.horizontal, horizontalSizeClass == .regular ? 60 : 24)
          .padding(.top, 20)

          Spacer()
        }
      }
      .overlay(
        Group {
          if showFirstLaunchOverlay {
            FirstLaunchOverlay(isVisible: $showFirstLaunchOverlay)
          }
        }, alignment: .top
      )
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: { showingSettings = true }) {
            Image(systemName: "gear")
              .foregroundColor(.black.opacity(0.7))
          }
        }
      }
    }
    .navigationViewStyle(.stack)
    .fullScreenCover(isPresented: $showingEmergencyCalm) { PanicFlowView() }
    .sheet(isPresented: $showingBreathingLibrary) { BreathingLibraryView() }
    .sheet(isPresented: $showingGrounding) { SomaticGroundingView() }
    .sheet(isPresented: $showingPMRExercise) { PMRExerciseView() }
    .sheet(isPresented: $showingNightProtocol) { NightProtocolView() }
    .fullScreenCover(isPresented: $showingSafeCard) { SafePersonCardView() }
    .sheet(isPresented: $showingSafePersonSetup) { TrustedContactView() }
    .sheet(isPresented: $showingCrisisResources) { CrisisResourcesView() }
    .sheet(isPresented: $showingSettings) { SettingsView() }
    .sheet(isPresented: $showingPaywall) { PaywallView() }
    .fullScreenCover(isPresented: $subscriptionSuccessManager.shouldShowSuccessScreen) {
      SubscriptionSuccessView()
        .onDisappear { subscriptionSuccessManager.dismissSuccessScreen() }
    }
    .onReceive(paywallManager.$shouldShowPaywall) { shouldShow in
      showingPaywall = shouldShow
    }
    .onAppear {
      if !hasShownFirstLaunchOverlay {
        showFirstLaunchOverlay = true
        hasShownFirstLaunchOverlay = true
      }
    }
  }
}
