import SwiftUI

struct DailyCoachView: View {
  @Environment(\.presentationMode) var presentationMode
  @State private var mood: Int = 4  // 1-10
  @State private var tags: Set<String> = ["tired"]
  @State private var note: String = ""
  @State private var checkinResult: [String: Any]?
  @State private var isLoading = false
  @State private var error: String?
  @State private var showingPanicPlan = false
  @State private var showingExercise = false

  var body: some View {
    NavigationView {
      ZStack {
        // Background gradient
        LinearGradient(
          gradient: Gradient(colors: [
            Color(hex: "#E8F4FD"),
            Color(hex: "#F0F8FF"),
            Color(hex: "#E6F3FF"),
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        ScrollView {
          VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
              Text("💙")
                .font(.system(size: 60))

              Text("Daily Check-in Coach")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color(.label))

              Text("Take 30 seconds to reset and get support")
                .font(.body)
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

              // Premium badge
              HStack {
                Image(systemName: "crown.fill")
                  .foregroundColor(.orange)
                  .font(.caption)
                Text("Daily Check-in is part of your Premium support")
                  .font(.caption)
                  .foregroundColor(Color(.secondaryLabel))
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color.orange.opacity(0.1))
              )
            }
            .padding(.top, 20)

            // Check-in Form
            VStack(spacing: 20) {
              Text("How's your mood right now?")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(.label))

              // Mood Slider
              VStack(spacing: 12) {
                HStack {
                  Text("😢")
                    .font(.title2)
                  Spacer()
                  Text("😐")
                    .font(.title2)
                  Spacer()
                  Text("🙂")
                    .font(.title2)
                  Spacer()
                  Text("😄")
                    .font(.title2)
                }

                HStack {
                  Text("1")
                    .font(.caption)
                    .foregroundColor(Color(.secondaryLabel))
                  Slider(
                    value: Binding(
                      get: { Double(mood) },
                      set: { mood = Int($0) }
                    ), in: 1...10, step: 1
                  )
                  .accentColor(.blue)
                  Text("10")
                    .font(.caption)
                    .foregroundColor(Color(.secondaryLabel))
                }

                // Mood labels
                HStack {
                  Text("Low / Drained")
                    .font(.caption)
                    .foregroundColor(Color(.secondaryLabel))
                  Spacer()
                  Text("Calm / Strong")
                    .font(.caption)
                    .foregroundColor(Color(.secondaryLabel))
                }

                Text("Mood: \(mood)")
                  .font(.headline)
                  .fontWeight(.medium)
                  .foregroundColor(Color(.label))
              }
              .padding(.horizontal, 20)

              // Tags
              VStack(alignment: .leading, spacing: 12) {
                Text("What's taking your energy today?")
                  .font(.headline)
                  .fontWeight(.semibold)
                  .foregroundColor(Color(.label))

                TagPicker(
                  tags: [
                    "tired", "work", "social", "health", "family", "sleep", "anxious",
                    "overwhelmed",
                  ],
                  selection: $tags
                )
              }
              .padding(.horizontal, 20)

              // Note
              VStack(alignment: .leading, spacing: 8) {
                Text("Anything specific on your mind? (optional)")
                  .font(.headline)
                  .fontWeight(.semibold)
                  .foregroundColor(Color(.label))

                TextField("Share what's weighing on you...", text: $note, axis: .vertical)
                  .textFieldStyle(RoundedBorderTextFieldStyle())
                  .lineLimit(3...6)
              }
              .padding(.horizontal, 20)

              // Check-in Button
              Button(action: runCheckIn) {
                HStack(spacing: 12) {
                  if isLoading {
                    ProgressView()
                      .progressViewStyle(CircularProgressViewStyle(tint: .white))
                      .scaleEffect(0.8)
                  } else {
                    Text("💙")
                      .font(.title2)
                  }
                  Text(isLoading ? "Processing..." : "Get Support")
                    .font(.headline)
                    .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                  RoundedRectangle(cornerRadius: 25)
                    .fill(Color.blue)
                )
              }
              .disabled(isLoading)
              .padding(.horizontal, 20)
            }
            .padding(20)
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 20)

            // Results Section
            if let result = checkinResult {
              VStack(spacing: 20) {
                Text("Your Check-in Results")
                  .font(.title2)
                  .fontWeight(.bold)
                  .foregroundColor(Color(.label))

                // Severity Display
                if let severity = result["severity"] as? Int {
                  SeverityCard(severity: severity)
                }

                // Action Buttons
                if let severity = result["severity"] as? Int, severity >= 2 {
                  // High severity - show exercise and panic plan options
                  VStack(spacing: 16) {
                    Button(action: { showingExercise = true }) {
                      HStack(spacing: 12) {
                        Image(systemName: "figure.mind.and.body")
                          .font(.title2)
                        Text("Do an Exercise Now")
                          .font(.headline)
                          .fontWeight(.semibold)
                      }
                      .foregroundColor(.white)
                      .frame(maxWidth: .infinity)
                      .padding(.vertical, 16)
                      .background(
                        RoundedRectangle(cornerRadius: 25)
                          .fill(Color.orange)
                      )
                    }

                    Button(action: { showingPanicPlan = true }) {
                      HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                          .font(.title2)
                        Text("Open Panic Plan")
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
                  }
                  .padding(.horizontal, 20)
                } else {
                  // Low severity - show micro-exercise
                  if let exercise = result["exercise"] as? [String: Any] {
                    MicroExerciseCard(exercise: exercise)
                  }
                }

                // Debug Info (can be removed in production)
                if let debugInfo = result["debug"] as? String {
                  Text(debugInfo)
                    .font(.caption)
                    .foregroundColor(Color(.secondaryLabel))
                    .padding(.horizontal, 20)
                }
              }
              .padding(20)
              .background(
                RoundedRectangle(cornerRadius: 16)
                  .fill(Color(.systemBackground))
                  .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
              )
              .padding(.horizontal, 20)
            }

            // Error Display
            if let error = error {
              VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                  .font(.title)
                  .foregroundColor(.red)

                Text("Something went wrong")
                  .font(.headline)
                  .fontWeight(.semibold)
                  .foregroundColor(Color(.label))

                Text(error)
                  .font(.body)
                  .foregroundColor(Color(.secondaryLabel))
                  .multilineTextAlignment(.center)
              }
              .padding(20)
              .background(
                RoundedRectangle(cornerRadius: 16)
                  .fill(Color(.systemBackground))
                  .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
              )
              .padding(.horizontal, 20)
            }

            Spacer(minLength: 40)
          }
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarItems(
        leading: Button("Close") {
          presentationMode.wrappedValue.dismiss()
        }
        .foregroundColor(.blue)
      )
      .sheet(isPresented: $showingPanicPlan) {
        PersonalizedPanicPlanView()
      }
      .sheet(isPresented: $showingExercise) {
        // TODO: Create ExerciseView for the micro-exercise
        Text("Exercise View - Coming Soon!")
      }
    }
  }

  private func runCheckIn() {
    isLoading = true
    error = nil
    checkinResult = nil

    let checkin: [String: Any] = [
      "mood": mood,
      "tags": Array(tags),
      "note": note,
    ]

    Task {
      do {
        let result = try await AiService.shared.dailyCheckIn(checkin: checkin)
        await MainActor.run {
          checkinResult = result
          isLoading = false
        }
      } catch {
        await MainActor.run {
          self.error = error.localizedDescription
          isLoading = false
        }
      }
    }
  }
}

