import SwiftData
import SwiftUI

struct EnhancedPanicPlanView: View {
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.modelContext) private var modelContext
  @Query private var journalEntries: [JournalEntry]
  
  @StateObject private var audioManager = AudioManager.shared
  @StateObject private var progressTracker = ProgressTracker.shared
  
  @State private var selectedPlan: PanicPlan?
  @State private var showingPlanEditor = false
  @State private var showingPlanExecution = false
  @State private var isGeneratingAIPlan = false
  @State private var aiInsights: [String] = []
  @State private var isLoadingInsights = false
  @State private var userPlans: [PanicPlan] = []
  
  // Sample panic plans - in a real app, these would be stored in UserDefaults or Core Data
  @State private var defaultPlans: [PanicPlan] = [
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
              Text("🧠")
                .font(.system(size: 60))
              
              Text("AI-Enhanced Panic Plan")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color(.label))
              
              Text("Your personalized plan with insights from your journal")
                .font(.body)
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            }
            .padding(.top, 20)
            
            // AI Insights Section
            if !aiInsights.isEmpty {
              VStack(alignment: .leading, spacing: 16) {
                HStack {
                  Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                  
                  Text("Personalized Insights")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(.label))
                  
                  Spacer()
                }
                
                ForEach(aiInsights, id: \.self) { insight in
                  HStack(alignment: .top, spacing: 12) {
                    Text("•")
                      .foregroundColor(.blue)
                      .font(.title3)
                      .fontWeight(.bold)
                    
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
            if aiInsights.isEmpty {
              Button(action: generateInsights) {
                HStack(spacing: 12) {
                  if isLoadingInsights {
                    ProgressView()
                      .progressViewStyle(CircularProgressViewStyle(tint: .white))
                      .scaleEffect(0.8)
                  } else {
                    Image(systemName: "brain.head.profile")
                      .font(.title2)
                  }
                  
                  Text(isLoadingInsights ? "Analyzing..." : "Generate Personal Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                  RoundedRectangle(cornerRadius: 25)
                    .fill(isLoadingInsights ? Color.gray : Color.blue)
                )
              }
              .disabled(isLoadingInsights)
              .padding(.horizontal, 20)
            }
            
            // Panic Plans Section
            VStack(alignment: .leading, spacing: 16) {
              HStack {
                Image(systemName: "list.bullet.clipboard.fill")
                  .foregroundColor(.green)
                  .font(.title2)
                
                Text("Your Panic Plans")
                  .font(.title2)
                  .fontWeight(.bold)
                  .foregroundColor(Color(.label))
                
                Spacer()
                
                Button(action: { showingPlanEditor = true }) {
                  Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                }
              }
              
              if userPlans.isEmpty {
                VStack(spacing: 12) {
                  Text("No plans yet")
                    .font(.headline)
                    .foregroundColor(Color(.secondaryLabel))
                  
                  Text("Create your first personalized panic plan")
                    .font(.body)
                    .foregroundColor(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
              } else {
                ForEach(userPlans) { plan in
                  PanicPlanCard(
                    plan: plan,
                    onSelect: { selectedPlan = plan },
                    onExecute: { 
                      selectedPlan = plan
                      showingPlanExecution = true
                    }
                  )
                }
              }
            }
            .padding(20)
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
            
            // Generate AI Plan Button
            Button(action: generateAIPanicPlan) {
              HStack(spacing: 12) {
                if isGeneratingAIPlan {
                  ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                } else {
                  Image(systemName: "sparkles")
                    .font(.title2)
                }
                
                Text(isGeneratingAIPlan ? "Creating..." : "Generate AI Plan")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 16)
              .background(
                RoundedRectangle(cornerRadius: 25)
                  .fill(isGeneratingAIPlan ? Color.gray : Color.purple)
              )
            }
            .disabled(isGeneratingAIPlan)
            .padding(.horizontal, 20)
            
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
        PanicPlanEditorView(
          onSave: { plan in
            userPlans.append(plan)
          }
        )
      }
      .sheet(isPresented: $showingPlanExecution) {
        if let plan = selectedPlan {
          PanicPlanExecutionView(plan: plan)
        }
      }
      .onAppear {
        loadUserPlans()
      }
    }
  }
  
  // MARK: - Private Methods
  
  private func loadUserPlans() {
    // Load from UserDefaults or Core Data
    if let data = UserDefaults.standard.data(forKey: "userPanicPlans"),
       let plans = try? JSONDecoder().decode([PanicPlan].self, from: data) {
      userPlans = plans
    } else {
      userPlans = defaultPlans
    }
  }
  
  private func saveUserPlans() {
    if let data = try? JSONEncoder().encode(userPlans) {
      UserDefaults.standard.set(data, forKey: "userPanicPlans")
    }
  }
  
  private func generateInsights() {
    isLoadingInsights = true
    
    Task {
      do {
        // Analyze journal entries for patterns
        let journalAnalysis = analyzeJournalEntries()
        
        // Generate insights using AI
        let insights = try await generatePersonalizedInsights(from: journalAnalysis)
        
        await MainActor.run {
          aiInsights = insights
          isLoadingInsights = false
        }
      } catch {
        await MainActor.run {
          isLoadingInsights = false
          // Handle error - could show alert
        }
        print("Error generating insights: \(error)")
      }
    }
  }
  
  private func analyzeJournalEntries() -> [String: Any] {
    let recentEntries = journalEntries.suffix(10) // Last 10 entries
    
    var emotionCounts: [String: Int] = [:]
    var intensityCounts: [String: Int] = [:]
    var commonFactors: [String: Int] = [:]
    var timePatterns: [String: Int] = [:]
    
    for entry in recentEntries {
      // Count emotions
      if let emotion = entry.emotion {
        emotionCounts[emotion, default: 0] += 1
      }
      
      // Count intensities
      if let intensity = entry.intensity {
        intensityCounts[intensity, default: 0] += 1
      }
      
      // Count contributing factors
      if let factors = entry.contributingFactors {
        for factor in factors {
          commonFactors[factor, default: 0] += 1
        }
      }
      
      // Analyze time patterns
      let hour = Calendar.current.component(.hour, from: entry.timestamp)
      let timeOfDay = hour < 12 ? "morning" : hour < 18 ? "afternoon" : "evening"
      timePatterns[timeOfDay, default: 0] += 1
    }
    
    return [
      "emotionCounts": emotionCounts,
      "intensityCounts": intensityCounts,
      "commonFactors": commonFactors,
      "timePatterns": timePatterns,
      "totalEntries": recentEntries.count,
      "dateRange": [
        "start": recentEntries.first?.timestamp ?? Date(),
        "end": recentEntries.last?.timestamp ?? Date()
      ]
    ]
  }
  
  private func generatePersonalizedInsights(from analysis: [String: Any]) async throws -> [String] {
    // Use the existing AI service to generate insights
    let prompt = """
    Based on the user's journal analysis, provide 3-5 gentle, non-directive insights about their patterns and progress. 
    Focus on positive observations and gentle suggestions. Be encouraging and supportive.
    
    Analysis data: \(analysis)
    
    Examples of good insights:
    - "You've been using the app more consistently this week - that's great progress!"
    - "I notice you often feel anxious in the afternoon - maybe scheduling a short break then could help"
    - "Your journal entries show you're getting better at identifying your triggers"
    
    Keep insights brief, positive, and actionable.
    """
    
    // For now, return mock insights - in production, this would call the AI service
    return [
      "You've been journaling consistently for the past week - that's great progress!",
      "I notice you often feel anxious in the afternoon. Maybe scheduling a short break then could help.",
      "Your entries show you're getting better at identifying your triggers - that's a valuable skill.",
      "You've been using calming techniques more frequently, which shows you're building healthy habits."
    ]
  }
  
  private func generateAIPanicPlan() {
    isGeneratingAIPlan = true
    
    Task {
      do {
        // Analyze journal entries for personalization
        let journalAnalysis = analyzeJournalEntries()
        
        // Create intake data for AI
        let intake: [String: Any] = [
          "context": "personalized based on journal analysis",
          "pref_breath": "box",
          "duration": "short",
          "journal_insights": journalAnalysis,
          "personalizedPhrase": "I am safe and I can handle this"
        ]
        
        let result = try await AiService.shared.generatePanicPlan(intake: intake)
        
        await MainActor.run {
          let newPlan = PanicPlan(
            title: "AI-Enhanced Plan",
            description: "Personalized plan based on your journal patterns",
            steps: parseStructuredPlan(result),
            duration: extractDuration(from: result),
            techniques: extractTechniques(from: result),
            emergencyContact: nil,
            personalizedPhrase: "I am safe and I can handle this"
          )
          
          userPlans.append(newPlan)
          saveUserPlans()
          isGeneratingAIPlan = false
        }
      } catch {
        await MainActor.run {
          isGeneratingAIPlan = false
        }
        print("AI Plan generation error:", error)
      }
    }
  }
  
  // MARK: - Helper Methods
  
  private func parseStructuredPlan(_ result: [String: Any]) -> [String] {
    if let steps = result["steps"] as? [String] {
      return steps
    }
    return ["Take deep breaths", "Ground yourself", "Use your calming phrase"]
  }
  
  private func extractDuration(from result: [String: Any]) -> Int {
    if let duration = result["duration"] as? Int {
      return duration
    }
    return 120
  }
  
  private func extractTechniques(from result: [String: Any]) -> [String] {
    if let techniques = result["techniques"] as? [String] {
      return techniques
    }
    return ["Breathing", "Grounding", "Mindfulness"]
  }
}

// MARK: - Supporting Views

struct PanicPlanCard: View {
  let plan: PanicPlan
  let onSelect: () -> Void
  let onExecute: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(plan.title)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(Color(.label))
          
          Text(plan.description)
            .font(.subheadline)
            .foregroundColor(Color(.secondaryLabel))
        }
        
        Spacer()
        
        Text("\(plan.duration)s")
          .font(.caption)
          .fontWeight(.medium)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.blue.opacity(0.2))
          .foregroundColor(.blue)
          .cornerRadius(8)
      }
      
      HStack(spacing: 8) {
        ForEach(plan.techniques.prefix(3), id: \.self) { technique in
          Text(technique)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.green.opacity(0.2))
            .foregroundColor(.green)
            .cornerRadius(4)
        }
        
        if plan.techniques.count > 3 {
          Text("+\(plan.techniques.count - 3)")
            .font(.caption)
            .foregroundColor(Color(.secondaryLabel))
        }
      }
      
      HStack(spacing: 12) {
        Button(action: onSelect) {
          Text("View Details")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.blue)
        }
        
        Spacer()
        
        Button(action: onExecute) {
          HStack(spacing: 4) {
            Image(systemName: "play.fill")
              .font(.caption)
            Text("Start")
              .font(.subheadline)
              .fontWeight(.medium)
          }
          .foregroundColor(.white)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Color.blue)
          .cornerRadius(8)
        }
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(.systemGray6))
    )
  }
}

