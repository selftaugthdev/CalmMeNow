import SwiftUI

struct PersonalizedPanicPlanGeneratorView: View {
  @StateObject private var viewModel = AIServiceViewModel()
  @Environment(\.dismiss) private var dismiss

  @State private var triggers: [String] = []
  @State private var symptoms: [String] = []
  @State private var preferences: [String] = []
  @State private var duration: Int = 300
  @State private var phrase: String = "This will pass; I'm safe."

  @State private var newTrigger = ""
  @State private var newSymptom = ""
  @State private var newPreference = ""

  private let commonTriggers = [
    "Crowded places", "Work stress", "Social situations", "Health concerns", "Financial worries",
  ]
  private let commonSymptoms = [
    "Racing heart", "Dizziness", "Shortness of breath", "Sweating", "Trembling",
  ]
  private let commonPreferences = [
    "Breathing exercises", "Grounding techniques", "Mindfulness", "Physical movement", "Music",
  ]

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          // Header
          VStack(spacing: 8) {
            Image(systemName: "brain.head.profile")
              .font(.system(size: 50))
              .foregroundColor(.blue)

            Text("Personalized Panic Plan")
              .font(.title2)
              .fontWeight(.bold)

            Text("Tell us about your experience to create a custom plan")
              .font(.subheadline)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
          }
          .padding(.top)

          // Triggers Section
          VStack(alignment: .leading, spacing: 12) {
            Text("What triggers your overwhelming feelings?")
              .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
              ForEach(commonTriggers, id: \.self) { trigger in
                Button(action: {
                  if triggers.contains(trigger) {
                    triggers.removeAll { $0 == trigger }
                  } else {
                    triggers.append(trigger)
                  }
                }) {
                  Text(trigger)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(triggers.contains(trigger) ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(triggers.contains(trigger) ? .white : .primary)
                    .cornerRadius(20)
                }
              }
            }

            HStack {
              TextField("Add custom trigger", text: $newTrigger)
                .textFieldStyle(RoundedBorderTextFieldStyle())

              Button("Add") {
                if !newTrigger.isEmpty {
                  triggers.append(newTrigger)
                  newTrigger = ""
                }
              }
              .disabled(newTrigger.isEmpty)
            }
          }

          // Symptoms Section
          VStack(alignment: .leading, spacing: 12) {
            Text("What symptoms do you experience?")
              .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
              ForEach(commonSymptoms, id: \.self) { symptom in
                Button(action: {
                  if symptoms.contains(symptom) {
                    symptoms.removeAll { $0 == symptom }
                  } else {
                    symptoms.append(symptom)
                  }
                }) {
                  Text(symptom)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(symptoms.contains(symptom) ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(symptoms.contains(symptom) ? .white : .primary)
                    .cornerRadius(20)
                }
              }
            }

            HStack {
              TextField("Add custom symptom", text: $newSymptom)
                .textFieldStyle(RoundedBorderTextFieldStyle())

              Button("Add") {
                if !newSymptom.isEmpty {
                  symptoms.append(newSymptom)
                  newSymptom = ""
                }
              }
              .disabled(newSymptom.isEmpty)
            }
          }

