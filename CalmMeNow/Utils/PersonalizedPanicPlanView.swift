import Firebase
import SwiftUI

struct PersonalizedPanicPlanView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var audioManager = AudioManager.shared
  @StateObject private var progressTracker = ProgressTracker.shared
  @StateObject private var planStore = PlanStore()

  @AppStorage("prefSounds") private var prefSounds = true

  @State private var selectedPlan: PanicPlan?
  @State private var showingPlanEditor = false
  @State private var showingIntakeForm = false

  @State private var isGeneratingAIPlan = false
  #if DEBUG
    @State private var debugStatus = ""
  #endif

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
              ForEach(planStore.plans) { plan in
                PlanCard(
                  plan: plan,
                  onTap: {
                    print("Plan card tapped: \(plan.title)")
                    print("Plan steps: \(plan.steps)")
                    selectedPlan = plan
                  },
                  onEdit: {
                    selectedPlan = plan
                    showingPlanEditor = true
                  },
                  onDelete: {
                    planStore.delete(plan)
                  }
                )
              }
            }
            .padding(.horizontal, 20)

            // Personalized Plan Generator Info Card
            VStack(spacing: 16) {
              Text("🧠 Personalized Plan Generator")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(.label))

              VStack(spacing: 12) {
                HStack {
                  Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                    .font(.title3)
                  VStack(alignment: .leading, spacing: 2) {
                    Text("Personalized for You")
                      .font(.subheadline)
                      .fontWeight(.medium)
                    Text("Tell us about your triggers, symptoms, and preferences")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  Spacer()
                }

                HStack {
                  Image(systemName: "clock")
                    .foregroundColor(.green)
                    .font(.title3)
                  VStack(alignment: .leading, spacing: 2) {
                    Text("Takes 2-3 minutes")
                      .font(.subheadline)
                      .fontWeight(.medium)
                    Text("Quick questions to understand your needs")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  Spacer()
                }

                HStack {
                  Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title3)
                  VStack(alignment: .leading, spacing: 2) {
                    Text("Created Just for You")
                      .font(.subheadline)
                      .fontWeight(.medium)
                    Text("A plan tailored to your specific situation and preferences")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  Spacer()
                }
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

            // Personalized Plan Button
            Button(action: {
              showingIntakeForm = true
            }) {
              HStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                  .font(.title2)
                Text("Create a Personalized Plan")
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
            .padding(.horizontal, 20)

            #if DEBUG
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
            #endif

            #if DEBUG
              // Debug Status
              if !debugStatus.isEmpty {
                Text(debugStatus)
                  .font(.caption)
                  .foregroundColor(Color(.secondaryLabel))
                  .padding(.horizontal, 20)
              }
            #endif

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
            planStore.upsert(newPlan)
            showingPlanEditor = false
          }
        )
      }
      .sheet(item: $selectedPlan) { plan in
        PlanExecutionView(plan: plan)
      }
      .sheet(isPresented: $showingIntakeForm) {
        AIPlanIntakeView(isPresented: $showingIntakeForm) { newPlan in
          planStore.upsert(newPlan)
          selectedPlan = newPlan
        }
      }
    }
  }

  // MARK: - AI Methods

  /// Generate a personalized panic plan using AI
  private func generateAIPanicPlan() {
    isGeneratingAIPlan = true
    let startTime = CFAbsoluteTimeGetCurrent()

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
          let steps = parseStructuredPlan(result)
          let duration = extractDuration(from: result)
          let techniques = extractTechniques(from: result)

          print("AI Plan Generation Debug:")
          print("Raw result: \(result)")
          print("Parsed steps: \(steps)")
          print("Extracted duration: \(duration)")
          print("Extracted techniques: \(techniques)")

          let newPlan = PanicPlan(
            title: "Personalized Plan",
            description: "Personalized plan created just for you",
            steps: steps,
            duration: duration,
            techniques: techniques,
            emergencyContact: nil,
            personalizedPhrase: "I am safe and I can handle this"
          )

          planStore.upsert(newPlan)
          selectedPlan = newPlan  // Auto-select the newly generated plan
          isGeneratingAIPlan = false

          // Track successful plan generation
          let latencyMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)
          AnalyticsLogger.shared.planGenerated(
            stepsCount: newPlan.steps.count,
            planVersion: "1.0",
            model: "gpt-4o-mini",
            latencyMs: latencyMs
          )
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
    guard let raw = result["steps"] as? [[String: Any]] else {
      return defaultSteps()
    }

    let parsed = raw.compactMap { step -> String? in
      let type = (step["type"] as? String)?.lowercased() ?? ""
      switch type {
      case "breathing":
        if let pattern = step["pattern"] as? String, let seconds = step["seconds"] as? Int {
          return "\(pattern.capitalized) breathing for \(seconds) seconds"
        }
        if let pattern = step["pattern"] as? String {
          return "\(pattern.capitalized) breathing"
        }
        return "Slow breathing: In 4 • Hold 4 • Out 4 • Hold 4"
      case "grounding":
        if let method = step["method"] as? String, let seconds = step["seconds"] as? Int {
          return "\(method.capitalized) grounding for \(seconds) seconds"
        }
        return "5-4-3-2-1 grounding"
      case "muscle_release":
        let area = (step["area"] as? String) ?? "shoulders"
        let seconds = (step["seconds"] as? Int) ?? 20
        return "Release \(area) for \(seconds) seconds"
      case "affirmation":
        let text = (step["text"] as? String) ?? "I am safe. This will pass."
        return "Repeat: '\(text)'"
      default:
        // Try a generic "text" field
        if let text = step["text"] as? String { return text }
        return nil
      }
    }
    return parsed.isEmpty ? defaultSteps() : parsed
  }

  private func defaultSteps() -> [String] {
    [
      "Take 5 slow breaths (in 4 • hold 4 • out 4 • hold 4)",
      "5-4-3-2-1 grounding: 5 see • 4 touch • 3 hear • 2 smell • 1 taste",
      "Repeat: 'I am safe. This will pass.'",
    ]
  }

  /// Extract duration from structured plan
  private func extractDuration(from result: [String: Any]) -> Int {
    if let total = (result["total_seconds"] as? Int), total > 0 {
      return min(max(total, 60), 300)
    }
    guard let steps = result["steps"] as? [[String: Any]] else { return 120 }
    let sum = steps.compactMap { $0["seconds"] as? Int }.reduce(0, +)
    return min(max(sum, 60), 300)
  }

  /// Extract techniques from structured plan
  private func extractTechniques(from result: [String: Any]) -> [String] {
    guard let steps = result["steps"] as? [[String: Any]] else { return ["Personalized"] }

    let techniques = steps.compactMap { step in
      step["type"] as? String
    }.map { $0.capitalized }

    return techniques.isEmpty ? ["Personalized"] : techniques
  }

  #if DEBUG
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
  #endif

}