struct PanicPlanEditorView: View {
  @Environment(\.presentationMode) var presentationMode
  let onSave: (PanicPlan) -> Void
  
  @State private var title = ""
  @State private var description = ""
  @State private var steps: [String] = [""]
  @State private var duration = 120
  @State private var techniques: [String] = []
  @State private var personalizedPhrase = "I am safe and I can handle this"
  
  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Plan Details")) {
          TextField("Plan Title", text: $title)
          TextField("Description", text: $description)
          Stepper("Duration: \(duration) seconds", value: $duration, in: 30...600, step: 30)
        }
        
        Section(header: Text("Steps")) {
          ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
            TextField("Step \(index + 1)", text: $steps[index])
          }
          .onDelete(perform: deleteStep)
          
          Button("Add Step") {
            steps.append("")
          }
        }
        
        Section(header: Text("Personalized Phrase")) {
          TextField("Your calming phrase", text: $personalizedPhrase)
        }
      }
      .navigationTitle("New Panic Plan")
      .navigationBarItems(
        leading: Button("Cancel") {
          presentationMode.wrappedValue.dismiss()
        },
        trailing: Button("Save") {
          let plan = PanicPlan(
            title: title.isEmpty ? "My Plan" : title,
            description: description.isEmpty ? "Personalized panic plan" : description,
            steps: steps.filter { !$0.isEmpty },
            duration: duration,
            techniques: ["Custom"],
            personalizedPhrase: personalizedPhrase
          )
          onSave(plan)
          presentationMode.wrappedValue.dismiss()
        }
        .disabled(title.isEmpty || steps.allSatisfy { $0.isEmpty })
      )
    }
  }
  
  private func deleteStep(at offsets: IndexSet) {
    steps.remove(atOffsets: offsets)
  }
}