// MARK: - Supporting Views

struct SeverityCard: View {
  let severity: Int

  var severityColor: Color {
    switch severity {
    case 0: return .green
    case 1: return .blue
    case 2: return .orange
    case 3: return .red
    default: return .gray
    }
  }

  var severityText: String {
    switch severity {
    case 0: return "Feeling Good"
    case 1: return "Mild Concern"
    case 2: return "Moderate Concern"
    case 3: return "High Concern"
    default: return "Unknown"
    }
  }

  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: severity == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
        .font(.title)
        .foregroundColor(severityColor)

      VStack(alignment: .leading, spacing: 4) {
        Text(severityText)
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(Color(.label))

        Text("Severity Level: \(severity)")
          .font(.subheadline)
          .foregroundColor(Color(.secondaryLabel))
      }

      Spacer()
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(severityColor.opacity(0.1))
    )
  }
}

struct MicroExerciseCard: View {
  let exercise: [String: Any]
  @State private var showBreathing = false
  @State private var showGenericExercise = false
  @State private var exerciseModel: Exercise?
  @State private var isLaunchingExercise = false

  var body: some View {
    VStack(spacing: 16) {
      HStack {
        Image(systemName: "figure.mind.and.body")
          .font(.title)
          .foregroundColor(.blue)

        VStack(alignment: .leading, spacing: 4) {
          Text(exercise["title"] as? String ?? "Micro-Exercise")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(Color(.label))

          if let duration = exercise["duration_sec"] as? Int {
            Text("\(duration) seconds")
              .font(.subheadline)
              .foregroundColor(Color(.secondaryLabel))
          }
        }

        Spacer()
      }

      if let steps = exercise["steps"] as? [String] {
        VStack(alignment: .leading, spacing: 8) {
          Text("Steps:")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(Color(.label))

          ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
            HStack(spacing: 8) {
              Text("\(index + 1).")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.blue)

              Text(step)
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
            }
          }
        }
      }

