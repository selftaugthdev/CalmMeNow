import SwiftData
import SwiftUI

struct MainTabView: View {
  var body: some View {
    TabView {
      // Home Tab
      ContentView()
        .tabItem {
          Image(systemName: "house.fill")
          Text("Home")
        }

      // Journal Tab
      JournalListView()
        .tabItem {
          Image(systemName: "book.fill")
          Text("Journal")
        }

      // Settings Tab
      SettingsView()
        .tabItem {
          Image(systemName: "gear")
          Text("Settings")
        }
    }
    .accentColor(Color(hex: "#A0C4FF"))
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
            Color(hex: "#D0BFFF"),  // Soft Purple
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

                Text("No journal entries yet")
                  .font(.title2)
                  .fontWeight(.medium)
                  .foregroundColor(.black)

                Text("Start writing to track your thoughts and feelings")
                  .font(.body)
                  .foregroundColor(.black.opacity(0.7))
                  .multilineTextAlignment(.center)
                  .padding(.horizontal, 40)

                Spacer()
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
