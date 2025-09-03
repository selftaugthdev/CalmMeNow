import Firebase
import SwiftUI

struct PersonalizedPanicPlanView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var audioManager = AudioManager.shared
  @StateObject private var progressTracker = ProgressTracker.shared

  @AppStorage("prefSounds") private var prefSounds = true

  @State private var selectedPlan: PanicPlan?
  @State private var showingPlanEditor = false
  @State private var showingPlanExecution = false

  // Sample panic plans - in a real app, these would be stored in UserDefaults or Core Data
  @State private var userPlans: [PanicPlan] = [
    PanicPlan(
      title: "My Emergency Plan",
      description: "Quick relief for panic attacks",
      steps: [
        "Take 3 deep breaths",
        "Ground yourself with 5-4-3-2-1",
        "Listen to calming sounds",
        "Call a trusted friend if needed",
      ],
      duration: 120,
      techniques: ["Breathing", "Grounding", "Social Support"],
      personalizedPhrase: "I am safe and I can handle this"
    )
  ]

  @State private var isGeneratingAIPlan = false
  @State private var debugStatus = ""

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
              Text("🧩")
                .font(.system(size: 60))

              Text("Your Panic Plan")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color(.label))

              Text("Personalized emergency response plans for when you need them most")
                .font(.body)
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            }
            .padding(.top, 20)

            // Plans List
            VStack(spacing: 16) {
              ForEach(userPlans) { plan in
                PlanCard(
                  plan: plan,
                  onTap: {
                    selectedPlan = plan
                    showingPlanExecution = true
                  },
                  onEdit: {
                    selectedPlan = plan
                    showingPlanEditor = true
                  }
                )
              }
            }
            .padding(.horizontal, 20)

            // AI Intake Form
            VStack(spacing: 16) {
              Text("🤖 AI Plan Generator")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(.label))

              HStack {
                Text("Context:")
                  .font(.caption)
                  .foregroundColor(Color(.secondaryLabel))
                Spacer()
                Text("Public transport")
                  .font(.caption)
                  .foregroundColor(Color(.label))
                  .fontWeight(.medium)
              }

              HStack {
                Text("Breathing:")
                  .font(.caption)
                  .foregroundColor(Color(.secondaryLabel))
                Spacer()
                Text("Box breathing")
                  .font(.caption)
                  .foregroundColor(Color(.label))
                  .fontWeight(.medium)
              }

              HStack {
                Text("Duration:")
                  .font(.caption)
                  .foregroundColor(Color(.secondaryLabel))
                Spacer()
                Text("Short (60-120s)")
                  .font(.caption)
                  .foregroundColor(Color(.label))
                  .fontWeight(.medium)
              }
            }
            .padding(16)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .padding(.horizontal, 20)

            // AI-Generated Plan Button
            Button(action: {
              generateAIPanicPlan()
            }) {
              HStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                  .font(.title2)
                Text(isGeneratingAIPlan ? "Generating..." : "🤖 AI Create Plan")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              .foregroundColor(.white)
              .padding(.vertical, 16)
              .padding(.horizontal, 24)
              .background(
                RoundedRectangle(cornerRadius: 25)
                  .fill(Color.blue)
              )
            }
            .disabled(isGeneratingAIPlan)
            .padding(.horizontal, 20)

            // Debug AI Button (for testing)
            Button(action: {
              testAIDebug()
            }) {
              HStack(spacing: 12) {
                Image(systemName: "ladybug")
                  .font(.title2)
                Text("🐛 Debug AI")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              .foregroundColor(.white)
              .padding(.vertical, 16)
              .padding(.horizontal, 24)
              .background(
                RoundedRectangle(cornerRadius: 25)
                  .fill(Color.orange)
              )
            }
            .padding(.horizontal, 20)

            // Debug Status
            if !debugStatus.isEmpty {
              Text(debugStatus)
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
                .padding(.horizontal, 20)
            }

            // Add New Plan Button
            Button(action: {
              selectedPlan = nil
              showingPlanEditor = true
            }) {
              HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                  .font(.title2)
                Text("Create New Plan")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              .foregroundColor(.white)
              .padding(.vertical, 16)
              .padding(.horizontal, 24)
              .background(
                RoundedRectangle(cornerRadius: 25)
                  .fill(Color.blue)
              )
            }
            .padding(.top, 20)

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
      .sheet(isPresented: $showingPlanEditor) {
        PlanEditorView(
          plan: selectedPlan,
          onSave: { newPlan in
            if let existingPlan = selectedPlan,
              let index = userPlans.firstIndex(where: { $0.id == existingPlan.id })
            {
              userPlans[index] = newPlan
            } else {
              userPlans.append(newPlan)
            }
            showingPlanEditor = false
          }
        )
      }
      .sheet(isPresented: $showingPlanExecution) {
        if let plan = selectedPlan {
          PlanExecutionView(plan: plan)
        }
      }
    }
  }

  // MARK: - AI Methods

  /// Generate a personalized panic plan using AI
  private func generateAIPanicPlan() {
    isGeneratingAIPlan = true

    Task {
      do {
        // Use the new AiService for Firebase Functions integration
        let intake: [String: Any] = [
          "context": "public transport",
          "pref_breath": "box",
          "duration": "short",
        ]

        let result = try await AiService.shared.generatePanicPlan(intake: intake)

        // Parse the structured result from Firebase Functions
        await MainActor.run {
          let newPlan = PanicPlan(
            title: "AI-Generated Plan",
            description: "Personalized plan created just for you",
            steps: parseStructuredPlan(result),
            duration: extractDuration(from: result),
            techniques: extractTechniques(from: result),
            emergencyContact: nil,
            personalizedPhrase: "I am safe and I can handle this"
          )

          userPlans.append(newPlan)
          isGeneratingAIPlan = false
        }
      } catch {
        await MainActor.run {
          isGeneratingAIPlan = false
          // Could show an error alert here
        }
        print("AI Plan generation error:", error)
      }
    }
  }

  /// Parse structured plan from Firebase Functions response
  private func parseStructuredPlan(_ result: [String: Any]) -> [String] {
    guard let steps = result["steps"] as? [[String: Any]] else {
      return ["Take 5 deep breaths", "Ground yourself", "Listen to calming sounds"]
    }

    return steps.compactMap { step in
      if let type = step["type"] as? String {
        switch type {
        case "breathing":
          if let pattern = step["pattern"] as? String, let seconds = step["seconds"] as? Int {
            return "\(pattern.capitalized) breathing for \(seconds) seconds"
          }
        case "grounding":
          if let method = step["method"] as? String, let seconds = step["seconds"] as? Int {
            return "\(method.capitalized) grounding for \(seconds) seconds"
          }
        case "muscle_release":
          if let area = step["area"] as? String, let seconds = step["seconds"] as? Int {
            return "Release \(area) for \(seconds) seconds"
          }
        case "affirmation":
          if let text = step["text"] as? String, let seconds = step["seconds"] as? Int {
            return "Repeat: '\(text)' for \(seconds) seconds"
          }
        default:
          break
        }
      }
      return nil
    }.filter { !$0.isEmpty }
  }

  /// Extract duration from structured plan
  private func extractDuration(from result: [String: Any]) -> Int {
    // Calculate total duration from steps
    guard let steps = result["steps"] as? [[String: Any]] else { return 180 }

    let totalSeconds = steps.compactMap { step in
      step["seconds"] as? Int
    }.reduce(0, +)

    return max(60, min(180, totalSeconds))  // Ensure 60-180s range
  }

  /// Extract techniques from structured plan
  private func extractTechniques(from result: [String: Any]) -> [String] {
    guard let steps = result["steps"] as? [[String: Any]] else { return ["AI-Generated"] }

    let techniques = steps.compactMap { step in
      step["type"] as? String
    }.map { $0.capitalized }

    return techniques.isEmpty ? ["AI-Generated"] : techniques
  }

  /// Debug method to test AI service directly
  private func testAIDebug() {
    debugStatus = "Testing AI service..."
    Task {
      do {
        print("🧠 Testing AI Debug...")
        let result = try await AiService.shared.generatePlanDebug()
        print("✅ Debug result:", result)
        await MainActor.run {
          debugStatus = "✅ Debug successful! Check console for details."
        }
      } catch {
        print("❌ Debug error:", error)
        await MainActor.run {
          debugStatus = "❌ Debug failed: \(error.localizedDescription)"
        }
      }
    }
  }

}

