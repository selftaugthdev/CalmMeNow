import Firebase
import FirebaseFunctions
import SwiftUI

// MARK: - JSON Pretty Printer
func printJSON(_ any: Any, prefix: String = "🔎") {
  if let d = try? JSONSerialization.data(withJSONObject: any, options: [.prettyPrinted]),
    let s = String(data: d, encoding: .utf8)
  {
    print("\(prefix) JSON:\n\(s)")
  } else {
    print("\(prefix) <non-JSON> \(any)")
  }
}

struct DailyCoachView: View {
  @Environment(\.presentationMode) var presentationMode
  @State private var mood: Int = 4  // 1-10
  @State private var tags: Set<String> = ["tired"]
  @State private var note: String = ""
  @State private var checkinResult: [String: Any]?
  @State private var isLoading = false
  @State private var error: String?
  @State private var showingPanicPlan = false
  @State private var emergencyExercise: Exercise?
  @State private var isGeneratingExercise = false
  @State private var usageInsights: [String] = []
  @State private var isLoadingInsights = false

  // Enhanced coach response state
  @State private var checkInResponse: DailyCheckInResponse?
  @State private var isLoadingResponse = false
  @State private var responseError: String?
  @State private var loadingMessageIndex = 0
  @State private var loadingProgress: Double = 0.0
  
  private let loadingMessages = [
    "Analyzing your mood...",
    "Understanding your needs...",
    "Crafting personalized support...",
    "Almost ready with your plan...",
    "Finalizing your guidance..."
  ]

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

