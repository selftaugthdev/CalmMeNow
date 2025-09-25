import Foundation

// MARK: - Protocol Types
enum ProtocolType: String, CaseIterable, Codable {
  case quickBreath = "quickBreath"
  case pmr = "pmr"
  case grounding = "grounding"
  case behavioral = "behavioral"
  case reframe = "reframe"
  case compassion = "compassion"

  var displayName: String {
    switch self {
    case .quickBreath: return "Quick Reset"
    case .pmr: return "Progressive Muscle Relaxation"
    case .grounding: return "Grounding"
    case .behavioral: return "Behavioral Activation"
    case .reframe: return "Cognitive Reframe"
    case .compassion: return "Self-Compassion"
    }
  }

  var duration: String {
    switch self {
    case .quickBreath: return "60-90s"
    case .pmr: return "2-3 min"
    case .grounding: return "90s"
    case .behavioral: return "2-3 min"
    case .reframe: return "2-3 min"
    case .compassion: return "90s"
    }
  }
}

// MARK: - Check-in Input
struct CheckInInput {
  let mood: Int  // 1-10
  let tags: [String]
  let note: String

  var hasAngerTriggers: Bool {
    let text = note.lowercased()
    return text.contains("cut me off") || text.contains("traffic") || text.contains("driver")
      || text.contains("angry") || text.contains("frustrated") || text.contains("rage")
  }

  var hasOverwhelmTriggers: Bool {
    return tags.contains("overwhelmed") || tags.contains("work-stress")
      || note.lowercased().contains("overwhelmed")
  }

  var hasAnxietyTriggers: Bool {
    return tags.contains("social-anxiety") || tags.contains("anxious")
      || note.lowercased().contains("anxious") || note.lowercased().contains("worried")
  }

  var hasFatigueTriggers: Bool {
    return tags.contains("tired") || tags.contains("low-energy") || tags.contains("poor-sleep")
      || note.lowercased().contains("tired") || note.lowercased().contains("exhausted")
  }
}

// MARK: - Coach Line Generator
struct CoachLineGenerator {
  static func generateCoachLine(for protocolType: ProtocolType, input: CheckInInput) -> String {
    switch protocolType {
    case .quickBreath:
      if input.hasAngerTriggers {
        return
          "That was frustrating. Let's settle your body first, then we'll decide what's worth your energy."
      } else if input.hasOverwhelmTriggers {
        return "I hear the overwhelm. Let's calm your nervous system—60 seconds to reset."
      } else {
        return "That spike is real. Let's settle your body first—60 seconds."
      }

    case .grounding:
      if input.hasAnxietyTriggers {
        return "Being anxious can spike anyone's stress. Quick grounding to bring you back to now."
      } else {
        return "Let's bring your attention back to now—quick grounding."
      }

    case .behavioral:
      if input.hasFatigueTriggers {
        return "Low energy is tough. Tiny action can lift your mood—pick one small step."
      } else {
        return "Tiny action can lift energy—pick one small step."
      }

    case .pmr:
      return "Tension gathers in muscles—let's release shoulders and jaw."

    case .reframe:
      if input.hasAngerTriggers {
        return "Let's look at this from a steadier angle—choose a reframe that helps."
      } else {
        return "Let's look at this from a steadier angle—choose a reframe."
      }

    case .compassion:
      return "This is hard. Give yourself a brief compassion break."
    }
  }
}

// MARK: - Reframe Chips
struct ReframeChip: Identifiable, Codable {
  let id = UUID()
  let text: String
  let category: String

  static let angerReframes = [
    ReframeChip(text: "I'm safe now.", category: "safety"),
    ReframeChip(text: "This isn't worth renting space in my head.", category: "perspective"),
    ReframeChip(text: "I'll use this to practice calm focus.", category: "growth"),
    ReframeChip(text: "They're having a bad day too.", category: "empathy"),
    ReframeChip(text: "I'll focus on arriving calm.", category: "control"),
  ]

  static let overwhelmReframes = [
    ReframeChip(text: "I can handle one thing at a time.", category: "control"),
    ReframeChip(text: "This feeling will pass.", category: "temporary"),
    ReframeChip(text: "I'm doing my best right now.", category: "self-compassion"),
    ReframeChip(text: "Progress, not perfection.", category: "realistic"),
    ReframeChip(text: "I'll tackle the most important thing first.", category: "prioritization"),
  ]

  static let anxietyReframes = [
    ReframeChip(text: "I'm safe in this moment.", category: "safety"),
    ReframeChip(text: "This is just my brain trying to protect me.", category: "understanding"),
    ReframeChip(text: "I've handled difficult situations before.", category: "strength"),
    ReframeChip(text: "I can take this one step at a time.", category: "control"),
    ReframeChip(text: "This feeling is temporary.", category: "temporary"),
  ]

  static func getReframes(for protocolType: ProtocolType, input: CheckInInput) -> [ReframeChip] {
    switch protocolType {
    case .reframe:
      if input.hasAngerTriggers {
        return angerReframes
      } else if input.hasOverwhelmTriggers {
        return overwhelmReframes
      } else if input.hasAnxietyTriggers {
        return anxietyReframes
      } else {
        return angerReframes  // Default
      }
    default:
      return []
    }
  }
}

