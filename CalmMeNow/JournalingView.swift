import SwiftData
import SwiftUI

struct JournalingView: View {
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.modelContext) private var modelContext
  @Query private var journalEntries: [JournalEntry]

  @StateObject private var biometricAuth = BiometricAuthManager.shared
  @State private var newEntryText = ""
  @State private var showingNewEntry = false
  @State private var showingAuthPrompt = false
  @State private var selectedEntry: JournalEntry?
  @State private var showingEntryDetail = false

  // Optional emotion context for new entries
  let emotionContext: String?
  let intensityContext: String?

  init(emotionContext: String? = nil, intensityContext: String? = nil) {
    self.emotionContext = emotionContext
    self.intensityContext = intensityContext
  }

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
            // Header with close button
            HStack {
              Spacer()

              Button(action: {
                presentationMode.wrappedValue.dismiss()
              }) {
                Image(systemName: "xmark.circle.fill")
                  .font(.title2)
                  .foregroundColor(.black.opacity(0.6))
              }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

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
            .padding(.top, 10)

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

            Button("Close") {
              presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.black.opacity(0.6))
            .padding(.top, 20)
          }
          .padding(.horizontal, 20)
        }
      }
      .navigationBarHidden(true)
    }
    .sheet(isPresented: $showingNewEntry) {
      NewJournalEntryView(
        onSave: { content in
          addNewEntry(content: content)
        },
        emotionContext: emotionContext,
        intensityContext: intensityContext
      )
    }
    .sheet(isPresented: $showingEntryDetail) {
      if let entry = selectedEntry {
        JournalEntryDetailView(entry: entry)
      }
    }
    .onAppear {
      if biometricAuth.isBiometricAvailable() {
        showingAuthPrompt = true
      } else {
        // If no biometric auth available, allow access
        biometricAuth.isAuthenticated = true
      }
    }
  }

  private func addNewEntry(content: String) {
    let newEntry = JournalEntry(
      content: content,
      emotion: emotionContext,
      intensity: intensityContext
    )
    modelContext.insert(newEntry)

    do {
      try modelContext.save()
    } catch {
      print("Error saving journal entry: \(error)")
    }
  }
}

struct JournalEntryCard: View {
  let entry: JournalEntry
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text(entry.content)
            .font(.body)
            .foregroundColor(.black)
            .lineLimit(3)
            .multilineTextAlignment(.leading)

          Spacer()

          Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundColor(.black.opacity(0.5))
        }

        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text(formatDate(entry.timestamp))
              .font(.caption)
              .foregroundColor(.black.opacity(0.6))

            if let emotion = entry.emotion {
              HStack(spacing: 4) {
                Text(emotion.capitalized)
                  .font(.caption)
                  .fontWeight(.medium)
                  .foregroundColor(.white)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 4)
                  .background(
                    RoundedRectangle(cornerRadius: 8)
                      .fill(getEmotionColor(emotion))
                  )

                if let intensity = entry.intensity {
                  Text(intensity.capitalized)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                      RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.1))
                    )
                }
              }
            }
          }

          Spacer()
        }
      }
      .padding(16)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.white.opacity(0.9))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color.black.opacity(0.1), lineWidth: 1)
      )
    }
    .buttonStyle(PlainButtonStyle())
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }

  private func getEmotionColor(_ emotion: String) -> Color {
    switch emotion.lowercased() {
    case "anxious":
      return Color.blue
    case "angry":
      return Color.red
    case "sad":
      return Color.purple
    case "frustrated":
      return Color.orange
    default:
      return Color.gray
    }
  }
}

struct NewJournalEntryView: View {
  @Environment(\.presentationMode) var presentationMode
  @State private var entryText = ""
  let onSave: (String) -> Void
  let emotionContext: String?
  let intensityContext: String?

  init(
    onSave: @escaping (String) -> Void, emotionContext: String? = nil,
    intensityContext: String? = nil
  ) {
    self.onSave = onSave
    self.emotionContext = emotionContext
    self.intensityContext = intensityContext
  }

  var body: some View {
    NavigationView {
      ZStack {
        Color(hex: "#A0C4FF")
          .ignoresSafeArea()

        VStack(spacing: 20) {
          Text("Write Your Thoughts")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.black)
            .padding(.top, 20)

          Text("Express what's on your mind. This is completely private.")
            .font(.body)
            .foregroundColor(.black.opacity(0.7))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)

          TextEditor(text: $entryText)
            .font(.body)
            .foregroundColor(.black)
            .padding(16)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.9))
            )
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )
            .frame(minHeight: 200)
            .padding(.horizontal, 20)
            .overlay(
              Group {
                if entryText.isEmpty {
                  VStack {
                    HStack {
                      Text(getPlaceholderText())
                        .font(.body)
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.leading, 36)  // Increased from 20 to account for TextEditor padding
                        .padding(.top, 24)
                      Spacer()
                    }
                    Spacer()
                  }
                }
              }
            )

          HStack(spacing: 16) {
            Button("Cancel") {
              presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.black.opacity(0.6))
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
              RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.8))
            )

            Button("Save") {
              if !entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                onSave(entryText)
                presentationMode.wrappedValue.dismiss()
              }
            }
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
              RoundedRectangle(cornerRadius: 20)
                .fill(
                  entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? Color.gray : Color.black.opacity(0.7))
            )
            .disabled(entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          }

          Spacer()
        }
      }
      .navigationBarHidden(true)
    }
  }

  private func getPlaceholderText() -> String {
    if let emotion = emotionContext {
      if let intensity = intensityContext {
        return "I felt \(intensity.lowercased()) \(emotion.lowercased()) today..."
      } else {
        return "I felt \(emotion.lowercased()) today..."
      }
    } else {
      return "I felt really anxious today after someone cut me off in traffic."
    }
  }
}

struct JournalEntryDetailView: View {
  @Environment(\.presentationMode) var presentationMode
  let entry: JournalEntry

  var body: some View {
    NavigationView {
      ZStack {
        Color(hex: "#A0C4FF")
          .ignoresSafeArea()

        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            Text("Journal Entry")
              .font(.largeTitle)
              .fontWeight(.bold)
              .foregroundColor(.black)
              .padding(.top, 20)

            VStack(alignment: .leading, spacing: 16) {
              Text(entry.content)
                .font(.body)
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)

              Divider()
                .background(Color.black.opacity(0.2))

              HStack {
                Text(formatDate(entry.timestamp))
                  .font(.caption)
                  .foregroundColor(.black.opacity(0.6))

                Spacer()

                if let emotion = entry.emotion {
                  Text(emotion)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                      RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.1))
                    )
                }
              }
            }
            .padding(20)
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)

            Button("Close") {
              presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
              RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.7))
            )
            .padding(.top, 20)
          }
        }
      }
      .navigationBarHidden(true)
    }
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}
