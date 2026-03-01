import SwiftUI
import WatchConnectivity

// User's primary reason for using the app
enum UserPrimaryGoal: String, CaseIterable {
  case panicAttacks = "panic_attacks"
  case generalAnxiety = "general_anxiety"
  case dailyStress = "daily_stress"
  case exploring = "exploring"

  var displayText: String {
    switch self {
    case .panicAttacks: return "I experience panic attacks"
    case .generalAnxiety: return "I have general anxiety"
    case .dailyStress: return "I want to manage daily stress"
    case .exploring: return "Just exploring"
    }
  }

  var emoji: String {
    switch self {
    case .panicAttacks: return "🚨"
    case .generalAnxiety: return "😰"
    case .dailyStress: return "😮‍💨"
    case .exploring: return "🔍"
    }
  }
}

// Common trigger categories
enum UserTrigger: String, CaseIterable {
  case workSchool = "work_school"
  case socialSituations = "social_situations"
  case healthWorries = "health_worries"
  case sleepDifficulties = "sleep_difficulties"
  case generalOverwhelm = "general_overwhelm"

  var displayText: String {
    switch self {
    case .workSchool: return "Work or school stress"
    case .socialSituations: return "Social situations"
    case .healthWorries: return "Health worries"
    case .sleepDifficulties: return "Sleep difficulties"
    case .generalOverwhelm: return "General overwhelm"
    }
  }

  var emoji: String {
    switch self {
    case .workSchool: return "💼"
    case .socialSituations: return "👥"
    case .healthWorries: return "🏥"
    case .sleepDifficulties: return "😴"
    case .generalOverwhelm: return "🌊"
    }
  }
}

enum OnboardingPageType {
  case welcome
  case primaryGoal
  case triggers
  case howToUse
  case preferences
}

struct OnboardingPage: Identifiable {
  let id = UUID()
  let type: OnboardingPageType
  let title: String
  let body: String
  let bullets: [String]
}

struct OnboardingView: View {
  @AppStorage("hasCompletedOnboarding") var done = false
  @AppStorage("prefSounds") var prefSounds = true
  @AppStorage("prefHaptics") var prefHaptics = true
  @AppStorage("prefVoice") var prefVoice = false
  @AppStorage("userPrimaryGoal") var userPrimaryGoal: String = ""
  @AppStorage("userTriggers") var userTriggers: String = ""  // Comma-separated
  // 0: Ask every time, 1: Continue, 2: Stop
  @AppStorage("watchEndBehavior") var watchEndBehavior = 1

  @State private var index = 0
  @State private var selectedGoal: UserPrimaryGoal?
  @State private var selectedTriggers: Set<UserTrigger> = []
  @State private var showingCrisisResources = false

  private var pages: [OnboardingPage] {
    [
      .init(
        type: .welcome,
        title: "Welcome to CalmMeNow",
        body: "Tools to steady your body and mind when stress hits.",
        bullets: [
          "Emergency Calm for sudden panic (Free)",
          "Grounding & relaxation exercises (Free)",
          "Personalized plans & insights (Premium)",
        ]
      ),
      .init(
        type: .primaryGoal,
        title: "What brings you here?",
        body: "This helps us personalize your experience.",
        bullets: []
      ),
      .init(
        type: .triggers,
        title: "Any of these feel familiar?",
        body: "Select all that apply, or skip if you're not sure.",
        bullets: []
      ),
      .init(
        type: .howToUse,
        title: "One minute to feel calmer",
        body: "Here's all you do:",
        bullets: [
          "Tap the big red button whenever panic spikes",
          "Or choose a grounding exercise from the cards",
          "Follow the guided breathing and prompts",
        ]
      ),
      .init(
        type: .preferences,
        title: "Make it yours",
        body: "Pick your defaults. Change them anytime in Settings.",
        bullets: []
      ),
    ]
  }

