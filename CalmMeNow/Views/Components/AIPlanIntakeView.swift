import SwiftData
import SwiftUI

struct AIPlanIntakeView: View {
  @Binding var isPresented: Bool
  let onPlanGenerated: (PanicPlan) -> Void

  @Environment(\.modelContext) private var modelContext
  @Query private var journalEntries: [JournalEntry]

  // Form state
  @State private var selectedTriggers: Set<String> = []
  @State private var selectedSymptoms: Set<String> = []
  @State private var selectedBreathing: String = "box"
  @State private var selectedGrounding: String = "54321"
  @State private var selectedDuration: String = "short"
  @State private var personalizedPhrase: String = ""
  @State private var additionalContext: String = ""
  @State private var isGenerating = false
  @State private var journalInsightMessage: String = ""
  @State private var errorMessage: String = ""

  // Available options
  private let triggers = [
    "Crowded places", "Public transport", "Work meetings", "Social situations",
    "Health concerns", "Financial stress", "Family issues", "Performance pressure",
    "Uncertainty", "Conflict", "Being alone", "Loud noises", "Bright lights",
  ]

  private let symptoms = [
    "Racing heart", "Shortness of breath", "Chest tightness", "Dizziness",
    "Sweating", "Trembling", "Nausea", "Feeling detached", "Fear of losing control",
    "Hot flashes", "Chills", "Numbness", "Tingling", "Headache",
  ]

  private let breathingOptions = [
    "box": "Box Breathing (4-4-4-4)",
    "478": "4-7-8 Breathing",
    "coherence": "Heart Coherence",
    "triangle": "Triangle Breathing (3-3-3)",
  ]

  private let groundingOptions = [
    "54321": "5-4-3-2-1 Technique",
    "countback": "Count Back from 100",
    "sensory": "Sensory Grounding",
    "body": "Body Scan",
  ]

  private let durationOptions = [
    "short": "Quick Relief (60-90 seconds)",
    "medium": "Standard Plan (2-3 minutes)",
    "long": "Extended Support (4-5 minutes)",
  ]