              // Enhanced Check-in Button with Loading Animation
              VStack(spacing: 12) {
                Button(action: runCheckIn) {
                  HStack(spacing: 12) {
                    if isLoadingResponse {
                      // Pulsing heart animation
                      Text("💙")
                        .font(.title2)
                        .scaleEffect(1.0 + 0.2 * sin(Date().timeIntervalSince1970 * 3))
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isLoadingResponse)
                    } else {
                      Text("💙")
                        .font(.title2)
                    }
                    Text(isLoadingResponse ? loadingMessages[loadingMessageIndex] : "Get Support")
                      .font(.headline)
                      .fontWeight(.semibold)
                  }
                  .foregroundColor(.white)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 16)
                  .background(
                    RoundedRectangle(cornerRadius: 25)
                      .fill(isLoadingResponse ? Color.blue.opacity(0.8) : Color.blue)
                      .overlay(
                        // Progress bar overlay
                        RoundedRectangle(cornerRadius: 25)
                          .fill(Color.white.opacity(0.3))
                          .scaleEffect(x: loadingProgress, y: 1, anchor: .leading)
                          .animation(.linear(duration: 0.1), value: loadingProgress)
                      )
                  )
                }
                .disabled(isLoadingResponse)
                .scaleEffect(isLoadingResponse ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isLoadingResponse)
                
                // Loading progress indicator
                if isLoadingResponse {
                  VStack(spacing: 8) {
                    ProgressView(value: loadingProgress, total: 1.0)
                      .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                      .scaleEffect(y: 2)
                    
                    Text("Creating your personalized support plan...")
                      .font(.caption)
                      .foregroundColor(.secondary)
                      .multilineTextAlignment(.center)
                  }
                  .padding(.horizontal, 20)
                }
              }
              .padding(.horizontal, 20)
            }
            .padding(20)
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 20)

            // Usage Insights Section
            if !usageInsights.isEmpty {
              VStack(alignment: .leading, spacing: 16) {
                HStack {
                  Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                    .font(.title2)

                  Text("Your Progress Insights")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(.label))

                  Spacer()
                }

                ForEach(usageInsights, id: \.self) { insight in
                  HStack(alignment: .top, spacing: 12) {
                    Text("💡")
                      .font(.title3)

                    Text(insight)
                      .font(.body)
                      .foregroundColor(Color(.label))
                      .multilineTextAlignment(.leading)
                  }
                  .padding(.vertical, 4)
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

            // Generate Insights Button
            if usageInsights.isEmpty {
              Button(action: generateUsageInsights) {
                HStack(spacing: 12) {
                  if isLoadingInsights {
                    ProgressView()
                      .progressViewStyle(CircularProgressViewStyle(tint: .white))
                      .scaleEffect(0.8)
                  } else {
                    Image(systemName: "chart.bar.fill")
                      .font(.title2)
                  }

                  Text(isLoadingInsights ? "Analyzing..." : "Get Progress Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                  RoundedRectangle(cornerRadius: 25)
                    .fill(isLoadingInsights ? Color.gray : Color.green)
                )
              }
              .disabled(isLoadingInsights)
              .padding(.horizontal, 20)
            }

            // Enhanced Results Section
            VStack(alignment: .leading, spacing: 16) {
              Text("Your Check-in Results")
                .font(.title3).fontWeight(.semibold)

              Group {
                if isLoadingResponse {
                  ProgressView("Thinking…")
                } else if let err = responseError {
                  Text("Hmm, something went wrong: \(err)")
                    .font(.footnote).foregroundColor(.secondary)
                  // show a safe default
                  EnhancedCoachCard(
                    response: DailyCheckInResponse(from: [
                      "severity": 1,
                      "coachLine": "That was a lot. Let's reset your body first—60 seconds.",
                      "quickResetSteps": [
                        "Sit comfortably and soften your gaze",
                        "Inhale 4 seconds, Hold 4, Exhale 6",
                        "Repeat 3 rounds",
                      ],
                    ]))
                } else if let r = checkInResponse {
                  EnhancedCoachCard(response: r)
                } else {
                  // nothing fetched yet → hide card or show a hint
                  Text("Tap **Get Support** to see your coach's suggestion.")
                    .font(.footnote).foregroundColor(.secondary)
                }
              }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            .padding(.horizontal, 20)

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
      .sheet(item: $emergencyExercise) { exercise in
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

  private func generateEmergencyExercise() async {
    isGeneratingExercise = true

    do {
      // Use OpenAI to generate a high-intensity emergency exercise
      let exercisePrompt = """
        Create an emergency calming exercise for someone experiencing high stress, anxiety, or overwhelming feelings. 
        The person rated their mood as \(mood)/10 and is feeling: \(tags.joined(separator: ", ")).
        Additional context: \(note.isEmpty ? "No additional details" : note)

        Generate a practical, immediate relief exercise that can be done anywhere in 2-3 minutes.
        Focus on grounding techniques, body awareness, physical movement, or mindfulness practices.
        DO NOT create a breathing exercise - focus on other calming techniques instead.
        Provide clear step-by-step instructions.
        """

      let exerciseInstructions = try await OpenAIService.shared.sendMessage(
        exercisePrompt,
        systemPrompt:
          "You are an expert in emergency calming techniques. Generate practical, step-by-step exercises that help people quickly calm down without focusing on breathing patterns."
      )

      // Create Exercise object from AI response - force it to be a generic exercise
      emergencyExercise = Exercise(
        id: UUID(),
        title: "Emergency Calming Exercise",  // Non-breathing title to avoid auto-detection
        duration: 180,  // 3 minutes for high severity
        steps: exerciseInstructions.components(separatedBy: "\n").filter {
          !$0.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty
        },
        prompt: "An AI-generated emergency exercise tailored to your current emotional state"
      )

    } catch {
      print("Failed to generate emergency exercise: \(error)")
      // Fallback to a default emergency exercise (non-breathing)
      emergencyExercise = Exercise(
        id: UUID(),
        title: "Emergency Grounding Technique",
        duration: 180,
        steps: [
          "Look around and name 5 things you can see",
          "Listen and name 4 things you can hear",
          "Touch and name 3 things you can feel (your clothes, a surface, etc.)",
          "Name 2 things you can smell",
          "Name 1 thing you can taste",
          "Take a moment to notice how you feel now",
          "Repeat if needed until you feel more grounded",
        ],
        prompt: "A 5-4-3-2-1 grounding exercise for high stress moments"
      )
    }

    isGeneratingExercise = false
  }

  private func runCheckIn() {
    isLoadingResponse = true
    responseError = nil
    checkInResponse = nil
    loadingMessageIndex = 0
    loadingProgress = 0.0

    // Start loading animation timer
    startLoadingAnimation()

    Task {
      do {
        let functions = Functions.functions(region: "europe-west1")
        let callable = functions.httpsCallable("dailyCheckIn")

        let payload: [String: Any] = [
          "checkin": [
            "mood": mood,
            "tags": Array(tags).map { $0.lowercased() },
            "note": note,
          ]
        ]

        // Simulate progress updates
        await updateProgress(0.2)
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        await updateProgress(0.4)
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        await updateProgress(0.6)
        let result = try await callable.call(payload)
        
        await updateProgress(0.8)
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Log shape once, super handy:
        printJSON(result.data, prefix: "🧩 CheckIn raw response")

        guard let outer = result.data as? [String: Any] else {
          throw NSError(
            domain: "Parse", code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        let dict = (outer["data"] as? [String: Any]) ?? outer
        let parsed = DailyCheckInResponse(from: dict)

        await updateProgress(1.0)
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        await MainActor.run {
          self.checkInResponse = parsed
          self.isLoadingResponse = false
        }
      } catch {
        await MainActor.run {
          self.responseError = error.localizedDescription
          self.isLoadingResponse = false
        }
      }
    }
  }
  
  private func startLoadingAnimation() {
    Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
      guard isLoadingResponse else {
        timer.invalidate()
        return
      }
      
      withAnimation(.easeInOut(duration: 0.5)) {
        loadingMessageIndex = (loadingMessageIndex + 1) % loadingMessages.count
      }
    }
  }
  
  @MainActor
  private func updateProgress(_ progress: Double) {
    withAnimation(.linear(duration: 0.3)) {
      loadingProgress = progress
    }
  }

  private func generateUsageInsights() {
    isLoadingInsights = true

    Task {
      do {
        // Analyze usage patterns
        let usageAnalysis = analyzeUsagePatterns()

        // Generate insights based on patterns
        let insights = generateInsightsFromUsage(usageAnalysis)

        await MainActor.run {
          usageInsights = insights
          isLoadingInsights = false
        }
      } catch {
        await MainActor.run {
          isLoadingInsights = false
        }
        print("Error generating usage insights: \(error)")
      }
    }
  }

  private func analyzeUsagePatterns() -> [String: Any] {
    let progressTracker = ProgressTracker.shared

    // Analyze usage patterns
    let totalUsage = progressTracker.totalUsage
    let weeklyUsage = progressTracker.weeklyUsage
    let currentStreak = progressTracker.currentStreak
    let longestStreak = progressTracker.longestStreak
    let daysThisWeek = progressTracker.daysThisWeek

    // Calculate usage frequency
    let usageFrequency = totalUsage > 0 ? Double(weeklyUsage) / 7.0 : 0.0

    // Analyze relief outcomes
    let reliefOutcomes = progressTracker.reliefOutcomes
    let betterNowCount = reliefOutcomes.filter { $0 == .betterNow }.count
    let stillNeedHelpCount = reliefOutcomes.filter { $0 == .stillNeedHelp }.count
    let successRate =
      reliefOutcomes.count > 0 ? Double(betterNowCount) / Double(reliefOutcomes.count) : 0.0

    // Analyze help options used
    let helpOptions = progressTracker.helpOptionsUsed
    let mostUsedOptions = Dictionary(grouping: helpOptions, by: { $0 })
      .mapValues { $0.count }
      .sorted { $0.value > $1.value }
      .prefix(3)

    return [
      "totalUsage": totalUsage,
      "weeklyUsage": weeklyUsage,
      "currentStreak": currentStreak,
      "longestStreak": longestStreak,
      "daysThisWeek": daysThisWeek,
      "usageFrequency": usageFrequency,
      "successRate": successRate,
      "betterNowCount": betterNowCount,
      "stillNeedHelpCount": stillNeedHelpCount,
      "mostUsedOptions": Array(mostUsedOptions),
      "hasRecentUsage": progressTracker.lastUsedDate != nil,
    ]
  }

  private func generateInsightsFromUsage(_ analysis: [String: Any]) -> [String] {
    var insights: [String] = []

    let totalUsage = analysis["totalUsage"] as? Int ?? 0
    let currentStreak = analysis["currentStreak"] as? Int ?? 0
    let longestStreak = analysis["longestStreak"] as? Int ?? 0
    let successRate = analysis["successRate"] as? Double ?? 0.0
    let usageFrequency = analysis["usageFrequency"] as? Double ?? 0.0
    let daysThisWeek = analysis["daysThisWeek"] as? Int ?? 0

    // Generate insights based on patterns
    if currentStreak > 0 {
      insights.append(
        "You're on a \(currentStreak)-day streak! Consistency is key to building healthy habits.")
    }

    if longestStreak > currentStreak {
      insights.append("Your longest streak was \(longestStreak) days - you know you can do this!")
    }

    if successRate > 0.7 {
      insights.append(
        "You're finding relief \(Int(successRate * 100))% of the time - that's excellent progress!")
    } else if successRate > 0.5 {
      insights.append(
        "You're finding relief \(Int(successRate * 100))% of the time - keep practicing!")
    }

    if usageFrequency > 0.5 {
      insights.append("You're using the app almost daily - that's a great habit to maintain!")
    } else if usageFrequency > 0.2 {
      insights.append("You're building a regular practice - every bit helps!")
    }

    if daysThisWeek >= 5 {
      insights.append(
        "You've used the app \(daysThisWeek) days this week - you're really committed to your wellbeing!"
      )
    } else if daysThisWeek >= 3 {
      insights.append("You've used the app \(daysThisWeek) days this week - nice consistency!")
    }

    if totalUsage > 20 {
      insights.append(
        "You've used the app \(totalUsage) times total - you're building real expertise in self-care!"
      )
    } else if totalUsage > 10 {
      insights.append(
        "You've used the app \(totalUsage) times - you're developing good coping skills!")
    }

    // If no specific insights, provide encouragement
    if insights.isEmpty {
      insights.append(
        "Every time you use the app, you're taking a positive step for your mental health.")
      insights.append("Remember, progress isn't always linear - be patient with yourself.")
    }

    return insights
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
  @State private var activeExercise: Exercise?
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
        guard !isLaunchingExercise && activeExercise == nil else { return }
        isLaunchingExercise = true

        print("Start Exercise tapped")  // Debug logging

        // Create Exercise model from dictionary and set as active
        if let exerciseObj = Exercise.fromAIResponse(exercise) {
          activeExercise = exerciseObj
        } else {
          // Fallback to default breathing exercise
          activeExercise = Exercise(
            id: UUID(),
            title: "Breathing Exercise",
            duration: 60,
            steps: ["Inhale slowly", "Hold", "Exhale slowly"],
            prompt: nil
          )
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
            .fill(isLaunchingExercise ? Color.gray : Color.blue)
        )
      }
      .disabled(isLaunchingExercise)
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.blue.opacity(0.1))
    )
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

// MARK: - Enhanced Coach Card Component
struct EnhancedCoachCard: View {
  let response: DailyCheckInResponse
  @State private var activeExercise: Exercise?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {

      // Severity pill (keeps your existing visual language)
      HStack {
        Label(
          response.severity <= 2
            ? "Mild Concern" : response.severity <= 4 ? "Moderate Concern" : "High Concern",
          systemImage: "exclamationmark.triangle"
        )
        .font(.subheadline)
        Spacer()
        Text("Level \(response.severity)").font(.caption).foregroundColor(.secondary)
      }
      .padding(12)
      .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.08)))

      if let coach = response.coachLine {
        Text(coach).font(.body)
      }

      // Quick Reset
      let quick =
        response.quickResetSteps ?? [
          "Sit comfortably and soften your gaze",
          "Inhale 4 seconds, Hold 4, Exhale 6",
          "Repeat 3 rounds",
        ]

      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Image(systemName: "figure.mind.and.body").foregroundColor(.blue)
          Text(response.exercise ?? "Quick Reset").font(.headline)
          Spacer()
          Text("≈ 60–90s").font(.caption).foregroundColor(.secondary)
        }
        ForEach(Array(quick.enumerated()), id: \.offset) { i, s in
          HStack(alignment: .top) {
            Text("\(i+1).").font(.caption).foregroundColor(.blue)
            Text(s).font(.subheadline)
          }
        }

        Button {
          // Create exercise from the quick reset steps
          let exercise = Exercise(
            id: UUID(),
            title: response.exercise ?? "Quick Reset",
            duration: 90, // 60-90 seconds as shown in UI
            steps: quick,
            prompt: "A quick reset exercise from your daily check-in"
          )
          activeExercise = exercise
        } label: {
          Label("Start Exercise", systemImage: "play.fill")
        }
        .buttonStyle(.borderedProminent)
      }
      .padding()
      .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.08)))

      // Process It (optional)
      if let process = response.processItSteps, !process.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Image(systemName: "text.bubble").foregroundColor(.purple)
            Text("Process It (2–3 min)").font(.headline)
          }
          ForEach(Array(process.enumerated()), id: \.offset) { i, s in
            HStack(alignment: .top) {
              Text("\(i+1).").font(.caption).foregroundColor(.purple)
              Text(s).font(.subheadline)
            }
          }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.purple.opacity(0.08)))
      }

      // Reframe chips (optional)
      if let chips = response.reframeChips, !chips.isEmpty {
        WrapChips(chips: chips)
      }

      if let insight = response.microInsight {
        Text(insight).font(.footnote).foregroundColor(.secondary)
      }
      if let plan = response.ifThenPlan {
        Text("If-Then: \(plan)").font(.footnote)
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

struct WrapChips: View {
  let chips: [String]
  var body: some View {
    FlowLayout(spacing: 8) {
      ForEach(chips, id: \.self) { c in
        Text(c).font(.caption)
          .padding(.horizontal, 10).padding(.vertical, 6)
          .background(Capsule().fill(Color(.secondarySystemBackground)))
      }
    }
  }
}

#Preview {
  DailyCoachView()
}
