import SwiftUI

struct SettingsView: View {
  @AppStorage("watchEndBehavior") private var watchEndBehavior: Int = 1
  @AppStorage("prefSounds") private var prefSounds: Bool = true
  @AppStorage("prefHaptics") private var prefHaptics: Bool = true
  @AppStorage("prefVoice") private var prefVoice: Bool = false
  @AppStorage("userCalmingPhrase") private var userCalmingPhrase =
    "This feeling will pass, I am safe"

  // App version
  private var appVersion: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    return "\(version) (\(build))"
  }

  // Paywall integration
  @StateObject private var paywallManager = PaywallManager.shared
  @StateObject private var revenueCatService = RevenueCatService.shared
  @State private var showingPaywall = false

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
              // Watch Integration Settings - Commented out for MVP launch
              /*
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
              */

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

                  Divider()
                    .background(Color.black.opacity(0.1))

                  // Calming Phrase Setting
                  VStack(alignment: .leading, spacing: 8) {
                    HStack {
                      VStack(alignment: .leading, spacing: 4) {
                        Text("Personal Calming Phrase")
                          .font(.headline)
                          .foregroundColor(.primary)

                        Text("Your personalized phrase for panic plan steps")
                          .font(.caption)
                          .foregroundColor(.primary.opacity(0.6))
                      }

                      Spacer()
                    }

                    TextField("Enter your calming phrase", text: $userCalmingPhrase)
                      .textFieldStyle(RoundedBorderTextFieldStyle())
                      .font(.body)
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

                // Enhanced Voice Banner
                if prefVoice {
                  CompactEnhancedVoiceBanner()
                }
              }

              // AI Settings
              SettingsSection(title: "🤖 AI Assistant") {
                VStack(spacing: 16) {
                  HStack {
                    VStack(alignment: .leading, spacing: 4) {
                      Text("Personalized Features")
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

                    Text("Personalized Features Configured")
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

              // Premium Features Section
              SettingsSection(title: "Premium Features") {
                VStack(spacing: 16) {
                  // Premium Feature Row
                  SettingsFeatureRow(
                    icon: "infinity",
                    iconColor: .orange,
                    title: "Unlimited AI Sessions",
                    description: "Generate unlimited personalized calming plans",
                    isPremium: true
                  )

                  Divider()
                    .background(Color.black.opacity(0.1))

                  SettingsFeatureRow(
                    icon: "brain.head.profile",
                    iconColor: .yellow,
                    title: "Advanced Personalization",
                    description:
                      "Personalized features learn from your preferences and mood patterns",
                    isPremium: true
                  )

                  Divider()
                    .background(Color.black.opacity(0.1))

                  SettingsFeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .yellow,
                    title: "Progress Tracking",
                    description: "Track your calming journey and mood improvements",
                    isPremium: true
                  )

                  Divider()
                    .background(Color.black.opacity(0.1))

                  // Restore Purchases - Only show if user is subscribed
                  if revenueCatService.isSubscribed {
                    SettingsActionRow(
                      icon: "arrow.clockwise",
                      iconColor: .blue,
                      title: "Restore Purchases",
                      description: "Restore your previous purchases",
                      action: {
                        Task {
                          do {
                            let restored = try await revenueCatService.restorePurchases()
                            if restored {
                              // Show success message or handle restoration
                              print("Purchases restored successfully")
                            }
                          } catch {
                            print("Failed to restore purchases: \(error.localizedDescription)")
                          }
                        }
                      }
                    )

                    Divider()
                      .background(Color.black.opacity(0.1))

                    // Manage Account - Only show if user is subscribed
                    SettingsActionRow(
                      icon: "person.circle",
                      iconColor: .green,
                      title: "Manage Account",
                      description: "View subscription details and manage billing",
                      action: {
                        openSubscriptionManagement()
                      }
                    )

                    Divider()
                      .background(Color.black.opacity(0.1))
                  }

                  // Upgrade Button - Only show if user is NOT subscribed
                  if !revenueCatService.isSubscribed {
                    SettingsActionRow(
                      icon: "crown.fill",
                      iconColor: .yellow,
                      title: "Upgrade to Premium",
                      description: "Unlock all premium features",
                      showPrice: true,
                      price: "$4.99/month",
                      action: {
                        showingPaywall = true
                      }
                    )
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

              // Privacy & Security Section
              SettingsSection(title: "Privacy & Security") {
                VStack(spacing: 16) {
                  SettingsActionRow(
                    icon: "hand.raised.fill",
                    iconColor: .blue,
                    title: "Privacy Policy",
                    description: "How we protect your data",
                    action: {
                      if let url = URL(
                        string:
                          "https://destiny-fender-4ad.notion.site/CalmMeNow-Privacy-Policy-26777834762b80798c5ade6a83b6a88c"
                      ) {
                        UIApplication.shared.open(url)
                      }
                    }
                  )

                  Divider()
                    .background(Color.black.opacity(0.1))

                  SettingsActionRow(
                    icon: "doc.text.fill",
                    iconColor: .blue,
                    title: "Terms of Service",
                    description: "App usage terms and conditions",
                    action: {
                      if let url = URL(
                        string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
                      {
                        UIApplication.shared.open(url)
                      }
                    }
                  )

                  Divider()
                    .background(Color.black.opacity(0.1))

                  SettingsActionRow(
                    icon: "externaldrive.fill",
                    iconColor: .blue,
                    title: "Data & Storage",
                    description: "Manage your data and storage",
                    action: {
                      // TODO: Implement data & storage management
                    }
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

              // About Section
              SettingsSection(title: "About") {
                VStack(spacing: 16) {
                  HStack {
                    Text("Version")
                      .foregroundColor(.primary)
                    Spacer()
                    Text(appVersion)
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
      .sheet(isPresented: $showingPaywall) {
        PaywallKitView()
      }
    }
  }

  // MARK: - Helper Functions

  private func openSubscriptionManagement() {
    #if targetEnvironment(simulator)
      // In simulator, show an alert instead of opening App Store
      DispatchQueue.main.async {
        let alert = UIAlertController(
          title: "Manage Account",
          message:
            "In the simulator, you can't access App Store subscription management. On a real device, this would open your subscription settings where you can cancel or modify your subscription.",
          preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first
        {
          window.rootViewController?.present(alert, animated: true)
        }
      }
    #else
      // On real device, open the App Store subscription management page
      if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
        UIApplication.shared.open(url)
      }
    #endif
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

struct SettingsFeatureRow: View {
  let icon: String
  let iconColor: Color
  let title: String
  let description: String
  let isPremium: Bool

  var body: some View {
    HStack {
      Image(systemName: icon)
        .foregroundColor(iconColor)
        .font(.title2)
        .frame(width: 24, height: 24)

      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(title)
            .font(.headline)
            .foregroundColor(.primary)

          if isPremium {
            Image(systemName: "crown.fill")
              .foregroundColor(.yellow)
              .font(.caption)
          }
        }

        Text(description)
          .font(.caption)
          .foregroundColor(.primary.opacity(0.6))
      }

      Spacer()
    }
  }
}

struct SettingsActionRow: View {
  let icon: String
  let iconColor: Color
  let title: String
  let description: String
  let showPrice: Bool
  let price: String?
  let action: () -> Void

  init(
    icon: String, iconColor: Color, title: String, description: String, showPrice: Bool = false,
    price: String? = nil, action: @escaping () -> Void
  ) {
    self.icon = icon
    self.iconColor = iconColor
    self.title = title
    self.description = description
    self.showPrice = showPrice
    self.price = price
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      HStack {
        Image(systemName: icon)
          .foregroundColor(iconColor)
          .font(.title2)
          .frame(width: 24, height: 24)

        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.headline)
            .foregroundColor(.primary)

          Text(description)
            .font(.caption)
            .foregroundColor(.primary.opacity(0.6))
        }

        Spacer()

        if showPrice, let price = price {
          Text(price)
            .font(.caption)
            .foregroundColor(.primary.opacity(0.6))
        } else {
          Image(systemName: "chevron.right")
            .foregroundColor(.primary.opacity(0.3))
            .font(.caption)
        }
      }
    }
    .buttonStyle(PlainButtonStyle())
  }
}

#Preview {
  SettingsView()
}
