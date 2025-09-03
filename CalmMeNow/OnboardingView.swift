import SwiftUI
import WatchConnectivity

struct OnboardingPage: Identifiable {
  let id = UUID()
  let title: String
  let body: String
  let bullets: [String]
  let showsToggles: Bool
  let showsWatchPrefs: Bool
}

struct OnboardingView: View {
  @AppStorage("hasCompletedOnboarding") var done = false
  @AppStorage("prefSounds") var prefSounds = true
  @AppStorage("prefHaptics") var prefHaptics = true
  @AppStorage("prefVoice") var prefVoice = false
  // 0: Ask every time, 1: Continue, 2: Stop
  @AppStorage("watchEndBehavior") var watchEndBehavior = 1

  @State private var index = 0
  private var watchSupported: Bool {
    #if os(iOS)
      return WCSession.isSupported()
    #else
      return false
    #endif
  }

  private var pages: [OnboardingPage] {
    [
      .init(
        title: "Welcome to CalmMeNow",
        body: "Quick tools to steady your body and mind in tough moments.",
        bullets: [
          "Emergency Calm for intense panic",
          "Emotion tools for anxious, angry, sad, frustrated",
          "Gentle guidance, sounds, and a breathing mascot",
        ],
        showsToggles: false,
        showsWatchPrefs: false
      ),
      .init(
        title: "One minute to feel better",
        body: "Tap how you feel → choose intensity → breathe with guidance.",
        bullets: [
          "Follow \"Inhale • Hold • Exhale\" pacing",
          "Optional calming sound and soft haptics",
          "Stop anytime—your progress is saved",
        ],
        showsToggles: false,
        showsWatchPrefs: false
      ),
      .init(
        title: "Make it yours",
        body: "Set your defaults. You can change them later in Settings.",
        bullets: [],
        showsToggles: true,
        showsWatchPrefs: false
      ),
      .init(
        title: "Apple Watch companion",
        body: "Start a calm session from your wrist with gentle haptics and the breathing cat.",
        bullets: [
          "Quick Calm Now button",
          "Breath pacing with haptics",
          "Choose what happens to iPhone audio when you end a session",
        ],
        showsToggles: false,
        showsWatchPrefs: true
      ),
    ].filter { !$0.showsWatchPrefs || watchSupported }
  }

  var body: some View {
    ZStack {
      // Background gradient
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "#A0C4FF"),  // Teal
          Color(hex: "#98D8C8"),  // Soft Mint
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
        .padding(.bottom, 20)  // Add space above page dots

        Button(index == pages.count - 1 ? "Start Calming" : "Continue") {
          if index < pages.count - 1 {
            withAnimation { index += 1 }
          } else {
            done = true
          }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal, 20)
        .padding(.bottom, 40)  // Increase bottom padding
      }
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

      if !page.bullets.isEmpty {
        VStack(alignment: .leading, spacing: 12) {
          ForEach(page.bullets, id: \.self) { bullet in
            HStack(alignment: .top, spacing: 12) {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: "#FF6B9D"))  // Pink color for better visibility
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

      if page.showsToggles {
        VStack(alignment: .leading, spacing: 16) {
          Toggle("Play calming sounds during sessions", isOn: $prefSounds)
            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#FF6B9D")))

          Toggle("Gentle haptics for breath cues", isOn: $prefHaptics)
            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#FF6B9D")))

          Toggle("Voice prompts (optional)", isOn: $prefVoice)
            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#FF6B9D")))
        }
        .padding(.top, 16)
        .padding(.horizontal, 4)
      }

      if page.showsWatchPrefs {
        VStack(alignment: .leading, spacing: 16) {
          Text("When ending a Watch session")
            .font(.headline)
            .foregroundColor(.black)

          Picker("", selection: $watchEndBehavior) {
            Text("Continue audio").tag(1)
            Text("Stop audio").tag(2)
            Text("Ask every time").tag(0)
          }
          .pickerStyle(.segmented)
          .accentColor(Color(hex: "#FF6B9D"))  // Pink accent color

          Text("You can change this later in Settings.")
            .font(.footnote)
            .foregroundColor(.black.opacity(0.6))
        }
        .padding(.top, 16)
      }

      Spacer()

      // Footer text
      VStack(spacing: 8) {
        Text("CalmMeNow is a self-help tool and not medical care.")
          .font(.footnote)
          .foregroundColor(.black.opacity(0.6))
          .multilineTextAlignment(.center)

        if index == 0 {
          Button("Safety & resources") {
            // TODO: Add safety resources view
          }
          .font(.footnote)
          .foregroundColor(Color(hex: "#FF6B9D"))  // Pink color for better visibility
        }

        if index == 1 {
          Text("If you're in danger, call local emergency services.")
            .font(.footnote)
            .foregroundColor(.black.opacity(0.6))
            .multilineTextAlignment(.center)
        }
      }
      .padding(.bottom, 20)  // Add padding to prevent overlap with page dots
    }
    .padding(.vertical, 20)
  }
}

#Preview {
  OnboardingView()
}
