import SwiftUI

struct PersonalizedPanicPlanView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var audioManager = AudioManager.shared
  @StateObject private var progressTracker = ProgressTracker.shared
  @StateObject private var openAIService = OpenAIService.shared
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
                .foregroundColor(.primary)

              Text("Personalized emergency response plans for when you need them most")
                .font(.body)
                .foregroundColor(.secondary)
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
        let prompt = """
            You are a mental health expert creating a personalized panic attack response plan.
            Create a 4-step emergency plan that includes:
            1. Immediate breathing technique
            2. Grounding exercise
            3. Calming activity
            4. Safety check or support contact
            
            Make it practical, gentle, and immediately actionable.
            Return the response as a JSON array of 4 strings.
          """

        let aiResponse = try await openAIService.sendMessage(
          "I need a personalized panic attack response plan",
          systemPrompt: prompt
        )

        // Parse AI response and create plan
        await MainActor.run {
          let newPlan = PanicPlan(
            title: "AI-Generated Plan",
            description: "Personalized plan created just for you",
            steps: parseAIResponse(aiResponse),
            duration: 180,
            techniques: ["AI-Generated", "Personalized"],
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
      }
    }
  }

  /// Parse AI response into plan steps
  private func parseAIResponse(_ response: String) -> [String] {
    // Try to parse as JSON first
    if let data = response.data(using: .utf8),
      let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [String]
    {
      return jsonArray
    }

    // Fallback: try to extract numbered steps
    let lines = response.components(separatedBy: .newlines)
    let steps = lines.compactMap { line in
      let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
      // Look for numbered lines or quoted strings
      if trimmed.range(of: #"^\d+\.\s*(.+)"#, options: .regularExpression) != nil {
        return String(
          trimmed.replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression))
      } else if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") {
        return String(trimmed.dropFirst().dropLast())
      }
      return nil
    }.filter { !$0.isEmpty }

    return steps.isEmpty
      ? [
        "Take 5 deep breaths",
        "Name 5 things you can see",
        "Listen to calming sounds",
        "Text a trusted friend",
      ] : steps
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
              .foregroundColor(.primary)

            Text(plan.description)
              .font(.caption)
              .foregroundColor(.secondary)
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
                .foregroundColor(.secondary)
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
            .foregroundColor(.secondary)

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
          .fill(Color.white)
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
            .foregroundColor(.primary)

          Text(plan.description)
            .font(.body)
            .foregroundColor(.secondary)
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
        .foregroundColor(.primary)

      Text("You've successfully completed your personalized panic plan. How are you feeling now?")
        .font(.body)
        .foregroundColor(.secondary)
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
