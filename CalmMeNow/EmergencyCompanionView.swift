import SwiftUI

struct EmergencyCompanionView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var audioManager = AudioManager.shared
  @StateObject private var progressTracker = ProgressTracker.shared
  @AppStorage("prefSounds") private var prefSounds = true

  @State private var currentMessage = ""
  @State private var messages: [CompanionMessage] = []
  @State private var isTyping = false
  @State private var showingCrisisResources = false
  @State private var showingBreathingGuide = false

  var body: some View {
    NavigationView {
      ZStack {
        // Background gradient
        LinearGradient(
          gradient: Gradient(colors: [
            Color(hex: "#FFF5F5"),
            Color(hex: "#FEF2F2"),
            Color(hex: "#FEE2E2"),
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 0) {
          // Header
          VStack(spacing: 12) {
            Text("🤖")
              .font(.system(size: 50))

            Text("Emergency Companion")
              .font(.title)
              .fontWeight(.bold)
              .foregroundColor(.primary)

            Text("I'm here to help you through this moment")
              .font(.body)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 20)
          }
          .padding(.top, 20)
          .padding(.bottom, 20)

          // Messages
          ScrollViewReader { proxy in
            ScrollView {
              LazyVStack(spacing: 16) {
                // Welcome message
                if messages.isEmpty {
                  CompanionMessageView(
                    message: CompanionMessage(
                      id: UUID().uuidString,
                      text:
                        "Hi there. I'm here to help you through this difficult moment. What's going on?",
                      isFromUser: false,
                      timestamp: Date()
                    )
                  )
                }

                // Existing messages
                ForEach(messages) { message in
                  CompanionMessageView(message: message)
                }

                // Typing indicator
                if isTyping {
                  HStack {
                    Text("🤖")
                      .font(.title2)

                    HStack(spacing: 4) {
                      ForEach(0..<3) { index in
                        Circle()
                          .fill(Color.gray.opacity(0.6))
                          .frame(width: 8, height: 8)
                          .scaleEffect(isTyping ? 1.2 : 0.8)
                          .animation(
                            Animation.easeInOut(duration: 0.6)
                              .repeatForever()
                              .delay(Double(index) * 0.2),
                            value: isTyping
                          )
                      }
                    }

                    Spacer()
                  }
                  .padding(.horizontal, 20)
                }
              }
              .padding(.horizontal, 20)
              .padding(.bottom, 100)  // Space for input
            }
            .onChange(of: messages.count) { _ in
              if let lastMessage = messages.last {
                withAnimation(.easeInOut(duration: 0.3)) {
                  proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
              }
            }
          }

          Spacer()

          // Input area
          VStack(spacing: 16) {
            // Quick action buttons
            if messages.isEmpty {
              QuickActionButtons(
                onBreathing: {
                  showingBreathingGuide = true
                },
                onCrisisResources: {
                  showingCrisisResources = true
                },
                onSendMessage: { message in
                  sendMessage(message)
                }
              )
              .padding(.horizontal, 20)

              // AI Emergency Companion Button
              Button(action: {
                // Present the AI Emergency Companion
                let aiView = EmergencyCompanionAIView()
                let hostingController = UIHostingController(rootView: aiView)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first
                {
                  window.rootViewController?.present(hostingController, animated: true)
                }
              }) {
                HStack(spacing: 12) {
                  Image(systemName: "bolt.fill")
                    .font(.title2)
                  Text("AI Emergency Companion")
                    .font(.headline)
                    .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                  RoundedRectangle(cornerRadius: 25)
                    .fill(Color.red)
                )
              }
              .padding(.horizontal, 20)
            }

            // Text input
            HStack(spacing: 12) {
              TextField("Type your message...", text: $currentMessage, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...3)

              Button(action: sendCurrentMessage) {
                Image(systemName: "paperplane.fill")
                  .foregroundColor(.white)
                  .padding(12)
                  .background(
                    Circle()
                      .fill(currentMessage.isEmpty ? Color.gray : Color.blue)
                  )
              }
              .disabled(currentMessage.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
          }
          .background(
            Rectangle()
              .fill(Color.white.opacity(0.9))
              .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -4)
          )
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarItems(
        leading: Button("Close") {
          presentationMode.wrappedValue.dismiss()
        }
        .foregroundColor(.blue)
      )
      .sheet(isPresented: $showingCrisisResources) {
        CrisisResourcesView()
      }
      .sheet(isPresented: $showingBreathingGuide) {
        EmergencyBreathingGuideView()
      }
      .onAppear {
        progressTracker.recordUsage()
      }
    }
  }

  private func sendCurrentMessage() {
    guard !currentMessage.isEmpty else { return }
    sendMessage(currentMessage)
    currentMessage = ""
  }

  private func sendMessage(_ text: String) {
    let userMessage = CompanionMessage(
      id: UUID().uuidString,
      text: text,
      isFromUser: true,
      timestamp: Date()
    )
    messages.append(userMessage)

    // Simulate AI response
    isTyping = true

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      isTyping = false

      let response = generateAIResponse(to: text)
      let aiMessage = CompanionMessage(
        id: UUID().uuidString,
        text: response,
        isFromUser: false,
        timestamp: Date()
      )
      messages.append(aiMessage)
    }
  }

  private func generateAIResponse(to message: String) -> String {
    let lowercased = message.lowercased()

    // Simple keyword-based responses
    if lowercased.contains("panic") || lowercased.contains("anxious")
      || lowercased.contains("scared")
    {
      return
        "I understand you're feeling panicked right now. Let's take this one step at a time. Can you try taking 3 deep breaths with me? Inhale slowly through your nose, hold for a moment, then exhale through your mouth. You're safe, and this feeling will pass."
    } else if lowercased.contains("sad") || lowercased.contains("depressed")
      || lowercased.contains("hopeless")
    {
      return
        "I hear that you're feeling really down right now. Your feelings are valid, and it's okay to not be okay. You don't have to go through this alone. Is there someone you trust that you could reach out to? Or would you like to try a grounding exercise together?"
    } else if lowercased.contains("angry") || lowercased.contains("frustrated")
      || lowercased.contains("mad")
    {
      return
        "I can see you're feeling angry, and that's completely understandable. Anger is a natural emotion. Let's try to find a healthy way to express it. Can you tell me more about what happened? Sometimes talking it out can help us process our feelings."
    } else if lowercased.contains("alone") || lowercased.contains("lonely")
      || lowercased.contains("isolated")
    {
      return
        "Feeling alone can be really hard. Even though it might feel like it right now, you're not truly alone. I'm here with you, and there are people who care about you. Would you like to try reaching out to someone, or would you prefer to work through this together first?"
    } else if lowercased.contains("help") || lowercased.contains("suicide")
      || lowercased.contains("kill")
    {
      return
        "I'm really concerned about what you're going through. You're not alone, and there are people who want to help you. Please consider calling a crisis hotline or reaching out to a mental health professional. Your life has value, and you deserve support."
    } else {
      return
        "Thank you for sharing that with me. I'm here to listen and support you. Can you tell me more about how you're feeling right now? Sometimes talking about our emotions can help us process them better."
    }
  }
}

// MARK: - Supporting Types

struct CompanionMessage: Identifiable {
  let id: String
  let text: String
  let isFromUser: Bool
  let timestamp: Date
}

// MARK: - Message View

struct CompanionMessageView: View {
  let message: CompanionMessage

  var body: some View {
    HStack {
      if message.isFromUser {
        Spacer()

        VStack(alignment: .trailing, spacing: 4) {
          Text(message.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
              RoundedRectangle(cornerRadius: 18)
                .fill(Color.blue)
            )
            .foregroundColor(.white)

          Text(formatTime(message.timestamp))
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      } else {
        VStack(alignment: .leading, spacing: 4) {
          HStack(alignment: .top, spacing: 8) {
            Text("🤖")
              .font(.title2)

            Text(message.text)
              .padding(.horizontal, 16)
              .padding(.vertical, 12)
              .background(
                RoundedRectangle(cornerRadius: 18)
                  .fill(Color.white)
                  .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
              )
              .foregroundColor(.primary)
          }

          Text(formatTime(message.timestamp))
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.leading, 36)
        }

        Spacer()
      }
    }
  }

  private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}

// MARK: - Quick Action Buttons

struct QuickActionButtons: View {
  let onBreathing: () -> Void
  let onCrisisResources: () -> Void
  let onSendMessage: (String) -> Void

  private let quickMessages = [
    "I'm having a panic attack",
    "I feel really sad",
    "I'm so angry right now",
    "I feel alone",
    "I need immediate help",
  ]

  var body: some View {
    VStack(spacing: 12) {
      // Action buttons
      HStack(spacing: 12) {
        Button(action: onBreathing) {
          HStack(spacing: 8) {
            Image(systemName: "lungs.fill")
            Text("Breathing Guide")
          }
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(.white)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(
            RoundedRectangle(cornerRadius: 20)
              .fill(Color.green)
          )
        }

        Button(action: onCrisisResources) {
          HStack(spacing: 8) {
            Image(systemName: "phone.fill")
            Text("Crisis Help")
          }
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(.white)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(
            RoundedRectangle(cornerRadius: 20)
              .fill(Color.red)
          )
        }
      }

      // Quick message buttons
      LazyVGrid(
        columns: [
          GridItem(.flexible()),
          GridItem(.flexible()),
        ], spacing: 8
      ) {
        ForEach(quickMessages, id: \.self) { message in
          Button(action: {
            onSendMessage(message)
          }) {
            Text(message)
              .font(.caption)
              .foregroundColor(.blue)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(Color.blue, lineWidth: 1)
              )
          }
        }
      }
    }
  }
}

// MARK: - Crisis Resources View

struct CrisisResourcesView: View {
  @Environment(\.presentationMode) var presentationMode

  private let crisisResources = [
    CrisisResource(
      name: "National Suicide Prevention Lifeline",
      number: "988",
      description: "24/7 crisis support and suicide prevention",
      isEmergency: true
    ),
    CrisisResource(
      name: "Crisis Text Line",
      number: "Text HOME to 741741",
      description: "Free 24/7 crisis counseling via text",
      isEmergency: true
    ),
    CrisisResource(
      name: "Emergency Services",
      number: "911",
      description: "For immediate life-threatening emergencies",
      isEmergency: true
    ),
    CrisisResource(
      name: "SAMHSA National Helpline",
      number: "1-800-662-HELP",
      description: "Treatment referral and information service",
      isEmergency: false
    ),
  ]

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 20) {
          // Header
          VStack(spacing: 12) {
            Text("🆘")
              .font(.system(size: 50))

            Text("Crisis Resources")
              .font(.title)
              .fontWeight(.bold)
              .foregroundColor(.primary)

            Text("If you're in crisis, these resources can help")
              .font(.body)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 20)
          }
          .padding(.top, 20)

          // Resources
          VStack(spacing: 16) {
            ForEach(crisisResources) { resource in
              CrisisResourceCard(resource: resource)
            }
          }
          .padding(.horizontal, 20)

          // Disclaimer
          VStack(spacing: 8) {
            Text("Important")
              .font(.headline)
              .fontWeight(.semibold)
              .foregroundColor(.red)

            Text(
              "If you're having thoughts of harming yourself or others, please call 911 or go to the nearest emergency room immediately."
            )
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 16)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(Color.red.opacity(0.1))
          )
          .padding(.horizontal, 20)

          Spacer(minLength: 40)
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarItems(
        trailing: Button("Done") {
          presentationMode.wrappedValue.dismiss()
        }
        .foregroundColor(.blue)
      )
    }
  }
}

