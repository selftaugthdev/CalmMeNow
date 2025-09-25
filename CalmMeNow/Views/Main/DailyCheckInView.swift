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
  @State private var activeExercise: Exercise?
  @State private var isLaunchingExercise = false
  @State private var selectedPath: CoachPath = .quickReset
  @State private var selectedReframe: String?
  @State private var showProcessItFlow = false
  @State private var currentProcessStep = 0

  enum CoachPath {
    case quickReset
    case processIt
  }

  // Computed properties with fallbacks
  private var coachLine: String {
    checkIn.coachLine ?? "I hear you. Let's take a moment to reset and choose your next step."
  }

  private var quickResetSteps: [String] {
    checkIn.quickResetSteps ?? [
      "Sit comfortably with your feet flat on the floor",
      "Take a deep breath in through your nose for 4 seconds",
      "Hold your breath gently for 4 seconds",
      "Exhale slowly through your mouth for 6 seconds",
      "Repeat this breathing pattern for 3 cycles",
    ]
  }

  private var processItSteps: [String] {
    checkIn.processItSteps ?? [
      "Label the feeling",
      "Choose a reframe",
      "Pick an action",
    ]
  }

  private var reframeChips: [String] {
    checkIn.reframeChips ?? [
      "I'm safe in this moment",
      "This feeling will pass",
      "I can handle this one step at a time",
    ]
  }

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

          // Coach Line (with fallback)
          VStack(spacing: 12) {
            Text(coachLine)
              .font(.headline)
              .foregroundColor(.primary)
              .multilineTextAlignment(.center)
              .padding()
              .background(Color.blue.opacity(0.1))
              .cornerRadius(12)

            // Two Path Selection
            HStack(spacing: 12) {
              Button(action: {
                selectedPath = .quickReset
                showProcessItFlow = false
              }) {
                VStack(spacing: 4) {
                  Image(systemName: "wind")
                    .font(.title2)
                  Text("Quick Reset")
                    .font(.caption)
                    .fontWeight(.medium)
                  Text("60-90s")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .foregroundColor(selectedPath == .quickReset ? .white : .blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedPath == .quickReset ? Color.blue : Color.blue.opacity(0.1))
                .cornerRadius(12)
              }

              Button(action: {
                selectedPath = .processIt
                showProcessItFlow = true
                currentProcessStep = 0
              }) {
                VStack(spacing: 4) {
                  Image(systemName: "brain.head.profile")
                    .font(.title2)
                  Text("Process It")
                    .font(.caption)
                    .fontWeight(.medium)
                  Text("2-3 min")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .foregroundColor(selectedPath == .processIt ? .white : .blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedPath == .processIt ? Color.blue : Color.blue.opacity(0.1))
                .cornerRadius(12)
              }
            }
          }

          // Quick Reset Flow
          if selectedPath == .quickReset {
            QuickResetView(steps: quickResetSteps, onStartExercise: startQuickResetExercise)
          }

          // Process It Flow
          if selectedPath == .processIt && showProcessItFlow {
            ProcessItFlowView(
              steps: processItSteps,
              reframeChips: reframeChips,
              selectedReframe: $selectedReframe,
              currentStep: $currentProcessStep
            )
          }

          // Micro Insight (with fallback)
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
              Text("Insight")
                .font(.headline)
              Spacer()
            }

            Text(
              checkIn.microInsight
                ?? "Taking time to check in with yourself is a powerful act of self-care."
            )
            .font(.body)
            .foregroundColor(.secondary)
          }
          .padding()
          .background(Color.yellow.opacity(0.1))
          .cornerRadius(12)

          // If-Then Plan (with fallback)
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Image(systemName: "arrow.clockwise")
                .foregroundColor(.green)
              Text("Save as Plan")
                .font(.headline)
              Spacer()
            }

            Text(
              checkIn.ifThenPlan
                ?? "If I feel overwhelmed, then I'll do 3 rounds of breathing and choose one small action."
            )
            .font(.body)
            .foregroundColor(.secondary)

            Button("Save Plan") {
              // TODO: Save to user's plans
              let plan =
                checkIn.ifThenPlan
                ?? "If I feel overwhelmed, then I'll do 3 rounds of breathing and choose one small action."
              print("Saving plan: \(plan)")
            }
            .font(.caption)
            .foregroundColor(.green)
            .padding(.top, 4)
          }
          .padding()
          .background(Color.green.opacity(0.1))
          .cornerRadius(12)

          // Severity Indicator (for high severity cases)
          if checkIn.severity >= 2 {
            HStack {
              Image(systemName: "gauge")
                .foregroundColor(.orange)

              Text(
                "Current Level: \(checkIn.severity == 2 ? "Medium" : "High")"
              )
              .font(.subheadline)

              Spacer()
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
          }

          // Resources (for high severity)
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

          // Continue Button
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
        .padding()
      }
      .navigationTitle("Coach Response")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
      .sheet(item: $activeExercise) { exercise in
        if exercise.isBreathingExercise, let plan = exercise.breathingPlan {
          BreathingExerciseView(plan: plan)
        } else if exercise.isBreathingExercise {
          BreathingExerciseView()
        } else {
          GenericExerciseView(exercise: exercise)
        }
      }
    }
  }

  private func startQuickResetExercise() {
    guard !isLaunchingExercise && activeExercise == nil else { return }
    isLaunchingExercise = true

    // Create Exercise model for quick reset
    activeExercise = Exercise(
      id: UUID(),
      title: "Quick Reset Breathing",
      duration: 90,
      steps: quickResetSteps,
      prompt: nil
    )

    // Reset debounce after 1 second
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      isLaunchingExercise = false
    }
  }
}

