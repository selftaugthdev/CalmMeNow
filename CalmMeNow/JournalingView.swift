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
        onSave: { content, factors in
          addNewEntry(content: content, contributingFactors: factors)
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

  private func addNewEntry(content: String, contributingFactors: [String] = []) {
    let newEntry = JournalEntry(
      content: content,
      emotion: emotionContext,
      intensity: intensityContext,
      contributingFactors: contributingFactors.isEmpty ? nil : contributingFactors
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

            // Contributing factors
            if let factors = entry.contributingFactors, !factors.isEmpty {
              Text("Factors: \(factors.prefix(3).joined(separator: ", "))")
                .font(.caption2)
                .foregroundColor(.black.opacity(0.6))
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
  @State private var selectedFactors: Set<String> = []
  @State private var customFactor = ""
  @State private var showingFactorsSection = false
  let onSave: (String, [String]) -> Void
  let emotionContext: String?
  let intensityContext: String?

  private let commonFactors = [
    "Stress", "Work", "Family", "Health", "Sleep", "Caffeine", "Alcohol", "Exercise",
    "Social Media", "News", "Financial", "Relationship", "Weather", "Crowds", "Noise", "Hunger",
    "Pain", "Medication", "Travel", "Change",
  ]

  var body: some View {
    NavigationView {
      ZStack {
        Color(hex: "#A0C4FF").ignoresSafeArea()

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

          ScrollView {
            VStack(spacing: 20) {

              // Simple Contributing Factors Section
              VStack(alignment: .leading, spacing: 8) {
                HStack {
                  Text("Contributing Factors")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)

                  Spacer()

                  Button(action: {
                    showingFactorsSection.toggle()
                  }) {
                    Image(systemName: showingFactorsSection ? "chevron.up" : "chevron.down")
                      .foregroundColor(.black.opacity(0.6))
                  }
                }

                if showingFactorsSection {
                  VStack(alignment: .leading, spacing: 8) {
                    Text("Common factors:")
                      .font(.caption)
                      .fontWeight(.medium)
                      .foregroundColor(.black)

                    LazyVGrid(
                      columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 4
                    ) {
                      ForEach(commonFactors, id: \.self) { factor in
                        Button(action: {
                          if selectedFactors.contains(factor) {
                            selectedFactors.remove(factor)
                          } else {
                            selectedFactors.insert(factor)
                          }
                        }) {
                          Text(factor)
                            .font(.caption)
                            .foregroundColor(selectedFactors.contains(factor) ? .white : .black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                              RoundedRectangle(cornerRadius: 4)
                                .fill(
                                  selectedFactors.contains(factor)
                                    ? Color.blue : Color.white.opacity(0.8))
                            )
                            .overlay(
                              RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                            )
                        }
                      }
                    }

                    HStack {
                      TextField("Add custom factor...", text: $customFactor)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.caption)

                      Button("Add") {
                        if !customFactor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                          selectedFactors.insert(
                            customFactor.trimmingCharacters(in: .whitespacesAndNewlines))
                          customFactor = ""
                        }
                      }
                      .disabled(
                        customFactor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if !selectedFactors.isEmpty {
                      Text("Selected: \(Array(selectedFactors).joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.black)
                    }
                  }
                  .padding(8)
                  .background(Color.white.opacity(0.9))
                  .cornerRadius(8)
                }
              }
              .padding(.horizontal, 20)

              TextEditor(text: $entryText)
                .font(.body)
                .foregroundColor(.white)
                .padding(16)
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.7))
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
                            .padding(.leading, 36)
                            .padding(.top, 24)
                          Spacer()
                        }
                        Spacer()
                      }
                    }
                  }
                )

              Spacer()

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
                    onSave(entryText, Array(selectedFactors))
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
              .padding(.bottom, 20)
            }
          }
        }
        .navigationBarHidden(true)
      }
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
      return "How are you feeling today? What's on your mind?"
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

              // Contributing factors in detail view
              if let factors = entry.contributingFactors, !factors.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                  Divider()
                    .background(Color.black.opacity(0.2))

                  Text("Contributing Factors")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)

                  LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8)
                  {
                    ForEach(entry.contributingFactors ?? [], id: \.self) { factor in
                      Text(factor)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                          RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue)
                        )
                    }
                  }
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

// MARK: - Contributing Factors View
struct ContributingFactorsView: View {
  @Binding var selectedFactors: Set<String>
  @Binding var customFactor: String
  @Binding var showingFactorsSection: Bool
  let commonFactors: [String]

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("Contributing Factors")
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(.black)

        Spacer()

        Button(action: {
          withAnimation(.easeInOut(duration: 0.3)) {
            showingFactorsSection.toggle()
          }
        }) {
          Image(systemName: showingFactorsSection ? "chevron.up" : "chevron.down")
            .foregroundColor(.black.opacity(0.6))
        }
      }

      if showingFactorsSection {
        VStack(alignment: .leading, spacing: 12) {
          // Common factors grid
          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 6) {
            ForEach(commonFactors, id: \.self) { factor in
              FactorButton(
                factor: factor,
                isSelected: selectedFactors.contains(factor),
                onTap: {
                  if selectedFactors.contains(factor) {
                    selectedFactors.remove(factor)
                  } else {
                    selectedFactors.insert(factor)
                  }
                }
              )
            }
          }

          // Custom factor input
          HStack {
            Text("Custom:")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundColor(.black)

            TextField("Add custom factor...", text: $customFactor)
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .font(.caption)

            Button(action: {
              if !customFactor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                selectedFactors.insert(customFactor.trimmingCharacters(in: .whitespacesAndNewlines))
                customFactor = ""
              }
            }) {
              Image(systemName: "plus.circle.fill")
                .foregroundColor(.blue)
                .font(.title3)
            }
            .disabled(customFactor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          }

          // Selected factors display
          if !selectedFactors.isEmpty {
            SelectedFactorsView(selectedFactors: $selectedFactors)
          }
        }
        .padding(12)
        .background(
          RoundedRectangle(cornerRadius: 10)
            .fill(Color.white.opacity(0.9))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 10)
            .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
      }
    }
    .padding(.horizontal, 20)
  }
}

struct FactorButton: View {
  let factor: String
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .foregroundColor(isSelected ? .blue : .gray)
          .font(.caption)
        Text(factor)
          .font(.caption)
          .foregroundColor(.black)
          .lineLimit(1)
        Spacer()
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(isSelected ? Color.blue.opacity(0.1) : Color.white.opacity(0.8))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 6)
          .stroke(isSelected ? Color.blue : Color.black.opacity(0.2), lineWidth: 1)
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

struct SelectedFactorsView: View {
  @Binding var selectedFactors: Set<String>

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Selected:")
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(.black)

      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 4) {
        ForEach(Array(selectedFactors), id: \.self) { factor in
          HStack {
            Text(factor)
              .font(.caption2)
              .foregroundColor(.white)
              .lineLimit(1)

            Spacer()

            Button(action: {
              selectedFactors.remove(factor)
            }) {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(.white.opacity(0.8))
                .font(.caption2)
            }
          }
          .padding(.horizontal, 6)
          .padding(.vertical, 3)
          .background(
            RoundedRectangle(cornerRadius: 4)
              .fill(Color.blue)
          )
        }
      }
    }
  }
}