struct CrisisResource: Identifiable {
  let id = UUID()
  let name: String
  let number: String
  let description: String
  let isEmergency: Bool
}

struct CrisisResourceCard: View {
  let resource: CrisisResource

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(resource.name)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.primary)

          Text(resource.description)
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

        if resource.isEmergency {
          Text("EMERGENCY")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.red)
            )
        }
      }

      Button(action: {
        if resource.number.contains("Text") {
          // Handle text line
          if let url = URL(string: "sms:741741&body=HOME") {
            UIApplication.shared.open(url)
          }
        } else {
          // Handle phone call
          if let url = URL(string: "tel:\(resource.number.replacingOccurrences(of: "-", with: ""))")
          {
            UIApplication.shared.open(url)
          }
        }
      }) {
        HStack {
          Image(systemName: resource.number.contains("Text") ? "message.fill" : "phone.fill")
          Text(resource.number)
            .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
          RoundedRectangle(cornerRadius: 25)
            .fill(resource.isEmergency ? Color.red : Color.blue)
        )
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    )
  }
}

// MARK: - Emergency Breathing Guide

struct EmergencyBreathingGuideView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var audioManager = AudioManager.shared
  @AppStorage("prefSounds") private var prefSounds = true

  @State private var breathingPhase: BreathingPhase = .inhale
  @State private var timeRemaining = 4
  @State private var isActive = false

  enum BreathingPhase {
    case inhale, hold, exhale

    var instruction: String {
      switch self {
      case .inhale: return "Breathe In"
      case .hold: return "Hold"
      case .exhale: return "Breathe Out"
      }
    }

    var emoji: String {
      switch self {
      case .inhale: return "🫁"
      case .hold: return "⏸️"
      case .exhale: return "💨"
      }
    }
  }

  var body: some View {
    ZStack {
      // Background gradient
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "#E8F4FD"),
          Color(hex: "#F0F8FF"),
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 40) {
        // Header
        VStack(spacing: 16) {
          Text("🌬️")
            .font(.system(size: 60))

          Text("Emergency Breathing")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.primary)

          Text("Follow the rhythm to calm your nervous system")
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
        }
        .padding(.top, 40)

        Spacer()

        // Breathing circle
        VStack(spacing: 20) {
          ZStack {
            Circle()
              .stroke(Color.blue.opacity(0.3), lineWidth: 4)
              .frame(width: 200, height: 200)

            Circle()
              .fill(Color.blue.opacity(0.1))
              .frame(width: 200, height: 200)
              .scaleEffect(isActive ? 1.2 : 0.8)
              .animation(
                Animation.easeInOut(duration: TimeInterval(timeRemaining))
                  .repeatForever(autoreverses: true),
                value: isActive
              )

            VStack(spacing: 8) {
              Text(breathingPhase.emoji)
                .font(.system(size: 40))

              Text(breathingPhase.instruction)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

              Text("\(timeRemaining)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            }
          }
        }

        Spacer()

        // Controls
        VStack(spacing: 16) {
          if !isActive {
            Button(action: startBreathing) {
              HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                  .font(.title2)
                Text("Start Breathing Exercise")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              .foregroundColor(.white)
              .padding(.vertical, 16)
              .padding(.horizontal, 32)
              .background(
                RoundedRectangle(cornerRadius: 25)
                  .fill(Color.blue)
              )
            }
          } else {
            Button(action: stopBreathing) {
              HStack(spacing: 12) {
                Image(systemName: "stop.circle.fill")
                  .font(.title2)
                Text("Stop")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              .foregroundColor(.white)
              .padding(.vertical, 16)
              .padding(.horizontal, 32)
              .background(
                RoundedRectangle(cornerRadius: 25)
                  .fill(Color.red)
              )
            }
          }
        }
        .padding(.bottom, 40)
      }
    }
    .navigationBarHidden(true)
    .onDisappear {
      stopBreathing()
    }
  }

  private func startBreathing() {
    isActive = true
    timeRemaining = 4
    breathingPhase = .inhale

    if prefSounds {
      audioManager.playSound("perfect-beauty-1-min", loop: true)
    }

    startBreathingCycle()
  }

  private func stopBreathing() {
    isActive = false
    audioManager.stopSound()
  }

  private func startBreathingCycle() {
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
      guard isActive else {
        timer.invalidate()
        return
      }

      if timeRemaining > 0 {
        timeRemaining -= 1
      } else {
        // Move to next phase
        switch breathingPhase {
        case .inhale:
          breathingPhase = .hold
          timeRemaining = 4
        case .hold:
          breathingPhase = .exhale
          timeRemaining = 6
        case .exhale:
          breathingPhase = .inhale
          timeRemaining = 4
        }
      }
    }
  }
}

#Preview {
  EmergencyCompanionView()
}