// MARK: - Quick Reset View
struct QuickResetView: View {
  let steps: [String]
  let onStartExercise: () -> Void
  @State private var currentStep = 0
  @State private var isRunning = false

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "wind")
          .foregroundColor(.blue)
        Text("Quick Reset Steps")
          .font(.headline)
        Spacer()
        Text("\(currentStep + 1)/\(steps.count)")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      if isRunning {
        VStack(alignment: .leading, spacing: 8) {
          ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
            HStack(alignment: .top, spacing: 12) {
              Circle()
                .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 20, height: 20)
                .overlay(
                  Text("\(index + 1)")
                    .font(.caption)
                    .foregroundColor(index <= currentStep ? .white : .gray)
                )

              Text(step)
                .font(.body)
                .foregroundColor(index <= currentStep ? .primary : .secondary)

              Spacer()
            }
          }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
      } else {
        Button(action: {
          isRunning = true
          startExercise()
        }) {
          HStack {
            Image(systemName: "play.fill")
            Text("Start Quick Reset")
          }
          .font(.headline)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue)
          .cornerRadius(12)
        }
      }
    }
  }

  private func startExercise() {
    onStartExercise()

    // Auto-advance through steps
    for i in 0..<steps.count {
      DispatchQueue.main.asyncAfter(deadline: .now() + Double(i * 15)) {
        currentStep = i
      }
    }
  }
}

// MARK: - Process It Flow View
struct ProcessItFlowView: View {
  let steps: [String]
  let reframeChips: [String]
  @Binding var selectedReframe: String?
  @Binding var currentStep: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "brain.head.profile")
          .foregroundColor(.purple)
        Text("Process It Flow")
          .font(.headline)
        Spacer()
        Text("\(currentStep + 1)/\(steps.count)")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      VStack(alignment: .leading, spacing: 16) {
        // Step 1: Label the feeling
        if currentStep >= 0 {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Circle()
                .fill(Color.purple)
                .frame(width: 20, height: 20)
                .overlay(
                  Text("1")
                    .font(.caption)
                    .foregroundColor(.white)
                )
              Text("Label the feeling")
                .font(.headline)
            }

            Text("What's the main emotion you're feeling right now?")
              .font(.body)
              .foregroundColor(.secondary)

            if currentStep == 0 {
              Button("I'm feeling...") {
                currentStep = 1
              }
              .font(.headline)
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.purple)
              .cornerRadius(12)
            }
          }
        }

        // Step 2: Choose a reframe
        if currentStep >= 1 {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Circle()
                .fill(Color.purple)
                .frame(width: 20, height: 20)
                .overlay(
                  Text("2")
                    .font(.caption)
                    .foregroundColor(.white)
                )
              Text("Choose a reframe")
                .font(.headline)
            }

            Text("Select a helpful perspective:")
              .font(.body)
              .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 8) {
              ForEach(reframeChips, id: \.self) { reframe in
                Button(action: {
                  selectedReframe = reframe
                  currentStep = 2
                }) {
                  Text(reframe)
                    .font(.body)
                    .foregroundColor(selectedReframe == reframe ? .white : .purple)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                      selectedReframe == reframe ? Color.purple : Color.purple.opacity(0.1)
                    )
                    .cornerRadius(12)
                }
              }
            }
          }
        }

        // Step 3: Pick an action
        if currentStep >= 2 {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Circle()
                .fill(Color.purple)
                .frame(width: 20, height: 20)
                .overlay(
                  Text("3")
                    .font(.caption)
                    .foregroundColor(.white)
                )
              Text("Pick an action")
                .font(.headline)
            }

            Text("Choose one small step you can take right now:")
              .font(.body)
              .foregroundColor(.secondary)

            VStack(spacing: 8) {
              Button("Take 3 deep breaths") {
                // Complete the flow
              }
              .font(.body)
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.purple)
              .cornerRadius(12)

              Button("Go for a short walk") {
                // Complete the flow
              }
              .font(.body)
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.purple)
              .cornerRadius(12)

              Button("Let it go for now") {
                // Complete the flow
              }
              .font(.body)
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.purple)
              .cornerRadius(12)
            }
          }
        }
      }
      .padding()
      .background(Color.purple.opacity(0.05))
      .cornerRadius(12)
    }
  }
}

#Preview {
  DailyCheckInView()
}