// MARK: - Protocol Detection
struct ProtocolDetector {
  static func detectProtocol(for input: CheckInInput) -> ProtocolType {
    // High priority: anger/irritation triggers
    if input.hasAngerTriggers {
      return .quickBreath
    }

    // Overwhelm + work stress
    if input.hasOverwhelmTriggers {
      return .quickBreath
    }

    // Low mood + fatigue
    if input.hasFatigueTriggers {
      return .behavioral
    }

    // Anxiety + rumination
    if input.hasAnxietyTriggers {
      return .grounding
    }

    // Default based on mood
    return input.mood <= 3 ? .behavioral : .quickBreath
  }
}

// MARK: - Exercise Steps
struct ExerciseStep: Identifiable, Codable {
  let id = UUID()
  let title: String
  let instruction: String
  let duration: Int  // seconds
  let isBreathing: Bool

  static func getSteps(for protocolType: ProtocolType) -> [ExerciseStep] {
    switch protocolType {
    case .quickBreath:
      return [
        ExerciseStep(
          title: "Sit comfortably",
          instruction: "Find a comfortable seated position with your feet flat on the floor",
          duration: 10, isBreathing: false),
        ExerciseStep(
          title: "Soften your gaze",
          instruction: "Lower your eyelids or focus on a spot on the floor", duration: 5,
          isBreathing: false),
        ExerciseStep(
          title: "Inhale 4 seconds",
          instruction: "Breathe in slowly through your nose for 4 seconds", duration: 4,
          isBreathing: true),
        ExerciseStep(
          title: "Hold 4 seconds", instruction: "Hold your breath gently for 4 seconds",
          duration: 4, isBreathing: true),
        ExerciseStep(
          title: "Exhale 6 seconds",
          instruction: "Breathe out slowly through your mouth for 6 seconds", duration: 6,
          isBreathing: true),
        ExerciseStep(
          title: "Repeat 3 rounds", instruction: "Complete 3 full breathing cycles", duration: 60,
          isBreathing: true),
      ]

    case .grounding:
      return [
        ExerciseStep(
          title: "Find your feet", instruction: "Feel your feet on the ground, notice the pressure",
          duration: 15, isBreathing: false),
        ExerciseStep(
          title: "Name 5 things you see", instruction: "Look around and name 5 things you can see",
          duration: 20, isBreathing: false),
        ExerciseStep(
          title: "Name 4 things you hear", instruction: "Listen and name 4 sounds around you",
          duration: 20, isBreathing: false),
        ExerciseStep(
          title: "Name 3 things you feel", instruction: "Notice 3 things you can touch or feel",
          duration: 20, isBreathing: false),
        ExerciseStep(
          title: "Take a deep breath", instruction: "Breathe in slowly and notice how you feel now",
          duration: 15, isBreathing: true),
      ]

    case .behavioral:
      return [
        ExerciseStep(
          title: "Stand up", instruction: "Get up from your current position", duration: 5,
          isBreathing: false),
        ExerciseStep(
          title: "Stretch your arms", instruction: "Reach your arms up and stretch gently",
          duration: 10, isBreathing: false),
        ExerciseStep(
          title: "Get some light", instruction: "Move to a well-lit area or open curtains",
          duration: 10, isBreathing: false),
        ExerciseStep(
          title: "Drink water", instruction: "Take a few sips of water", duration: 15,
          isBreathing: false),
        ExerciseStep(
          title: "Pick one small task", instruction: "Choose one tiny thing you can do right now",
          duration: 30, isBreathing: false),
      ]

    case .pmr:
      return [
        ExerciseStep(
          title: "Sit comfortably", instruction: "Find a comfortable seated position", duration: 10,
          isBreathing: false),
        ExerciseStep(
          title: "Tense shoulders", instruction: "Raise your shoulders up to your ears and hold",
          duration: 5, isBreathing: false),
        ExerciseStep(
          title: "Release shoulders", instruction: "Let your shoulders drop and relax completely",
          duration: 10, isBreathing: false),
        ExerciseStep(
          title: "Tense jaw", instruction: "Clench your jaw gently and hold", duration: 5,
          isBreathing: false),
        ExerciseStep(
          title: "Release jaw", instruction: "Let your jaw relax and drop slightly", duration: 10,
          isBreathing: false),
        ExerciseStep(
          title: "Breathe deeply", instruction: "Take 3 slow, deep breaths", duration: 30,
          isBreathing: true),
      ]

    case .compassion:
      return [
        ExerciseStep(
          title: "Place hand on heart", instruction: "Gently place your hand over your heart",
          duration: 10, isBreathing: false),
        ExerciseStep(
          title: "Acknowledge difficulty",
          instruction: "Say to yourself: 'This is a moment of suffering'", duration: 15,
          isBreathing: false),
        ExerciseStep(
          title: "Recognize common humanity",
          instruction: "Say: 'Suffering is part of being human'", duration: 15, isBreathing: false),
        ExerciseStep(
          title: "Offer kindness", instruction: "Say: 'May I be kind to myself in this moment'",
          duration: 15, isBreathing: false),
        ExerciseStep(
          title: "Breathe with compassion",
          instruction: "Take 3 breaths while feeling self-compassion", duration: 30,
          isBreathing: true),
      ]

    case .reframe:
      return [
        ExerciseStep(
          title: "Name the feeling",
          instruction: "What's the main emotion you're feeling right now?", duration: 20,
          isBreathing: false),
        ExerciseStep(
          title: "Choose a reframe", instruction: "Select a helpful perspective from the options",
          duration: 30, isBreathing: false),
        ExerciseStep(
          title: "Take action", instruction: "Pick one small step you can take right now",
          duration: 30, isBreathing: false),
      ]
    }
  }
}