// MARK: - Supporting Types

// Using the PanicPlan struct from PanicPlan.swift

// MARK: - Plan Card Component

struct PlanCard: View {
  let plan: PanicPlan
  let onTap: () -> Void
  let onEdit: () -> Void
  let onDelete: () -> Void

  var body: some View {
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

        HStack(spacing: 8) {
          Button(action: onEdit) {
            Image(systemName: "pencil.circle.fill")
              .font(.title2)
              .foregroundColor(.blue)
          }
          .buttonStyle(PlainButtonStyle())

          Button(action: onDelete) {
            Image(systemName: "trash.circle.fill")
              .font(.title2)
              .foregroundColor(.red)
          }
          .buttonStyle(PlainButtonStyle())
        }
      }

      // Add Start Plan button
      Button(action: onTap) {
        HStack {
          Image(systemName: "play.fill")
            .font(.caption)
          Text("Start Plan")
            .font(.subheadline)
            .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.blue)
        .cornerRadius(8)
      }
      .buttonStyle(PlainButtonStyle())

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
              .fill(Color.blue.opacity(0.2))
          )
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    )
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
          Text("Add clear, actionable steps for your panic plan. Examples:")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.bottom, 8)

          ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
            VStack(alignment: .leading, spacing: 4) {
              Text("Step \(index + 1)")
                .font(.caption)
                .foregroundColor(.secondary)

              TextField(getStepPlaceholder(for: index), text: $steps[index])
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            if steps.count > 1 {
              HStack {
                Spacer()
                Button(action: {
                  steps.remove(at: index)
                }) {
                  HStack {
                    Image(systemName: "minus.circle.fill")
                    Text("Remove Step")
                  }
                  .foregroundColor(.red)
                }
              }
            }
          }

          Button("Add Step") {
            steps.append("")
          }
          .foregroundColor(.blue)
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
        } else {
          // Set default values for new plans
          name = "My Panic Plan"
          description = "Personalized plan for managing panic attacks"
          steps = [
            "Take 5 deep breaths slowly",
            "Name 5 things you can see around you",
            "Repeat: 'I am safe and this will pass'",
          ]
        }
      }
    }
  }

  private func getStepPlaceholder(for index: Int) -> String {
    let examples = [
      "Take 5 deep breaths slowly",
      "Name 5 things you can see around you",
      "Repeat: 'I am safe and this will pass'",
      "Focus on your breathing for 30 seconds",
      "Call a trusted friend or family member",
      "Use your calming phrase 3 times",
      "Do a quick body scan and relax tense muscles",
      "Listen to calming music or sounds",
    ]

    if index < examples.count {
      return examples[index]
    } else {
      return "Add your personal calming technique"
    }
  }
}