struct PanicPlanExecutionView: View {
  @Environment(\.presentationMode) var presentationMode
  let plan: PanicPlan
  
  @State private var currentStepIndex = 0
  @State private var isCompleted = false
  
  var body: some View {
    NavigationView {
      VStack(spacing: 24) {
        Text(plan.title)
          .font(.largeTitle)
          .fontWeight(.bold)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
        
        Text(plan.personalizedPhrase)
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(.blue)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
        
        if !isCompleted {
          VStack(spacing: 16) {
            Text("Step \(currentStepIndex + 1) of \(plan.steps.count)")
              .font(.headline)
              .foregroundColor(Color(.secondaryLabel))
            
            Text(plan.steps[currentStepIndex])
              .font(.title3)
              .fontWeight(.medium)
              .multilineTextAlignment(.center)
              .padding(.horizontal)
            
            Button(action: nextStep) {
              Text(currentStepIndex == plan.steps.count - 1 ? "Complete" : "Next Step")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(25)
            }
            .padding(.horizontal)
          }
        } else {
          VStack(spacing: 16) {
            Text("✅")
              .font(.system(size: 60))
            
            Text("Plan Completed!")
              .font(.title2)
              .fontWeight(.bold)
            
            Text("You've successfully completed your panic plan. How are you feeling now?")
              .font(.body)
              .multilineTextAlignment(.center)
              .foregroundColor(Color(.secondaryLabel))
              .padding(.horizontal)
          }
        }
        
        Spacer()
      }
      .padding()
      .navigationBarItems(
        leading: Button("Close") {
          presentationMode.wrappedValue.dismiss()
        }
      )
    }
  }
  
  private func nextStep() {
    if currentStepIndex < plan.steps.count - 1 {
      currentStepIndex += 1
    } else {
      isCompleted = true
    }
  }
}

#Preview {
  EnhancedPanicPlanView()
    .modelContainer(for: JournalEntry.self)
}
