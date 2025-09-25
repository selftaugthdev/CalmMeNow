import Foundation

struct PanicPlan: Codable, Identifiable, Hashable {
  let id: UUID
  var title: String
  var description: String
  var steps: [PlanStep]
  var duration: Int
  var techniques: [String]
  var emergencyContact: String?
  var personalizedPhrase: String?
  let createdAt: Date

  // Method to recalculate duration from steps
  mutating func recalculateDuration() {
    self.duration = steps.compactMap { $0.seconds }.reduce(0, +)
  }

  init(from dict: [String: Any]) {
    self.id = UUID()
    self.title = dict["title"] as? String ?? "Personalized Calm Plan"
    self.description =
      dict["description"] as? String ?? "Your customized plan for managing overwhelming moments"

    // Convert string steps to PlanStep objects
    if let stringSteps = dict["steps"] as? [String] {
      self.steps = stringSteps.map { PlanStep(type: .custom, text: $0) }
    } else {
      self.steps = [
        PlanStep(type: .breathing, text: "Take deep breaths"),
        PlanStep(type: .grounding, text: "Ground yourself"),
        PlanStep(type: .affirmation, text: "Use your calming phrase"),
      ]
    }

    self.duration = dict["duration"] as? Int ?? 300
    self.techniques = dict["techniques"] as? [String] ?? ["Breathing", "Grounding", "Mindfulness"]
    self.emergencyContact = dict["emergencyContact"] as? String
    self.personalizedPhrase = dict["personalizedPhrase"] as? String ?? "This will pass; I'm safe."
    self.createdAt = Date()
  }

  // Custom initializer for creating PanicPlan instances
  init(
    id: UUID = UUID(),
    title: String,
    description: String,
    steps: [PlanStep],
    duration: Int? = nil,  // Make duration optional
    techniques: [String],
    emergencyContact: String? = nil,
    personalizedPhrase: String? = nil,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.steps = steps
    // Calculate duration from steps if not provided
    self.duration = duration ?? steps.compactMap { $0.seconds }.reduce(0, +)
    self.techniques = techniques
    self.emergencyContact = emergencyContact
    self.personalizedPhrase = personalizedPhrase
    self.createdAt = createdAt
  }

  // Convenience initializer for backward compatibility with string steps
  init(
    id: UUID = UUID(),
    title: String,
    description: String,
    stringSteps: [String],
    duration: Int,
    techniques: [String],
    emergencyContact: String? = nil,
    personalizedPhrase: String? = nil,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.steps = stringSteps.map { PlanStep(type: .custom, text: $0) }
    self.duration = duration
    self.techniques = techniques
    self.emergencyContact = emergencyContact
    self.personalizedPhrase = personalizedPhrase
    self.createdAt = createdAt
  }
}

struct DailyCheckInResponse: Codable, Identifiable {
  let id = UUID()
  let severity: Int
  let exercise: String?
  let resources: [String]?
  let message: String
  let recommendations: [String]

  // Enhanced coach features
  let coachLine: String?
  let protocolType: String?
  let quickResetSteps: [String]?
  let processItSteps: [String]?
  let reframeChips: [String]?
  let microInsight: String?
  let ifThenPlan: String?

  init(from dict: [String: Any]) {
    self.severity = dict["severity"] as? Int ?? 1
    self.exercise = dict["exercise"] as? String
    self.resources = dict["resources"] as? [String]
    self.message = dict["message"] as? String ?? "Thank you for checking in"
    self.recommendations = dict["recommendations"] as? [String] ?? []

    // Enhanced features
    self.coachLine = dict["coachLine"] as? String
    self.protocolType = dict["protocolType"] as? String
    self.quickResetSteps = dict["quickResetSteps"] as? [String]
    self.processItSteps = dict["processItSteps"] as? [String]
    self.reframeChips = dict["reframeChips"] as? [String]
    self.microInsight = dict["microInsight"] as? String
    self.ifThenPlan = dict["ifThenPlan"] as? String
  }
}