// MARK: - Supporting Types

// Using the PanicPlan struct from PanicPlan.swift

// MARK: - Plan Card Component

struct PlanCard: View {
  let plan: PanicPlan
  let onTap: () -> Void
  let onEdit: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text(plan.title)
              .font(.title3)
              .fontWeight(.semibold)
              .foregroundColor(Color(.label))

            Text(plan.description)
              .font(.caption)
              .foregroundColor(Color(.secondaryLabel))
              .lineLimit(2)
          }

          Spacer()

          Button(action: onEdit) {
            Image(systemName: "pencil.circle.fill")
              .font(.title2)
              .foregroundColor(.blue)
          }
          .buttonStyle(PlainButtonStyle())
        }

        // Steps preview
        VStack(alignment: .leading, spacing: 4) {
          ForEach(Array(plan.steps.prefix(2).enumerated()), id: \.offset) { index, step in
            HStack(spacing: 8) {
              Text("\(index + 1).")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.blue)

              Text(step)
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
                .lineLimit(1)
            }
          }

          if plan.steps.count > 2 {
            Text("+ \(plan.steps.count - 2) more steps")
              .font(.caption)
              .foregroundColor(.blue)
          }
        }

        HStack {
          Label("\(Int(plan.duration / 60)) min", systemImage: "clock")
            .font(.caption)
            .foregroundColor(Color(.secondaryLabel))

          Spacer()

          // Note: isDefault property removed, using duration instead
          Text("\(plan.duration / 60) min")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.green)
            )
        }
      }
      .padding(16)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(.systemBackground))
          .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

