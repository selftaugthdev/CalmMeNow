import Foundation

struct PanicPlan: Codable, Identifiable, Hashable {
  let id: UUID
  var title: String
  var description: String
  var steps: [String]
  var duration: Int
  var techniques: [String]
  var emergencyContact: String?
  var personalizedPhrase: String?
  let createdAt: Date

  init(from dict: [String: Any]) {
    self.id = UUID()
    self.title = dict["title"] as? String ?? "Personalized Calm Plan"
    self.description =
      dict["description"] as? String ?? "Your customized plan for managing overwhelming moments"
    self.steps =
      dict["steps"] as? [String] ?? [
        "Take deep breaths", "Ground yourself", "Use your calming phrase",
      ]
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
    steps: [String],
    duration: Int,
    techniques: [String],
    emergencyContact: String? = nil,
    personalizedPhrase: String? = nil,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.steps = steps
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

  init(from dict: [String: Any]) {
    self.severity = dict["severity"] as? Int ?? 1
    self.exercise = dict["exercise"] as? String
    self.resources = dict["resources"] as? [String]
    self.message = dict["message"] as? String ?? "Thank you for checking in"
    self.recommendations = dict["recommendations"] as? [String] ?? []
  }
}