  var body: some View {
    ZStack {
      // Background gradient
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "#C9B8E8"),  // Soft Lavender
          Color(hex: "#E8D5F5"),  // Pale Lilac
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 24) {
        TabView(selection: $index) {
          ForEach(pages.indices, id: \.self) { i in
            pageView(pages[i])
              .tag(i)
              .padding(.horizontal, 20)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .padding(.bottom, 20)

        // Navigation buttons
        HStack(spacing: 16) {
          // Skip button for optional pages
          if pages[index].type == .triggers {
            Button("Skip") {
              withAnimation { index += 1 }
            }
            .foregroundColor(.black.opacity(0.6))
            .padding(.horizontal, 20)
          }

          Button(buttonText) {
            handleContinue()
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
          .disabled(!canContinue)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
      }
    }
    .sheet(isPresented: $showingCrisisResources) {
      CrisisResourcesView()
    }
  }

  private var buttonText: String {
    if index == pages.count - 1 {
      return "Start Calming"
    } else if pages[index].type == .primaryGoal && selectedGoal == nil {
      return "Select one to continue"
    } else {
      return "Continue"
    }
  }

  private var canContinue: Bool {
    let currentPage = pages[index]
    switch currentPage.type {
    case .primaryGoal:
      return selectedGoal != nil
    default:
      return true
    }
  }

  private func handleContinue() {
    // Save data before moving to next page
    if pages[index].type == .primaryGoal, let goal = selectedGoal {
      userPrimaryGoal = goal.rawValue
    } else if pages[index].type == .triggers {
      userTriggers = selectedTriggers.map { $0.rawValue }.joined(separator: ",")
    }

    if index < pages.count - 1 {
      withAnimation { index += 1 }
    } else {
      done = true
    }
  }

  @ViewBuilder
  private func pageView(_ page: OnboardingPage) -> some View {
    VStack(alignment: .leading, spacing: 20) {
      Spacer()

      VStack(alignment: .leading, spacing: 16) {
        Text(page.title)
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundColor(.black)

        Text(page.body)
          .font(.title3)
          .foregroundColor(.black.opacity(0.7))
          .lineLimit(nil)
      }

      // Standard bullet points
      if !page.bullets.isEmpty {
        VStack(alignment: .leading, spacing: 12) {
          ForEach(page.bullets, id: \.self) { bullet in
            HStack(alignment: .top, spacing: 12) {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: "#FF6B9D"))
                .font(.title3)

              Text(bullet)
                .font(.body)
                .foregroundColor(.black.opacity(0.8))
                .lineLimit(nil)
            }
          }
        }
        .padding(.top, 8)
      }

      // Primary Goal Selection
      if page.type == .primaryGoal {
        VStack(spacing: 12) {
          ForEach(UserPrimaryGoal.allCases, id: \.self) { goal in
            GoalOptionButton(
              goal: goal,
              isSelected: selectedGoal == goal
            ) {
              withAnimation(.easeInOut(duration: 0.2)) {
                selectedGoal = goal
              }
            }
          }
        }
        .padding(.top, 8)
      }

      // Triggers Selection
      if page.type == .triggers {
        VStack(spacing: 12) {
          ForEach(UserTrigger.allCases, id: \.self) { trigger in
            TriggerOptionButton(
              trigger: trigger,
              isSelected: selectedTriggers.contains(trigger)
            ) {
              withAnimation(.easeInOut(duration: 0.2)) {
                if selectedTriggers.contains(trigger) {
                  selectedTriggers.remove(trigger)
                } else {
                  selectedTriggers.insert(trigger)
                }
              }
            }
          }
        }
        .padding(.top, 8)
      }

      // Preferences Toggles
      if page.type == .preferences {
        VStack(alignment: .leading, spacing: 12) {
          preferenceToggle(
            title: "Soothing soundscapes",
            subtitle: "Gentle ambiance while you breathe.",
            isOn: $prefSounds
          )

          preferenceToggle(
            title: "Gentle haptic cues",
            subtitle: "Light taps guide your breathing cadence.",
            isOn: $prefHaptics
          )

          preferenceToggle(
            title: "Soft voice coaching",
            subtitle: "Calm prompts to talk you through each step.",
            isOn: $prefVoice
          )
        }
        .padding(.top, 8)
      }

      Spacer()

      // Footer text
      VStack(spacing: 8) {
        Text("CalmMeNow is a self-help tool, not a replacement for medical care.")
          .font(.footnote)
          .foregroundColor(.black.opacity(0.6))
          .multilineTextAlignment(.center)

        if page.type == .welcome {
          Button("Safety & Crisis Resources") {
            showingCrisisResources = true
          }
          .font(.footnote)
          .foregroundColor(Color(hex: "#FF6B9D"))
        }

        if page.type == .howToUse {
          Text("If you're ever in danger, call your local emergency services.")
            .font(.footnote)
            .foregroundColor(.black.opacity(0.6))
            .multilineTextAlignment(.center)
        }
      }
      .padding(.bottom, 20)
    }
    .padding(.vertical, 20)
  }
}

// MARK: - Goal Option Button
struct GoalOptionButton: View {
  let goal: UserPrimaryGoal
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 16) {
        Text(goal.emoji)
          .font(.title2)

        Text(goal.displayText)
          .font(.body)
          .fontWeight(isSelected ? .semibold : .regular)
          .foregroundColor(.black)

        Spacer()

        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(Color(hex: "#FF6B9D"))
            .font(.title2)
        }
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(isSelected ? Color.white : Color.white.opacity(0.7))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(isSelected ? Color(hex: "#FF6B9D") : Color.clear, lineWidth: 2)
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

// MARK: - Trigger Option Button
struct TriggerOptionButton: View {
  let trigger: UserTrigger
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 16) {
        Text(trigger.emoji)
          .font(.title2)

        Text(trigger.displayText)
          .font(.body)
          .fontWeight(isSelected ? .semibold : .regular)
          .foregroundColor(.black)

        Spacer()

        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
          .foregroundColor(isSelected ? Color(hex: "#FF6B9D") : .black.opacity(0.3))
          .font(.title2)
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(isSelected ? Color.white : Color.white.opacity(0.7))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(isSelected ? Color(hex: "#FF6B9D") : Color.clear, lineWidth: 2)
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

@ViewBuilder
private func preferenceToggle(
  title: String,
  subtitle: String,
  isOn: Binding<Bool>
) -> some View {
  Toggle(isOn: isOn) {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .fontWeight(.semibold)
        .foregroundColor(.black)

      Text(subtitle)
        .font(.caption)
        .foregroundColor(.black.opacity(0.65))
        .fixedSize(horizontal: false, vertical: true)
    }
  }
  .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#FF6B9D")))
  .padding()
  .background(
    RoundedRectangle(cornerRadius: 16)
      .fill(Color.white.opacity(0.9))
  )
  .overlay(
    RoundedRectangle(cornerRadius: 16)
      .stroke(Color.black.opacity(0.05), lineWidth: 1)
  )
}

#Preview {
  OnboardingView()
}