// MARK: - Plan Execution View

struct PlanExecutionView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var audioManager = AudioManager.shared
  @StateObject private var progressTracker = ProgressTracker.shared
  @StateObject private var speechService = SpeechService()
  @AppStorage("prefSounds") private var prefSounds = true

  let plan: PanicPlan

  @State private var currentStepIndex = 0
  @State private var timeRemaining: TimeInterval = 0
  @State private var isExecuting = false
  @State private var showCompletion = false
  @State private var showValidationAlert = false
  @State private var validationMessage = ""
  @State private var stepTimer: Timer?
  @State private var currentStepStartTime: Date?

  var body: some View {
    ZStack {
      // Background gradient
      LinearGradient(
        gradient: Gradient(colors: [
          Color.blue.opacity(0.1),
          Color.blue.opacity(0.05),
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 30) {
        // Header with close button
        VStack(spacing: 16) {
          HStack {
            Spacer()
            Button(action: {
              // Clean up audio before dismissing
              stepTimer?.invalidate()
              audioManager.stopSound()
              speechService.stopAll()
              presentationMode.wrappedValue.dismiss()
            }) {
              Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(.gray)
            }
          }
          .padding(.horizontal, 20)

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

            // Step content with better formatting
            VStack(spacing: 12) {
              Text("What to do:")
                .font(.subheadline)
                .foregroundColor(.secondary)

              Text(plan.steps[currentStepIndex])
                .font(.title2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                )
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )

              // Detailed explanation for the current step
              if let explanation = getStepExplanation(for: plan.steps[currentStepIndex]) {
                Text(explanation)
                  .font(.body)
                  .foregroundColor(.secondary)
                  .multilineTextAlignment(.center)
                  .padding(.horizontal, 20)
                  .padding(.top, 8)
              }
            }

            // Progress indicator
            ProgressView(value: Double(currentStepIndex), total: Double(plan.steps.count - 1))
              .progressViewStyle(LinearProgressViewStyle(tint: .blue))
              .padding(.horizontal, 40)

            // Timer
            VStack(spacing: 4) {
              Text("Time remaining:")
                .font(.caption)
                .foregroundColor(.secondary)
              Text(timeString(from: timeRemaining))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            }
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
    .onAppear {
      print("PlanExecutionView appeared")
      print("Plan title: \(plan.title)")
      print("Plan steps: \(plan.steps)")
      print("Plan duration: \(plan.duration)")
    }
    .onDisappear {
      // Clean up when view disappears
      stepTimer?.invalidate()
      audioManager.stopSound()
      speechService.stopAll()
    }
    .alert(isPresented: $showValidationAlert) {
      Alert(
        title: Text("Can't Start Plan"),
        message: Text(validationMessage),
        dismissButton: .default(Text("OK"))
      )
    }
  }

  private func startPlan() {
    print("Start Plan button tapped")  // Debug logging
    print("Plan title: \(plan.title)")
    print("Plan steps count: \(plan.steps.count)")
    print("Plan duration: \(plan.duration)")

    // Validate plan data
    guard !plan.steps.isEmpty else {
      validationMessage = "This plan has no steps. Edit or regenerate it."
      showValidationAlert = true
      return
    }

    guard plan.duration > 0 else {
      validationMessage = "This plan has no duration. Edit or regenerate it."
      showValidationAlert = true
      return
    }

    isExecuting = true
    currentStepIndex = 0
    timeRemaining = TimeInterval(plan.duration)
    currentStepStartTime = Date()

    progressTracker.recordUsage()

    // Start audio if enabled
    if prefSounds {
      // Play appropriate calming sound based on plan content
      let soundFile = getAppropriateSound(for: plan)
      print("Playing sound: \(soundFile)")
      audioManager.playSound(soundFile, loop: true)
    }

    // Start with voice guidance for the first step
    speakCurrentStep()

    // Start main timer
    stepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
      if timeRemaining > 0 {
        timeRemaining -= 1

        // Progress to next step based on time
        let stepDuration = TimeInterval(plan.duration) / TimeInterval(plan.steps.count)
        let nextStepIndex = Int((TimeInterval(plan.duration) - timeRemaining) / stepDuration)

        if nextStepIndex != currentStepIndex && nextStepIndex < plan.steps.count {
          currentStepIndex = nextStepIndex
          currentStepStartTime = Date()
          speakCurrentStep()
        }
      } else {
        timer.invalidate()
        audioManager.stopSound()
        speechService.stopAll()
        showCompletion = true
      }
    }
  }

  private func timeString(from timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }

  // MARK: - Voice Guidance Methods

  private func speakCurrentStep() {
    let step = plan.steps[currentStepIndex]
    let stepNumber = currentStepIndex + 1
    let totalSteps = plan.steps.count

    // Create a more natural voice message with pauses
    var message = "Step \(stepNumber) of \(totalSteps). "

    // Add the step instruction with natural pauses
    if step.contains("breathing") || step.contains("breath") {
      // For breathing exercises, speak more slowly and with pauses
      message += "Now, let's focus on breathing. " + step.replacingOccurrences(of: "•", with: ", ")
    } else {
      message += step
    }

    // Add detailed explanation if available, with a pause
    if let explanation = getStepExplanation(for: step) {
      message += ". " + explanation
    }

    // Add personalized phrase if this is the last step
    if currentStepIndex == plan.steps.count - 1, let phrase = plan.personalizedPhrase {
      message += ". Remember your calming phrase: \(phrase)"
    }

    print("🎤 Speaking step guidance: \(message)")
    // Use a slower rate for breathing exercises
    let rate: Float = step.contains("breathing") || step.contains("breath") ? 0.4 : 0.5
    speechService.speak(message, rate: rate)
  }

  private func getStepExplanation(for step: String) -> String? {
    let lowercasedStep = step.lowercased()

    // Breathing exercises
    if lowercasedStep.contains("breathing") || lowercasedStep.contains("breath") {
      if lowercasedStep.contains("478") || lowercasedStep.contains("4-7-8") {
        return "This breathing pattern helps activate your body's relaxation response."
      } else if lowercasedStep.contains("box") {
        return "Imagine tracing a square with your breath."
      } else if lowercasedStep.contains("coherence") {
        return
          "Focus on your heart as you breathe. This creates harmony between your heart and brain."
      } else {
        return "Let your breath anchor you to the present moment."
      }
    }

    // Grounding exercises
    if lowercasedStep.contains("grounding") || lowercasedStep.contains("54321") {
      if lowercasedStep.contains("54321") || lowercasedStep.contains("5-4-3-2-1") {
        return
          "This grounding technique helps you connect with your surroundings. Notice 5 things you can see, 4 things you can touch, 3 things you can hear, 2 things you can smell, and 1 thing you can taste. This brings your attention to the present moment."
      } else if lowercasedStep.contains("countback") || lowercasedStep.contains("countdown") {
        return
          "Count backwards from 10 to 1, focusing on each number. This helps ground you in the present moment."
      } else if lowercasedStep.contains("sensory") {
        return
          "Focus on your senses one at a time. Notice what you can see, hear, feel, smell, and taste right now."
      } else {
        return
          "This grounding technique helps you connect with your surroundings and brings your attention to the present moment."
      }
    }

    // Muscle release
    if lowercasedStep.contains("release") || lowercasedStep.contains("muscle") {
      return
        "Gently tense the muscle group for a few seconds, then slowly release. Notice the difference between tension and relaxation."
    }

    // Affirmations
    if lowercasedStep.contains("repeat") || lowercasedStep.contains("phrase") {
      return
        "Speak your calming phrase slowly and with intention. Let the words sink in and bring you comfort."
    }

    return nil
  }

  private func getAppropriateSound(for plan: PanicPlan) -> String {
    // Check if any step mentions specific emotions or situations
    let allSteps = plan.steps.joined(separator: " ").lowercased()

    if allSteps.contains("angry") || allSteps.contains("anger") {
      return "mixkit-just-chill-angry"
    } else if allSteps.contains("anxious") || allSteps.contains("anxiety") {
      return "mixkit-serene-anxious"
    } else if allSteps.contains("sad") || allSteps.contains("depressed") {
      return "mixkit-jazz-sad"
    } else {
      // Default calming sound
      return "perfect-beauty-1-min"
    }
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