// MARK: - Plan Editor View

struct PlanEditorView: View {
  @Environment(\.presentationMode) var presentationMode
  let plan: PanicPlan?
  let onSave: (PanicPlan) -> Void

  @State private var name: String = ""
  @State private var description: String = ""
  @State private var steps: [String] = [""]
  @State private var duration: TimeInterval = 120

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Plan Details")) {
          TextField("Plan Name", text: $name)
          TextField("Description", text: $description)
        }

        Section(header: Text("Steps")) {
          ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
            HStack {
              TextField("Step \(index + 1)", text: $steps[index])

              if steps.count > 1 {
                Button(action: {
                  steps.remove(at: index)
                }) {
                  Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
                }
              }
            }
          }

          Button("Add Step") {
            steps.append("")
          }
        }

        Section(header: Text("Duration")) {
          Picker("Duration", selection: $duration) {
            Text("1 minute").tag(TimeInterval(60))
            Text("2 minutes").tag(TimeInterval(120))
            Text("3 minutes").tag(TimeInterval(180))
            Text("5 minutes").tag(TimeInterval(300))
          }
        }
      }
      .navigationTitle(plan == nil ? "New Plan" : "Edit Plan")
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarItems(
        leading: Button("Cancel") {
          presentationMode.wrappedValue.dismiss()
        },
        trailing: Button("Save") {
          let newPlan = PanicPlan(
            title: name,
            description: description,
            steps: steps.filter { !$0.isEmpty },
            duration: Int(duration),
            techniques: ["Custom"],
            emergencyContact: nil,
            personalizedPhrase: "I am safe and I can handle this"
          )
          onSave(newPlan)
        }
        .disabled(name.isEmpty || steps.filter { !$0.isEmpty }.isEmpty)
      )
      .onAppear {
        if let plan = plan {
          name = plan.title
          description = plan.description
          steps = plan.steps
          // audioFile removed from PanicPlan struct
          duration = TimeInterval(plan.duration)
        }
      }
    }
  }
}

