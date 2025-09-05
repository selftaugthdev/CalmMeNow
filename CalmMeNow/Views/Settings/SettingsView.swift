import SwiftUI

struct SettingsView: View {
  @AppStorage("watchEndBehavior") private var watchEndBehavior: Int = 1
  @AppStorage("prefSounds") private var prefSounds: Bool = true
  @AppStorage("prefHaptics") private var prefHaptics: Bool = true
  @AppStorage("prefVoice") private var prefVoice: Bool = false

  var body: some View {
    NavigationView {
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

        ScrollView {
          VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
              Text("⚙️ Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)

              Text("Customize your experience")
                .font(.subheadline)
                .foregroundColor(.primary.opacity(0.7))
            }
            .padding(.top, 20)

            // Settings sections
            VStack(spacing: 20) {
              // Watch Integration Settings
              SettingsSection(title: "Watch Integration") {
                VStack(alignment: .leading, spacing: 16) {
                  Text("When ending session")
                    .font(.headline)
                    .foregroundColor(.primary)

                  Picker("When ending session", selection: $watchEndBehavior) {
                    Text("Ask every time").tag(0)
                    Text("Continue audio").tag(1)
                    Text("Stop audio").tag(2)
                  }
                  .pickerStyle(.inline)

                  Text("Choose what happens when you stop a session on your Apple Watch")
                    .font(.caption)
                    .foregroundColor(.primary.opacity(0.6))
                }
                .padding()
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.9))
                )
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
              }

              // General Settings
              SettingsSection(title: "General") {
                VStack(spacing: 16) {
                  SettingsToggleRow(
                    title: "Calming Sounds",
                    description: "Play calming sounds during sessions",
                    isOn: $prefSounds
                  )

                  Divider()
                    .background(Color.black.opacity(0.1))

                  SettingsToggleRow(
                    title: "Haptic Feedback",
                    description: "Gentle haptics for breath cues",
                    isOn: $prefHaptics
                  )

                  Divider()
                    .background(Color.black.opacity(0.1))

                  SettingsToggleRow(
                    title: "Voice Prompts",
                    description: "Audio cues during breathing exercises",
                    isOn: $prefVoice
                  )
                }
                .padding()
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.9))
                )
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
              }

              // AI Settings
              SettingsSection(title: "🤖 AI Assistant") {
                VStack(spacing: 16) {
                  HStack {
                    VStack(alignment: .leading, spacing: 4) {
                      Text("AI-Powered Features")
                        .font(.headline)
                        .foregroundColor(.primary)

                      Text("Personalized calming advice and breathing guidance")
                        .font(.caption)
                        .foregroundColor(.primary.opacity(0.6))
                    }

                    Spacer()

                    // AI is automatically configured - no settings needed
                    Image(systemName: "checkmark.circle.fill")
                      .foregroundColor(.green)
                      .font(.system(size: 14, weight: .medium))
                  }

                  HStack {
                    Image(systemName: "checkmark.circle.fill")
                      .foregroundColor(.green)

                    Text("AI Configured")
                      .font(.caption)
                      .foregroundColor(.green)
                  }
                }
                .padding()
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.9))
                )
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
              }

              // About Section
              SettingsSection(title: "About") {
                VStack(spacing: 16) {
                  HStack {
                    Text("Version")
                      .foregroundColor(.primary)
                    Spacer()
                    Text("1.0.0")
                      .foregroundColor(.primary.opacity(0.6))
                  }

                  Divider()
                    .background(Color.primary.opacity(0.1))

                  HStack {
                    Text("Build")
                      .foregroundColor(.primary)
                    Spacer()
                    Text("1")
                      .foregroundColor(.primary.opacity(0.6))
                  }
                }
                .padding()
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.9))
                )
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
              }
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 40)
          }
        }
      }
      .navigationBarHidden(true)
    }
  }
}

struct SettingsSection<Content: View>: View {
  let title: String
  let content: Content

  init(title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.primary)
        .padding(.horizontal, 4)

      content
    }
  }
}

struct SettingsToggleRow: View {
  let title: String
  let description: String
  @Binding var isOn: Bool

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.headline)
          .foregroundColor(.primary)

        Text(description)
          .font(.caption)
          .foregroundColor(.primary.opacity(0.6))
      }

      Spacer()

      Toggle("", isOn: $isOn)
        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#A0C4FF")))
    }
  }
}

#Preview {
  SettingsView()
}