      Button(action: {
        guard !isLaunchingExercise else { return }
        isLaunchingExercise = true

        print("Start Exercise tapped")  // Debug logging

        // Create Exercise model from dictionary
        if let exerciseObj = Exercise.fromAIResponse(exercise) {
          exerciseModel = exerciseObj

          if exerciseObj.isBreathingExercise {
            // Launch breathing exercise
            showBreathing = true
          } else {
            // Launch generic exercise view
            showGenericExercise = true
          }
        } else {
          // Fallback to default breathing exercise
          exerciseModel = Exercise(
            id: UUID(),
            title: "Breathing Exercise",
            duration: 60,
            steps: ["Inhale slowly", "Hold", "Exhale slowly"],
            prompt: nil
          )
          showBreathing = true
        }

        // Reset debounce after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
          isLaunchingExercise = false
        }
      }) {
        HStack(spacing: 8) {
          Image(systemName: "play.fill")
          Text(isLaunchingExercise ? "Starting..." : "Start Exercise")
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(Color.blue)
        )
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.blue.opacity(0.1))
    )
    .sheet(isPresented: $showBreathing) {
      if let exercise = exerciseModel, let plan = exercise.breathingPlan {
        BreathingExerciseView(plan: plan)
      } else {
        BreathingExerciseView()
      }
    }
    .sheet(isPresented: $showGenericExercise) {
      if let exercise = exerciseModel {
        GenericExerciseView(exercise: exercise)
      }
    }
  }
}

// MARK: - Tag Picker

struct TagPicker: View {
  let tags: [String]
  @Binding var selection: Set<String>

  var body: some View {
    WrapHStack(spacing: 8) {
      ForEach(tags, id: \.self) { tag in
        let isSelected = selection.contains(tag)
        Button(action: {
          if isSelected {
            selection.remove(tag)
          } else {
            selection.insert(tag)
          }
        }) {
          Text(tag.capitalized)
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
              Capsule()
                .fill(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .blue : Color(.label))
        }
        .buttonStyle(PlainButtonStyle())
      }
    }
  }
}

// MARK: - Wrap HStack

struct WrapHStack<Content: View>: View {
  let spacing: CGFloat
  @ViewBuilder let content: () -> Content

  init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
    self.spacing = spacing
    self.content = content
  }

  var body: some View {
    FlowLayout(spacing: spacing) {
      content()
    }
  }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
  let spacing: CGFloat

  init(spacing: CGFloat = 8) {
    self.spacing = spacing
  }

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let result = FlowResult(
      in: proposal.replacingUnspecifiedDimensions().width,
      subviews: subviews,
      spacing: spacing
    )
    return result.size
  }

  func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    let result = FlowResult(
      in: bounds.width,
      subviews: subviews,
      spacing: spacing
    )
    for (index, subview) in subviews.enumerated() {
      subview.place(
        at: CGPoint(
          x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y),
        proposal: .unspecified)
    }
  }
}

struct FlowResult {
  let positions: [CGPoint]
  let size: CGSize

  init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
    var positions: [CGPoint] = []
    var currentX: CGFloat = 0
    var currentY: CGFloat = 0
    var lineHeight: CGFloat = 0
    var maxWidthUsed: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)

      if currentX + size.width > maxWidth && currentX > 0 {
        currentX = 0
        currentY += lineHeight + spacing
        lineHeight = 0
      }

      positions.append(CGPoint(x: currentX, y: currentY))
      currentX += size.width + spacing
      lineHeight = max(lineHeight, size.height)
      maxWidthUsed = max(maxWidthUsed, currentX)
    }

    self.positions = positions
    self.size = CGSize(width: maxWidthUsed, height: currentY + lineHeight)
  }
}

#Preview {
  DailyCoachView()
}