// MARK: - Plan Execution View

struct PlanExecutionView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var audioManager = AudioManager.shared
  @StateObject private var progressTracker = ProgressTracker.shared
  @AppStorage("prefSounds") private var prefSounds = true

  let plan: PanicPlan

  @State private var currentStepIndex = 0
  @State private var timeRemaining: TimeInterval = 0
  @State private var isExecuting = false
  @State private var showCompletion = false

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

      VStack(spacing: 30) {
        // Header
        VStack(spacing: 16) {
          Text("🧩")
            .font(.system(size: 50))

          Text(plan.title)
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(Color(.label))

          Text(plan.description)
            .font(.body)
            .foregroundColor(Color(.secondaryLabel))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
        }

        if isExecuting {
          // Current Step
          VStack(spacing: 20) {
            Text("Step \(currentStepIndex + 1) of \(plan.steps.count)")
              .font(.headline)
              .foregroundColor(.blue)

            Text(plan.steps[currentStepIndex])
              .font(.title2)
              .fontWeight(.medium)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 20)

            // Progress indicator
            ProgressView(value: Double(currentStepIndex), total: Double(plan.steps.count - 1))
              .progressViewStyle(LinearProgressViewStyle(tint: .blue))
              .padding(.horizontal, 40)

            // Timer
            Text(timeString(from: timeRemaining))
              .font(.title)
              .fontWeight(.bold)
              .foregroundColor(.blue)
          }
        } else {
          // Start button
          Button(action: startPlan) {
            HStack(spacing: 12) {
              Image(systemName: "play.circle.fill")
                .font(.title2)
              Text("Start Plan")
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
        }

        Spacer()
      }
      .padding(.top, 40)
    }
    .navigationBarHidden(true)
    .sheet(isPresented: $showCompletion) {
      PlanCompletionView(plan: plan) {
        presentationMode.wrappedValue.dismiss()
      }
    }
  }

  private func startPlan() {
    isExecuting = true
    currentStepIndex = 0
    timeRemaining = TimeInterval(plan.duration)

    progressTracker.recordUsage()

    // Start audio if enabled
    if prefSounds {
      // audioManager.playSound(plan.audioFile, loop: true) // audioFile removed
    }

    // Start timer
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
      if timeRemaining > 0 {
        timeRemaining -= 1

        // Progress to next step
        let stepDuration = TimeInterval(plan.duration) / TimeInterval(plan.steps.count)
        let nextStepIndex = Int((TimeInterval(plan.duration) - timeRemaining) / stepDuration)

        if nextStepIndex != currentStepIndex && nextStepIndex < plan.steps.count {
          currentStepIndex = nextStepIndex
        }
      } else {
        timer.invalidate()
        audioManager.stopSound()
        showCompletion = true
      }
    }
  }

  private func timeString(from timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }
}

// MARK: - Plan Completion View

struct PlanCompletionView: View {
  let plan: PanicPlan
  let onDismiss: () -> Void

  var body: some View {
    VStack(spacing: 30) {
      Text("✅")
        .font(.system(size: 60))

      Text("Plan Complete!")
        .font(.title)
        .fontWeight(.bold)
        .foregroundColor(Color(.label))

      Text("You've successfully completed your personalized panic plan. How are you feeling now?")
        .font(.body)
        .foregroundColor(Color(.secondaryLabel))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)

      VStack(spacing: 16) {
        Button("I feel better") {
          onDismiss()
        }
        .foregroundColor(.white)
        .padding(.vertical, 12)
        .padding(.horizontal, 32)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(Color.green)
        )

        Button("I need more help") {
          onDismiss()
        }
        .foregroundColor(.blue)
        .padding(.vertical, 12)
        .padding(.horizontal, 32)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .stroke(Color.blue, lineWidth: 2)
        )
      }
    }
    .padding(40)
  }

}

#Preview {
  PersonalizedPanicPlanView()
}