          // Preferences Section
          VStack(alignment: .leading, spacing: 12) {
            Text("What helps you calm down?")
              .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
              ForEach(commonPreferences, id: \.self) { preference in
                Button(action: {
                  if preferences.contains(preference) {
                    preferences.removeAll { $0 == preference }
                  } else {
                    preferences.append(preference)
                  }
                }) {
                  Text(preference)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                      preferences.contains(preference) ? Color.blue : Color.gray.opacity(0.2)
                    )
                    .foregroundColor(preferences.contains(preference) ? .white : .primary)
                    .cornerRadius(20)
                }
              }
            }

            HStack {
              TextField("Add custom preference", text: $newPreference)
                .textFieldStyle(RoundedBorderTextFieldStyle())

              Button("Add") {
                if !newPreference.isEmpty {
                  preferences.append(newPreference)
                  newPreference = ""
                }
              }
              .disabled(newPreference.isEmpty)
            }
          }

          // Duration and Phrase
          VStack(alignment: .leading, spacing: 12) {
            Text("Plan Duration (minutes)")
              .font(.headline)

            Picker("Duration", selection: $duration) {
              Text("2 min").tag(120)
              Text("5 min").tag(300)
              Text("10 min").tag(600)
              Text("15 min").tag(900)
            }
            .pickerStyle(SegmentedPickerStyle())

            Text("Your Calming Phrase")
              .font(.headline)

            TextField("Enter a phrase that helps you", text: $phrase)
              .textFieldStyle(RoundedBorderTextFieldStyle())
          }

          // Generate Button
          Button(action: {
            Task {
              await viewModel.generatePanicPlan(
                triggers: triggers,
                symptoms: symptoms,
                preferences: preferences,
                duration: duration,
                phrase: phrase
              )
            }
          }) {
            HStack {
              if viewModel.isLoading {
                ProgressView()
                  .progressViewStyle(CircularProgressViewStyle(tint: .white))
                  .scaleEffect(0.8)
              } else {
                Image(systemName: "wand.and.stars")
              }

              Text(viewModel.isLoading ? "Generating..." : "Generate My Plan")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
              triggers.isEmpty || symptoms.isEmpty || preferences.isEmpty
                ? Color.gray
                : Color.blue
            )
            .cornerRadius(12)
          }
          .disabled(
            triggers.isEmpty || symptoms.isEmpty || preferences.isEmpty || viewModel.isLoading)

          if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
              .foregroundColor(.red)
              .font(.caption)
              .multilineTextAlignment(.center)
          }
        }
        .padding()
      }
      .navigationTitle("Create Plan")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
    .onAppear {
      viewModel.loadStoredPlan()
    }
    .sheet(item: $viewModel.currentPlan) { plan in
      PanicPlanDetailView(plan: plan)
    }
  }
}

struct PanicPlanDetailView: View {
  let plan: PanicPlan
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          // Header
          VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 60))
              .foregroundColor(.green)

            Text(plan.title)
              .font(.title)
              .fontWeight(.bold)
              .multilineTextAlignment(.center)

            Text(plan.description)
              .font(.subheadline)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
          }
          .padding(.top)

          // Steps
          VStack(alignment: .leading, spacing: 16) {
            Text("Your Plan Steps")
              .font(.headline)

            ForEach(Array(plan.steps.enumerated()), id: \.offset) { index, step in
              HStack(alignment: .top, spacing: 12) {
                Text("\(index + 1)")
                  .font(.headline)
                  .foregroundColor(.white)
                  .frame(width: 30, height: 30)
                  .background(Color.blue)
                  .clipShape(Circle())

                Text(step)
                  .font(.body)

                Spacer()
              }
            }
          }

          // Techniques
          VStack(alignment: .leading, spacing: 12) {
            Text("Recommended Techniques")
              .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
              ForEach(plan.techniques, id: \.self) { technique in
                Text(technique)
                  .font(.caption)
                  .padding(.horizontal, 12)
                  .padding(.vertical, 8)
                  .background(Color.blue.opacity(0.1))
                  .foregroundColor(.blue)
                  .cornerRadius(20)
              }
            }
          }

          // Personal Phrase
          VStack(alignment: .leading, spacing: 12) {
            Text("Your Calming Phrase")
              .font(.headline)

            Text(plan.personalizedPhrase)
              .font(.title3)
              .italic()
              .padding()
              .frame(maxWidth: .infinity)
              .background(Color.blue.opacity(0.1))
              .cornerRadius(12)
          }

          // Duration
          HStack {
            Image(systemName: "clock")
              .foregroundColor(.blue)

            Text("Plan Duration: \(plan.duration / 60) minutes")
              .font(.subheadline)

            Spacer()
          }
          .padding()
          .background(Color.gray.opacity(0.1))
          .cornerRadius(12)

          // Start Plan Button
          Button(action: {
            // Navigate to the plan execution view
            dismiss()
          }) {
            HStack {
              Image(systemName: "play.fill")
              Text("Start My Plan")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
          }
        }
        .padding()
      }
      .navigationTitle("Your Plan")
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
  PersonalizedPanicPlanGeneratorView()
}