  var body: some View {
    NavigationView {
      ZStack {
        // Gentle background gradient
        LinearGradient(
          gradient: Gradient(colors: [
            Color(hex: "#F8FAFF"),
            Color(hex: "#F0F8FF"),
            Color(hex: "#E8F4FD"),
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        ScrollView {
          VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
              Text("🧠")
                .font(.system(size: 50))

              Text("Create Your Personalized Plan")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)

              Text("Help us understand your needs so we can create a plan that truly works for you")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

              if !journalEntries.isEmpty {
                Text(
                  "💡 If you've used our journal, we'll automatically pull insights from your entries to personalize your plan"
                )
                .font(.caption)
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 8)
              }
            }
            .padding(.top, 20)

            // Journal Insight Message
            if !journalInsightMessage.isEmpty {
              HStack {
                Text(journalInsightMessage)
                  .font(.caption)
                  .foregroundColor(.blue)
                  .padding(.horizontal, 16)
                  .padding(.vertical, 12)
                  .background(
                    RoundedRectangle(cornerRadius: 8)
                      .fill(Color.blue.opacity(0.1))
                  )
              }
              .padding(.horizontal, 20)
            }

            // Triggers Section
            VStack(alignment: .leading, spacing: 12) {
              Text("What situations trigger your anxiety?")
                .font(.headline)
                .foregroundColor(.primary)

              Text("Select all that apply")
                .font(.caption)
                .foregroundColor(.secondary)

              LazyVGrid(
                columns: [
                  GridItem(.flexible()),
                  GridItem(.flexible()),
                ], spacing: 8
              ) {
                ForEach(triggers, id: \.self) { trigger in
                  TriggerChip(
                    text: trigger,
                    isSelected: selectedTriggers.contains(trigger)
                  ) {
                    if selectedTriggers.contains(trigger) {
                      selectedTriggers.remove(trigger)
                    } else {
                      selectedTriggers.insert(trigger)
                    }
                  }
                }
              }
            }
            .padding(.horizontal, 20)

            // Symptoms Section
            VStack(alignment: .leading, spacing: 12) {
              Text("What physical symptoms do you experience?")
                .font(.headline)
                .foregroundColor(.primary)

              Text("This helps us choose the right techniques")
                .font(.caption)
                .foregroundColor(.secondary)

              LazyVGrid(
                columns: [
                  GridItem(.flexible()),
                  GridItem(.flexible()),
                ], spacing: 8
              ) {
                ForEach(symptoms, id: \.self) { symptom in
                  SymptomChip(
                    text: symptom,
                    isSelected: selectedSymptoms.contains(symptom)
                  ) {
                    if selectedSymptoms.contains(symptom) {
                      selectedSymptoms.remove(symptom)
                    } else {
                      selectedSymptoms.insert(symptom)
                    }
                  }
                }
              }
            }
            .padding(.horizontal, 20)

            // Preferences Section
            VStack(alignment: .leading, spacing: 16) {
              Text("Your Preferences")
                .font(.headline)
                .foregroundColor(.primary)

              // Breathing Technique
              VStack(alignment: .leading, spacing: 8) {
                Text("Preferred Breathing Technique")
                  .font(.subheadline)
                  .fontWeight(.medium)

                Picker("Breathing", selection: $selectedBreathing) {
                  ForEach(Array(breathingOptions.keys.sorted()), id: \.self) { key in
                    Text(breathingOptions[key] ?? key).tag(key)
                  }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                  RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.separator), lineWidth: 0.5)
                )
              }

              // Grounding Technique
              VStack(alignment: .leading, spacing: 8) {
                Text("Preferred Grounding Method")
                  .font(.subheadline)
                  .fontWeight(.medium)

                Picker("Grounding", selection: $selectedGrounding) {
                  ForEach(Array(groundingOptions.keys.sorted()), id: \.self) { key in
                    Text(groundingOptions[key] ?? key).tag(key)
                  }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                  RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.separator), lineWidth: 0.5)
                )
              }

              // Duration
              VStack(alignment: .leading, spacing: 8) {
                Text("Plan Duration")
                  .font(.subheadline)
                  .fontWeight(.medium)

                Picker("Duration", selection: $selectedDuration) {
                  ForEach(Array(durationOptions.keys.sorted()), id: \.self) { key in
                    Text(durationOptions[key] ?? key).tag(key)
                  }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                  RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.separator), lineWidth: 0.5)
                )
              }
            }
            .padding(.horizontal, 20)

            // Personal Phrase Section
            VStack(alignment: .leading, spacing: 12) {
              Text("Your Calming Phrase")
                .font(.headline)
                .foregroundColor(.primary)

              Text("A personal phrase that helps you feel safe and grounded")
                .font(.caption)
                .foregroundColor(.secondary)

              TextField("e.g., 'I am safe and I can handle this'", text: $personalizedPhrase)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)

            // Additional Context
            VStack(alignment: .leading, spacing: 12) {
              Text("Anything else we should know?")
                .font(.headline)
                .foregroundColor(.primary)

              Text("Any specific details that might help us create a better plan")
                .font(.caption)
                .foregroundColor(.secondary)

              TextField(
                "Optional: Share any additional context...", text: $additionalContext,
                axis: .vertical
              )
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .lineLimit(3...6)
              .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)

            // Generate Button
            Button(action: generatePlan) {
              HStack(spacing: 12) {
                if isGenerating {
                  ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                } else {
                  Image(systemName: "brain.head.profile")
                    .font(.title2)
                }

                Text(isGenerating ? "Creating Your Plan..." : "Create My Personalized Plan")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              .foregroundColor(.white)
              .padding(.vertical, 16)
              .padding(.horizontal, 24)
              .background(
                RoundedRectangle(cornerRadius: 25)
                  .fill(canGenerate ? Color.blue : Color.gray)
              )
            }
            .disabled(!canGenerate || isGenerating)
            .padding(.horizontal, 20)

            // Error Message
            if !errorMessage.isEmpty {
              HStack {
                Image(systemName: "exclamationmark.triangle")
                  .foregroundColor(.red)
                Text(errorMessage)
                  .font(.caption)
                  .foregroundColor(.red)
              }
              .padding(.horizontal, 20)
              .padding(.bottom, 20)
            }
          }
          .padding(.bottom, 40)
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            isPresented = false
          }
        }
      }
      .onAppear {
        analyzeJournalEntries()
      }
    }
  }

  private var canGenerate: Bool {
    !selectedTriggers.isEmpty && !selectedSymptoms.isEmpty
      && !personalizedPhrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private func analyzeJournalEntries() {
    // Only analyze if user hasn't made any selections yet
    guard selectedTriggers.isEmpty && selectedSymptoms.isEmpty else { return }

    // Get recent journal entries (last 30 days)
    let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    let recentEntries = journalEntries.filter { $0.timestamp >= thirtyDaysAgo }

    // Extract common contributing factors as potential triggers
    var factorCounts: [String: Int] = [:]
    for entry in recentEntries {
      if let factors = entry.contributingFactors {
        for factor in factors {
          factorCounts[factor, default: 0] += 1
        }
      }
    }

    // Pre-select the most common factors (if they match our trigger list)
    let commonFactors = factorCounts.sorted { $0.value > $1.value }.prefix(3)
    for (factor, _) in commonFactors {
      if triggers.contains(factor) {
        selectedTriggers.insert(factor)
      }
    }

    // If we found journal data, show a helpful message
    if !selectedTriggers.isEmpty {
      journalInsightMessage =
        "✨ We found some patterns in your recent journal entries and pre-selected common triggers for you."
    }
  }

  private func generatePlan() {
    isGenerating = true
    errorMessage = ""

    Task {
      do {
        let intake: [String: Any] = [
          "triggers": Array(selectedTriggers),
          "symptoms": Array(selectedSymptoms),
          "preferences": [
            "breathing": selectedBreathing,
            "grounding": selectedGrounding,
          ],
          "duration": selectedDuration,
          "personalizedPhrase": personalizedPhrase.trimmingCharacters(in: .whitespacesAndNewlines),
          "additionalContext": additionalContext.trimmingCharacters(in: .whitespacesAndNewlines),
        ]

        let result = try await AiService.shared.generatePanicPlan(intake: intake)

        await MainActor.run {
          let newPlan = createPlanFromResult(result)
          onPlanGenerated(newPlan)

          // Add a small delay to prevent multiple sheets from presenting simultaneously
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPresented = false
          }
        }
      } catch {
        await MainActor.run {
          isGenerating = false
          errorMessage =
            "We're having trouble creating your plan right now. Please try again in a moment."
          print("Error generating plan: \(error)")
        }
      }
    }
  }

  private func createPlanFromResult(_ result: [String: Any]) -> PanicPlan {
    let planSteps = parseStructuredPlanSteps(result)
    let duration = extractDuration(from: result)
    let techniques = extractTechniques(from: result)

    let plan = PanicPlan(
      title: "My Personalized Plan",
      description: "Created specifically for your needs",
      steps: planSteps,
      duration: duration,
      techniques: techniques,
      emergencyContact: nil,
      personalizedPhrase: personalizedPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
    )

    print(
      "🔍 Created plan: \(plan.title), duration: \(plan.duration), steps: \(plan.steps.map { "\($0.type.rawValue): \($0.text)" })"
    )
    return plan
  }

  // Helper functions for parsing AI results into PlanStep objects
  private func parseStructuredPlanSteps(_ result: [String: Any]) -> [PlanStep] {
    print("🔍 Parsing AI result: \(result)")
    guard let steps = result["steps"] as? [[String: Any]] else {
      print("⚠️ No steps found in AI result, using default steps")
      return defaultPlanSteps()
    }

    let parsed = steps.compactMap { step -> PlanStep? in
      print("🔍 Raw step data: \(step)")

      // Handle the AI's format where step type is the key
      var stepType: StepType = .custom
      var stepData: [String: Any] = [:]
      var seconds: Int? = nil
      var text: String = ""

      // Check if this is the AI's format (type as key)
      if let breathingData = step["breathing"] as? [String: Any] {
        stepType = .breathing
        stepData = breathingData
        if let pattern = breathingData["pattern"] as? String {
          text = "\(pattern.capitalized) breathing"
        }
      } else if let groundingData = step["grounding"] as? [String: Any] {
        stepType = .grounding
        stepData = groundingData
        if let method = groundingData["method"] as? String {
          text = "\(method.capitalized) grounding"
        }
      } else if let muscleData = step["muscle_release"] as? [String: Any] {
        stepType = .muscleRelease
        stepData = muscleData
        if let area = muscleData["area"] as? String {
          text = "Release \(area)"
        }
      } else if let affirmationData = step["affirmation"] as? [String: Any] {
        stepType = .affirmation
        stepData = affirmationData
        if let affirmationText = affirmationData["text"] as? String {
          text = "Repeat: '\(affirmationText)'"
        }
      } else if let mindfulnessData = step["mindfulness"] as? [String: Any] {
        stepType = .mindfulness
        stepData = mindfulnessData
        text = "Mindful awareness"
      } else if let cognitiveData = step["cognitive_reframing"] as? [String: Any] {
        stepType = .cognitiveReframing
        stepData = cognitiveData
        text = "Cognitive reframing"
      } else {
        // Fallback to standard format
        let type = (step["type"] as? String)?.lowercased() ?? ""
        text = step["text"] as? String ?? ""

        switch type {
        case "breathing":
          stepType = .breathing
        case "grounding":
          stepType = .grounding
        case "muscle_release":
          stepType = .muscleRelease
        case "affirmation":
          stepType = .affirmation
        case "mindfulness":
          stepType = .mindfulness
        case "cognitive_reframing":
          stepType = .cognitiveReframing
        default:
          stepType = .custom
        }
      }

      // Extract seconds from stepData or step
      seconds = stepData["seconds"] as? Int ?? step["seconds"] as? Int

      // Enhance text with duration if available
      if let duration = seconds, duration > 0 {
        text += " for \(duration) seconds"
      }

      print("🔍 Parsing step: type='\(stepType.rawValue)', text='\(text)', seconds=\(seconds ?? 0)")

      let planStep = PlanStep(type: stepType, text: text, seconds: seconds)
      print("🔍 Created PlanStep: \(planStep.type.rawValue) - '\(planStep.text)'")
      return planStep
    }

    return parsed.isEmpty ? defaultPlanSteps() : parsed
  }

  // Helper functions (same as in PersonalizedPanicPlanView)
  private func parseStructuredPlan(_ result: [String: Any]) -> [String] {
    guard let steps = result["steps"] as? [[String: Any]] else {
      return defaultSteps()
    }

    let parsed = steps.compactMap { step -> String? in
      let type = (step["type"] as? String)?.lowercased() ?? ""
      switch type {
      case "breathing":
        if let pattern = step["pattern"] as? String, let seconds = step["seconds"] as? Int {
          // Handle specific breathing patterns
          switch pattern.lowercased() {
          case "478":
            return "4-7-8 breathing for \(seconds) seconds"
          case "box":
            return "Box breathing for \(seconds) seconds"
          case "coherence":
            return "Heart coherence breathing for \(seconds) seconds"
          case "diaphragmatic":
            return "Diaphragmatic breathing for \(seconds) seconds"
          default:
            return "\(pattern.capitalized) breathing for \(seconds) seconds"
          }
        }
        if let pattern = step["pattern"] as? String {
          return "\(pattern.capitalized) breathing"
        }
        return "Slow breathing: In 4 • Hold 4 • Out 4 • Hold 4"
      case "grounding":
        if let method = step["method"] as? String, let seconds = step["seconds"] as? Int {
          // Handle specific grounding methods
          switch method.lowercased() {
          case "54321":
            return "5-4-3-2-1 grounding for \(seconds) seconds"
          case "countback":
            return "Countdown grounding for \(seconds) seconds"
          case "sensory":
            return "Sensory grounding for \(seconds) seconds"
          default:
            return "\(method.capitalized) grounding for \(seconds) seconds"
          }
        }
        return "5-4-3-2-1 grounding"
      case "muscle_release":
        let area = (step["area"] as? String) ?? "shoulders"
        let seconds = (step["seconds"] as? Int) ?? 20
        return "Release \(area) for \(seconds) seconds"
      case "affirmation":
        let text = (step["text"] as? String) ?? "I am safe. This will pass."
        return "Repeat: '\(text)'"
      case "mindfulness":
        let text = (step["text"] as? String) ?? "Focus on the present moment"
        return text
      case "cognitive_reframing":
        let text = (step["text"] as? String) ?? "This is uncomfortable but not dangerous"
        return "Reframe: '\(text)'"
      default:
        if let text = step["text"] as? String { return text }
        return nil
      }
    }
    return parsed.isEmpty ? defaultSteps() : parsed
  }

  private func defaultPlanSteps() -> [PlanStep] {
    // Return 3 random evidence-based techniques for variety
    let allSteps = StepLibrary.allSteps
    let defaultSteps = Array(allSteps.shuffled().prefix(3))
    print("🔍 Default plan steps: \(defaultSteps.map { "\($0.type.rawValue): \($0.text)" })")
    return defaultSteps
  }

  private func defaultSteps() -> [String] {
    // Evidence-based techniques pool for fallback
    let techniques = [
      "Box breathing: Inhale 4, hold 4, exhale 4, hold 4",
      "4-7-8 breathing: Inhale 4, hold 7, exhale 8",
      "5-4-3-2-1 grounding: 5 things you see, 4 you can touch, 3 you hear, 2 you smell, 1 you taste",
      "Temperature grounding: Hold something cold, notice the sensation",
      "Progressive muscle relaxation: Tense and release your shoulders",
      "Cognitive reframing: 'This is uncomfortable but not dangerous'",
      "Mindful body scan: Notice your feet touching the ground",
      "Counting backwards: Count slowly from 20 to 1",
      "Diaphragmatic breathing: Breathe deeply into your belly",
      "Sensory awareness: Focus on one sound around you",
    ]

    // Return 3 random techniques for variety
    return Array(techniques.shuffled().prefix(3))
  }

  private func extractDuration(from result: [String: Any]) -> Int {
    if let total = (result["total_seconds"] as? Int), total > 0 {
      let duration = min(max(total, 60), 300)
      print("🔍 Extracted duration from total_seconds: \(duration)")
      return duration
    }
    guard let steps = result["steps"] as? [[String: Any]] else {
      print("🔍 No steps found, using default duration: 120")
      return 120
    }
    let sum = steps.compactMap { step -> Int? in
      // Handle AI's nested format
      if let breathingData = step["breathing"] as? [String: Any],
        let seconds = breathingData["seconds"] as? Int
      {
        return seconds
      } else if let groundingData = step["grounding"] as? [String: Any],
        let seconds = groundingData["seconds"] as? Int
      {
        return seconds
      } else if let muscleData = step["muscle_release"] as? [String: Any],
        let seconds = muscleData["seconds"] as? Int
      {
        return seconds
      } else if let affirmationData = step["affirmation"] as? [String: Any],
        let seconds = affirmationData["seconds"] as? Int
      {
        return seconds
      } else if let mindfulnessData = step["mindfulness"] as? [String: Any],
        let seconds = mindfulnessData["seconds"] as? Int
      {
        return seconds
      } else if let cognitiveData = step["cognitive_reframing"] as? [String: Any],
        let seconds = cognitiveData["seconds"] as? Int
      {
        return seconds
      } else {
        // Fallback to standard format
        return step["seconds"] as? Int
      }
    }.reduce(0, +)
    let duration = min(max(sum, 60), 300)
    print("🔍 Extracted duration from step sum: \(duration)")
    return duration
  }

  private func extractTechniques(from result: [String: Any]) -> [String] {
    guard let steps = result["steps"] as? [[String: Any]] else { return ["Personalized"] }

    let techniques = steps.compactMap { step in
      step["type"] as? String
    }.map { $0.capitalized }

    return techniques.isEmpty ? ["Personalized"] : techniques
  }
}

// MARK: - Supporting Views

struct TriggerChip: View {
  let text: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(text)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(isSelected ? .white : .primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(isSelected ? Color.blue : Color(.systemBackground))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(isSelected ? Color.blue : Color(.separator), lineWidth: 0.5)
        )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

struct SymptomChip: View {
  let text: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(text)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(isSelected ? .white : .primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(isSelected ? Color.green : Color(.systemBackground))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(isSelected ? Color.green : Color(.separator), lineWidth: 0.5)
        )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

#Preview {
  AIPlanIntakeView(isPresented: .constant(true)) { _ in }
}
