import Foundation

// MARK: - Dictionary Extensions for Tolerant Parsing
extension Dictionary where Key == String, Value == Any {
  func val<T>(_ keys: [String]) -> T? {
    for k in keys { if let v = self[k] as? T { return v } }
    return nil
  }
  var maybeData: [String: Any] {
    (self["data"] as? [String: Any]) ?? self
  }
}

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
  let reason: String?
  let suggestedPath: String?

  // Enhanced coach features
  let coachLine: String?
  let protocolType: String?
  let quickResetSteps: [String]?
  let processItSteps: [String]?
  let reframeChips: [String]?
  let microInsight: String?
  let ifThenPlan: String?

  init(from dictRaw: [String: Any]) {
    let dict = dictRaw.maybeData
    print("🔍 DailyCheckInResponse init - dict: \(dict)")

    self.severity = dict.val(["severity", "level", "severityLevel"]) ?? 1
    self.exercise = dict.val(["exercise", "title"]) ?? "Quick Calm Down Breath"
    self.resources = dict.val(["resources"])
    self.message = dict.val(["message", "note"]) ?? "Thank you for checking in"
    self.recommendations = dict.val(["recommendations", "suggestions"]) ?? []
    self.reason = dict.val(["reason", "why"])
    self.suggestedPath = dict.val(["suggested_path", "suggestedPath"])

    // Enhanced features
    self.coachLine = dict.val(["coachLine", "coach_line", "coach"])
    self.protocolType = dict.val(["protocolType", "protocol_type", "protocol"])
    self.quickResetSteps = dict.val(["quickResetSteps", "quick_reset_steps", "resetSteps"])
    self.processItSteps = dict.val(["processItSteps", "process_it_steps", "processSteps"])
    self.reframeChips = dict.val(["reframeChips", "reframe_chips", "reframes"])
    self.microInsight = dict.val(["microInsight", "insight"])
    self.ifThenPlan = dict.val(["ifThenPlan", "if_then_plan"])

    print(
      "🔍 Parsed response - coachLine: \(self.coachLine ?? "nil"), quickResetSteps: \(self.quickResetSteps?.count ?? 0), reason: \(self.reason ?? "nil")"
    )
  }
}
