import Foundation

// MARK: - Step Types

enum StepType: String, Codable, CaseIterable, Identifiable {
  case breathing = "breathing"
  case grounding = "grounding"
  case muscleRelease = "muscle_release"
  case affirmation = "affirmation"
  case mindfulness = "mindfulness"
  case cognitiveReframing = "cognitive_reframing"
  case custom = "custom"

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .breathing: return "Breathing"
    case .grounding: return "Grounding"
    case .muscleRelease: return "Muscle Release"
    case .affirmation: return "Affirmation"
    case .mindfulness: return "Mindfulness"
    case .cognitiveReframing: return "Cognitive Reframing"
    case .custom: return "Custom"
    }
  }

  var icon: String {
    switch self {
    case .breathing: return "lungs"
    case .grounding: return "hand.raised"
    case .muscleRelease: return "figure.strengthtraining.traditional"
    case .affirmation: return "quote.bubble"
    case .mindfulness: return "brain.head.profile"
    case .cognitiveReframing: return "lightbulb"
    case .custom: return "square.and.pencil"
    }
  }
}

// MARK: - Plan Step Model

struct PlanStep: Identifiable, Codable, Hashable {
  var id = UUID()
  var type: StepType
  var text: String
  var seconds: Int?  // optional per step

  init(type: StepType, text: String, seconds: Int? = nil) {
    self.type = type
    self.text = text
    self.seconds = seconds
  }
}

// MARK: - Step Library

struct StepLibrary {
  static let breathing: [PlanStep] = [
    .init(
      type: .breathing,
      text: "Box breathing: in 4 seconds • hold 4 seconds • out 4 seconds • hold 4 seconds",
      seconds: 60),
    .init(type: .breathing, text: "Paced breathing: in 4 seconds • out 6 seconds", seconds: 60),
    .init(
      type: .breathing, text: "4-7-8 breathing: in 4 seconds • hold 7 seconds • out 8 seconds",
      seconds: 60),
    .init(
      type: .breathing, text: "Diaphragmatic breathing: breathe deeply into your belly", seconds: 60
    ),
    .init(
      type: .breathing, text: "Heart coherence breathing: breathe at a comfortable pace",
      seconds: 60),
  ]

  static let grounding: [PlanStep] = [
    .init(
      type: .grounding,
      text:
        "5-4-3-2-1 grounding: 5 things you see, 4 you can touch, 3 you hear, 2 you smell, 1 you taste",
      seconds: 60),
    .init(type: .grounding, text: "Count backwards slowly from 30", seconds: 30),
    .init(
      type: .grounding, text: "Temperature shift: hold a cool object and describe its feel",
      seconds: 30),
    .init(type: .grounding, text: "Sensory awareness: focus on one sound around you", seconds: 20),
    .init(type: .grounding, text: "Touch grounding: feel your feet on the floor", seconds: 20),
  ]

  static let muscle: [PlanStep] = [
    .init(type: .muscleRelease, text: "Tense and release shoulders 3 times", seconds: 30),
    .init(type: .muscleRelease, text: "Unclench jaw and drop tongue from palate", seconds: 20),
    .init(
      type: .muscleRelease, text: "Progressive muscle relaxation: tense and release hands",
      seconds: 30),
    .init(type: .muscleRelease, text: "Release neck tension with gentle head rolls", seconds: 20),
    .init(type: .muscleRelease, text: "Shoulder blade squeeze and release", seconds: 25),
  ]

  static let affirmation: [PlanStep] = [
    .init(type: .affirmation, text: "Repeat: 'This is uncomfortable, not dangerous.'", seconds: 20),
    .init(type: .affirmation, text: "Repeat: 'I am safe. This will pass.'", seconds: 20),
    .init(type: .affirmation, text: "Repeat: 'I can handle this moment.'", seconds: 20),
    .init(type: .affirmation, text: "Repeat: 'I am in control of my breathing.'", seconds: 20),
    .init(type: .affirmation, text: "Repeat: 'This feeling is temporary.'", seconds: 20),
  ]

  static let mindfulness: [PlanStep] = [
    .init(type: .mindfulness, text: "Notice one sound; describe it in 3 words", seconds: 20),
    .init(type: .mindfulness, text: "Feel feet on the floor; describe the pressure", seconds: 20),
    .init(
      type: .mindfulness, text: "Mindful body scan: notice your feet touching the ground",
      seconds: 30),
    .init(
      type: .mindfulness, text: "Present moment awareness: name 3 things you can see", seconds: 20),
    .init(
      type: .mindfulness, text: "Acceptance: 'This is how I feel right now, and that's okay'",
      seconds: 25),
  ]

  static let cognitive: [PlanStep] = [
    .init(
      type: .cognitiveReframing,
      text: "Reality check: 'What evidence do I have that I'm in danger?'", seconds: 30),
    .init(
      type: .cognitiveReframing, text: "Thought challenge: 'Is this thought helpful or harmful?'",
      seconds: 25),
    .init(
      type: .cognitiveReframing,
      text: "Perspective shift: 'How would I help a friend in this situation?'", seconds: 30),
    .init(
      type: .cognitiveReframing,
      text: "Evidence gathering: 'What has helped me through this before?'", seconds: 25),
  ]

  static var categories: [(title: String, steps: [PlanStep])] {
    [
      ("Breathing", breathing),
      ("Grounding", grounding),
      ("Muscle Release", muscle),
      ("Affirmations", affirmation),
      ("Mindfulness", mindfulness),
      ("Cognitive Reframing", cognitive),
    ]
  }

  static var allSteps: [PlanStep] {
    categories.flatMap { $0.steps }
  }
}
