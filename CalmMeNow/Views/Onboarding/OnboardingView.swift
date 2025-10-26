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
        body: "Tools to help you steady your body and mind when stress hits.",
        bullets: [
          "Emergency Calm → for sudden panic (Always Free)",
          "Emotion Tools → manage anxiety, anger, sadness, frustration (Always Free)",
          "Guided breathing and soothing sounds (Premium Unlock)",
        ],
        showsToggles: false,
        showsWatchPrefs: false
      ),
      .init(
        title: "One minute to feel calmer",
        body: "Here's all you do:",
        bullets: [
          "Tap the big orange Calm Me Now button whenever panic spikes — it's your instant relief button and it's free forever.",
          "Choose how you feel → pick intensity",
          "Follow \"Inhale • Hold • Exhale\" pacing",
          "Add calming sounds or haptics if you like",
        ],
        showsToggles: false,
        showsWatchPrefs: false
      ),
      .init(
        title: "Make it yours",
        body: "Pick your defaults. You can change them anytime in Settings.",
        bullets: [],
        showsToggles: true,
        showsWatchPrefs: false
      ),
      // Commented out for MVP launch without Apple Watch
      // .init(
      //   title: "Apple Watch companion",
      //   body: "Start a calm session from your wrist with gentle haptics and the breathing cat.",
      //   bullets: [
      //     "Quick Calm Now button",
      //     "Breath pacing with haptics",
      //     "Choose what happens to iPhone audio when you end a session",
      //   ],
      //   showsToggles: false,
      //   showsWatchPrefs: true
      // ),
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
          Text("Choose a couple of calming defaults. You can tweak them anytime in Settings.")
            .font(.subheadline)
            .foregroundColor(.black.opacity(0.7))

          VStack(alignment: .leading, spacing: 12) {
            preferenceToggle(
              title: "Soothing soundscapes",
              subtitle: "Keeps gentle ambiance playing while you breathe.",
              isOn: $prefSounds
            )

            preferenceToggle(
              title: "Gentle haptic cues",
              subtitle: "Light taps guide your inhale, hold, and exhale cadence.",
              isOn: $prefHaptics
            )

            preferenceToggle(
              title: "Soft voice coaching",
              subtitle: "Hear calm prompts if you like being talked through each step.",
              isOn: $prefVoice
            )
          }
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
        Text("CalmMeNow is a self-help tool, not a replacement for medical care.")
          .font(.footnote)
          .foregroundColor(.black.opacity(0.6))
          .multilineTextAlignment(.center)

        if index == 0 {
          Button("Safety & Resources") {
            // TODO: Add safety resources view
          }
          .font(.footnote)
          .foregroundColor(Color(hex: "#FF6B9D"))  // Pink color for better visibility
        }

        if index == 1 {
          Text("If you're ever in danger, call your local emergency services.")
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
