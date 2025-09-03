import SwiftUI

struct DailyCheckInView: View {
  @StateObject private var viewModel = AIServiceViewModel()
  @Environment(\.dismiss) private var dismiss

  @State private var mood: Int = 3
  @State private var selectedTags: [String] = []
  @State private var note: String = ""
  @State private var newTag: String = ""

  private let commonTags = [
    "poor-sleep", "work-stress", "social-anxiety", "health-concerns",
    "financial-worry", "relationship-issues", "overwhelmed", "irritable",
    "restless", "concentrating-difficulty", "appetite-changes", "low-energy",
  ]

  private let moodDescriptions = [
    1: "Very Distressed",
    2: "Distressed",
    3: "Neutral",
    4: "Calm",
    5: "Very Calm",
  ]

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          // Header
          VStack(spacing: 8) {
            Image(systemName: "heart.text.square")
              .font(.system(size: 50))
              .foregroundColor(.blue)

            Text("Daily Check-in")
              .font(.title2)
              .fontWeight(.bold)

            Text("How are you feeling today?")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .padding(.top)

          // Mood Selection
          VStack(alignment: .leading, spacing: 16) {
            Text("Current Mood")
              .font(.headline)

            HStack(spacing: 20) {
              ForEach(1...5, id: \.self) { moodLevel in
                VStack(spacing: 8) {
                  Button(action: {
                    mood = moodLevel
                  }) {
                    Image(systemName: moodLevel <= mood ? "heart.fill" : "heart")
                      .font(.system(size: 30))
                      .foregroundColor(moodLevel <= mood ? .red : .gray)
                  }

                  Text("\(moodLevel)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
              }
            }
            .frame(maxWidth: .infinity)

            Text(moodDescriptions[mood] ?? "Neutral")
              .font(.subheadline)
              .foregroundColor(.blue)
              .frame(maxWidth: .infinity)
          }

          // Tags Selection
          VStack(alignment: .leading, spacing: 16) {
            Text("What's affecting you today?")
              .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
              ForEach(commonTags, id: \.self) { tag in
                Button(action: {
                  if selectedTags.contains(tag) {
                    selectedTags.removeAll { $0 == tag }
                  } else {
                    selectedTags.append(tag)
                  }
                }) {
                  Text(tag.replacingOccurrences(of: "-", with: " ").capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(selectedTags.contains(tag) ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(selectedTags.contains(tag) ? .white : .primary)
                    .cornerRadius(16)
                }
              }
            }

            HStack {
              TextField("Add custom tag", text: $newTag)
                .textFieldStyle(RoundedBorderTextFieldStyle())

              Button("Add") {
                if !newTag.isEmpty {
                  let formattedTag = newTag.lowercased().replacingOccurrences(of: " ", with: "-")
                  selectedTags.append(formattedTag)
                  newTag = ""
                }
              }
              .disabled(newTag.isEmpty)
            }
          }

          // Note Section
          VStack(alignment: .leading, spacing: 12) {
            Text("Additional Notes (Optional)")
              .font(.headline)

            TextField("How are you feeling? Any specific concerns?", text: $note, axis: .vertical)
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .lineLimit(3...6)
          }

          // Submit Button
          Button(action: {
            Task {
              await viewModel.submitDailyCheckIn(
                mood: mood,
                tags: selectedTags,
                note: note
              )
            }
          }) {
            HStack {
              if viewModel.isLoading {
                ProgressView()
                  .progressViewStyle(CircularProgressViewStyle(tint: .white))
                  .scaleEffect(0.8)
              } else {
                Image(systemName: "paperplane.fill")
              }

              Text(viewModel.isLoading ? "Submitting..." : "Submit Check-in")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
          }
          .disabled(viewModel.isLoading)

          if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
              .foregroundColor(.red)
              .font(.caption)
              .multilineTextAlignment(.center)
          }
        }
        .padding()
      }
      .navigationTitle("Daily Check-in")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
    .sheet(item: $viewModel.lastCheckIn) { checkIn in
      CheckInResponseView(checkIn: checkIn)
    }
  }
}

struct CheckInResponseView: View {
  let checkIn: DailyCheckInResponse
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          // Header
          VStack(spacing: 16) {
            Image(
              systemName: checkIn.severity >= 2
                ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
            )
            .font(.system(size: 60))
            .foregroundColor(checkIn.severity >= 2 ? .orange : .green)

            Text(checkIn.message)
              .font(.title2)
              .fontWeight(.bold)
              .multilineTextAlignment(.center)

            if checkIn.severity >= 2 {
              Text("We're here to help you through this")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }
          }
          .padding(.top)

          // Severity Indicator
          HStack {
            Image(systemName: "gauge")
              .foregroundColor(.blue)

            Text(
              "Current Level: \(checkIn.severity == 1 ? "Low" : checkIn.severity == 2 ? "Medium" : "High")"
            )
            .font(.subheadline)

            Spacer()
          }
          .padding()
          .background(Color.gray.opacity(0.1))
          .cornerRadius(12)

          // Recommendations
          if !checkIn.recommendations.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
              Text("Recommendations")
                .font(.headline)

              ForEach(Array(checkIn.recommendations.enumerated()), id: \.offset) {
                index, recommendation in
                HStack(alignment: .top, spacing: 12) {
                  Text("\(index + 1)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 25, height: 25)
                    .background(Color.blue)
                    .clipShape(Circle())

                  Text(recommendation)
                    .font(.body)

                  Spacer()
                }
              }
            }
          }

          // Exercise or Resources
          if let exercise = checkIn.exercise {
            VStack(alignment: .leading, spacing: 12) {
              Text("Suggested Exercise")
                .font(.headline)

              Text(exercise)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
          }

          if let resources = checkIn.resources, !resources.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
              Text("Helpful Resources")
                .font(.headline)

              ForEach(resources, id: \.self) { resource in
                HStack {
                  Image(systemName: "link")
                    .foregroundColor(.blue)

                  Text(resource)
                    .font(.body)

                  Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
              }
            }
          }

          // Action Buttons
          VStack(spacing: 12) {
            if let exercise = checkIn.exercise {
              Button(action: {
                // Navigate to exercise view
                dismiss()
              }) {
                HStack {
                  Image(systemName: "play.fill")
                  Text("Start Exercise")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
              }
            }

            Button(action: {
              dismiss()
            }) {
              Text("Continue")
                .font(.headline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
          }
        }
        .padding()
      }
      .navigationTitle("Check-in Response")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}

#Preview {
  DailyCheckInView()
}
