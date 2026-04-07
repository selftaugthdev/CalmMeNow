import SwiftData
import SwiftUI

struct MainTabView: View {
  @EnvironmentObject var deepLinkManager: DeepLinkManager
  @Environment(\.modelContext) private var modelContext
  @StateObject private var paywallManager = PaywallManager.shared
  @State private var showingEmergencyCalm = false
  @State private var showingNightProtocol = false
  @State private var showingPaywall = false

  var body: some View {
    TabView {
      // Home Tab
      HomeView()
        .tabItem {
          Image(systemName: "house.fill")
          Text("Home")
        }

      // Tools Tab
      ToolsView()
        .tabItem {
          Image(systemName: "leaf.fill")
          Text("Tools")
        }

      // My Plan Tab
      MyPlanView()
        .tabItem {
          Image(systemName: "puzzlepiece.fill")
          Text("My Plan")
        }

      // Journal Tab
      JournalListView()
        .tabItem {
          Image(systemName: "book.fill")
          Text("Journal")
        }
    }
    .accentColor(Color(hex: "#A0C4FF"))
    .preferredColorScheme(.light)  // Force light mode for tab bar
    .fullScreenCover(isPresented: $showingEmergencyCalm) {
      EmergencyCalmView()
    }
    .fullScreenCover(isPresented: $showingNightProtocol) {
      NightProtocolView()
    }
    .fullScreenCover(isPresented: $showingPaywall) {
      PaywallView()
    }
    .onReceive(paywallManager.$shouldShowPaywall) { shouldShow in
      showingPaywall = shouldShow
    }
    .onReceive(deepLinkManager.$shouldShowEmergencyCalm) { shouldShow in
      if shouldShow {
        showingEmergencyCalm = true
        deepLinkManager.resetEmergencyCalm()
      }
    }
    .onReceive(deepLinkManager.$shouldShowNightProtocol) { shouldShow in
      if shouldShow {
        showingNightProtocol = true
        deepLinkManager.resetNightProtocol()
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .watchMoodEntryReceived)) { notification in
      guard let score = notification.userInfo?["score"] as? Int,
            let date = notification.userInfo?["date"] as? TimeInterval else { return }
      let entry = MoodEntry(score: score, tags: ["watch"], timestamp: Date(timeIntervalSince1970: date))
      modelContext.insert(entry)
    }
    .onAppear {
      PhoneWCSessionHandler.shared.activate()
    }
  }
}

struct JournalListView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var journalEntries: [JournalEntry]
  @StateObject private var biometricAuth = BiometricAuthManager.shared
  @State private var showingNewEntry = false
  @State private var selectedEntry: JournalEntry?
  @State private var showingEntryDetail = false

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

        if biometricAuth.isAuthenticated {
          // Journal content
          VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
              Text("📝 Your Journal")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)

              Text("Your thoughts are private and secure")
                .font(.subheadline)
                .foregroundColor(.black.opacity(0.7))
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Journal entries list
            if journalEntries.isEmpty {
              VStack(spacing: 20) {
                Spacer()

                Image(systemName: "book.closed")
                  .font(.system(size: 60))
                  .foregroundColor(.black.opacity(0.3))

                Text("This is your space.")
                  .font(.title2)
                  .fontWeight(.medium)
                  .foregroundColor(.black)

                Text("Write whenever you're ready.\nNo pressure, no rules.")
                  .font(.body)
                  .foregroundColor(.black.opacity(0.7))
                  .multilineTextAlignment(.center)
                  .padding(.horizontal, 40)

                Spacer()

                StreakCardView(progressTracker: ProgressTracker.shared)
                  .padding(.horizontal, 20)
                  .onLongPressGesture(minimumDuration: 3) {
                    ProgressTracker.shared.resetStreakData()
                  }
                  .onTapGesture(count: 2) {
                    let calendar = Calendar.current
                    if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) {
                      ProgressTracker.shared.addUsageForDate(yesterday)
                    }
                  }
                  .onTapGesture(count: 3) {
                    ProgressTracker.shared.addUsageForConsecutiveDays(5)
                  }
              }
            } else {
              ScrollView {
                LazyVStack(spacing: 12) {
                  ForEach(journalEntries.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                    JournalEntryCard(entry: entry) {
                      selectedEntry = entry
                      showingEntryDetail = true
                    }
                  }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                StreakCardView(progressTracker: ProgressTracker.shared)
                  .padding(.horizontal, 20)
                  .padding(.top, 12)
                  .padding(.bottom, 20)
                  .onLongPressGesture(minimumDuration: 3) {
                    ProgressTracker.shared.resetStreakData()
                  }
                  .onTapGesture(count: 2) {
                    let calendar = Calendar.current
                    if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) {
                      ProgressTracker.shared.addUsageForDate(yesterday)
                    }
                  }
                  .onTapGesture(count: 3) {
                    ProgressTracker.shared.addUsageForConsecutiveDays(5)
                  }
              }
            }

            // New entry button
            Button(action: {
              showingNewEntry = true
            }) {
              HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                  .font(.title2)
                Text("New Entry")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              .foregroundColor(.white)
              .padding(.vertical, 16)
              .padding(.horizontal, 24)
              .background(
                RoundedRectangle(cornerRadius: 25)
                  .fill(Color.black.opacity(0.7))
              )
            }
            .padding(.bottom, 30)
          }
        } else {
          // Authentication prompt
          VStack(spacing: 30) {
            Image(systemName: biometricAuth.biometricType == .faceID ? "faceid" : "touchid")
              .font(.system(size: 80))
              .foregroundColor(.black.opacity(0.6))

            VStack(spacing: 16) {
              Text("Secure Your Journal")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)

              Text(
                "Use \(biometricAuth.getBiometricTypeString()) to access your private journal entries"
              )
              .font(.title3)
              .foregroundColor(.black.opacity(0.8))
              .multilineTextAlignment(.center)
              .padding(.horizontal, 40)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

            Button(action: {
              Task {
                await biometricAuth.authenticate()
              }
            }) {
              HStack(spacing: 12) {
                Image(systemName: biometricAuth.biometricType == .faceID ? "faceid" : "touchid")
                  .font(.title2)
                Text("Authenticate with \(biometricAuth.getBiometricTypeString())")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              .foregroundColor(.white)
              .padding(.vertical, 16)
              .padding(.horizontal, 24)
              .background(
                RoundedRectangle(cornerRadius: 25)
                  .fill(Color.black.opacity(0.7))
              )
            }
          }
          .padding(.horizontal, 20)
        }
      }
      .navigationBarHidden(true)
    }
    .navigationViewStyle(.stack)  // Force single-column layout on iPad
    .sheet(isPresented: $showingNewEntry) {
      NewJournalEntryView(
        onSave: { content, factors in
          addNewEntry(content: content, contributingFactors: factors)
        },
        emotionContext: nil,
        intensityContext: nil
      )
    }
    .sheet(isPresented: $showingEntryDetail) {
      if let entry = selectedEntry {
        JournalEntryDetailView(entry: entry)
      }
    }
    .onAppear {
      if !biometricAuth.isBiometricAvailable() {
        // If no biometric auth available, allow access
        biometricAuth.isAuthenticated = true
      }
    }
  }

  private func addNewEntry(content: String, contributingFactors: [String] = []) {
    let newEntry = JournalEntry(
      content: content,
      contributingFactors: contributingFactors
    )
    modelContext.insert(newEntry)

    do {
      try modelContext.save()
    } catch {
      print("Error saving journal entry: \(error)")
    }
  }
}

#Preview {
  MainTabView()
    .modelContainer(for: JournalEntry.self)
}
