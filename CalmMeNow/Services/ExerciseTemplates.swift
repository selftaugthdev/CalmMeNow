//
//  ExerciseTemplates.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import Foundation

// MARK: - Exercise Template Models
struct ExerciseTemplate {
  let id: String
  let title: String
  let steps: [String]
  let duration: Int
  let category: ExerciseCategory
  let parameters: [String: Any]
}

enum ExerciseCategory: String, CaseIterable {
  case breathing = "breathing"
  case grounding = "grounding"
  case stretch = "stretch"
  case mindfulness = "mindfulness"
  case emergency = "emergency"
}

// MARK: - Exercise Template Manager
class ExerciseTemplateManager {
  static let shared = ExerciseTemplateManager()

  private let templates: [String: ExerciseTemplate]

  private init() {
    self.templates = Self.loadTemplates()
  }

  // MARK: - Template Access

  func getTemplate(id: String) -> ExerciseTemplate? {
    return templates[id]
  }

  func getTemplates(for category: ExerciseCategory) -> [ExerciseTemplate] {
    return templates.values.filter { $0.category == category }
  }

  func getRandomTemplate(for category: ExerciseCategory) -> ExerciseTemplate? {
    let categoryTemplates = getTemplates(for: category)
    return categoryTemplates.randomElement()
  }

  // MARK: - Template Selection Logic

  func selectTemplate(for moodBucket: String, intensity: Int, tags: [String]) -> ExerciseTemplate? {
    let category = determineCategory(moodBucket: moodBucket, intensity: intensity, tags: tags)
    return getRandomTemplate(for: category)
  }

  private func determineCategory(moodBucket: String, intensity: Int, tags: [String])
    -> ExerciseCategory
  {
    // High intensity or emergency tags -> emergency
    if intensity >= 8 || tags.contains("panic") || tags.contains("crisis") {
      return .emergency
    }

    // Anxiety-related tags -> breathing or grounding
    if tags.contains("anxious") || tags.contains("worried") || moodBucket == "high" {
      return intensity >= 6 ? .breathing : .grounding
    }

    // Sleep-related -> mindfulness
    if tags.contains("sleep") || tags.contains("tired") {
      return .mindfulness
    }

    // Physical tension -> stretch
    if tags.contains("tense") || tags.contains("muscle") {
      return .stretch
    }

    // Default based on intensity
    switch intensity {
    case 1...3: return .mindfulness
    case 4...6: return .breathing
    case 7...10: return .grounding
    default: return .breathing
    }
  }

  // MARK: - Template Loading

  private static func loadTemplates() -> [String: ExerciseTemplate] {
    var templates: [String: ExerciseTemplate] = [:]

    // Breathing Exercises
    templates["breath_4_2_6"] = ExerciseTemplate(
      id: "breath_4_2_6",
      title: "4-2-6 Breathing",
      steps: [
        "Sit comfortably with your back straight",
        "Inhale slowly through your nose for 4 counts",
        "Hold your breath for 2 counts",
        "Exhale slowly through your mouth for 6 counts",
        "Repeat this cycle 5-10 times",
      ],
      duration: 300,
      category: .breathing,
      parameters: ["inhale": 4, "hold": 2, "exhale": 6]
    )

    templates["breath_box"] = ExerciseTemplate(
      id: "breath_box",
      title: "Box Breathing",
      steps: [
        "Sit in a comfortable position",
        "Inhale for 4 counts",
        "Hold for 4 counts",
        "Exhale for 4 counts",
        "Hold empty for 4 counts",
        "Repeat the box pattern 8-10 times",
      ],
      duration: 320,
      category: .breathing,
      parameters: ["inhale": 4, "hold": 4, "exhale": 4, "pause": 4]
    )

    // Grounding Exercises
    templates["grounding_54321"] = ExerciseTemplate(
      id: "grounding_54321",
      title: "5-4-3-2-1 Grounding",
      steps: [
        "Name 5 things you can see around you",
        "Name 4 things you can touch",
        "Name 3 things you can hear",
        "Name 2 things you can smell",
        "Name 1 thing you can taste",
      ],
      duration: 180,
      category: .grounding,
      parameters: [:]
    )

    templates["grounding_body_scan"] = ExerciseTemplate(
      id: "grounding_body_scan",
      title: "Body Scan Grounding",
      steps: [
        "Start at the top of your head",
        "Notice any tension in your forehead",
        "Move down to your jaw and relax it",
        "Continue down through your shoulders",
        "Feel your chest rise and fall with breath",
        "Notice your stomach and lower body",
        "End by wiggling your toes",
      ],
      duration: 240,
      category: .grounding,
      parameters: [:]
    )

    // Stretch Exercises
    templates["stretch_neck"] = ExerciseTemplate(
      id: "stretch_neck",
      title: "Neck and Shoulder Release",
      steps: [
        "Sit or stand comfortably",
        "Slowly tilt your head to the right",
        "Hold for 15 seconds, feeling the stretch",
        "Return to center and tilt left",
        "Hold for 15 seconds",
        "Roll your shoulders backward 5 times",
        "Roll your shoulders forward 5 times",
      ],
      duration: 120,
      category: .stretch,
      parameters: [:]
    )

    // Mindfulness Exercises
    templates["mindfulness_breath"] = ExerciseTemplate(
      id: "mindfulness_breath",
      title: "Mindful Breathing",
      steps: [
        "Find a comfortable seated position",
        "Close your eyes or soften your gaze",
        "Focus on your natural breathing rhythm",
        "When your mind wanders, gently return to breath",
        "Continue for 2-3 minutes",
        "Slowly open your eyes when ready",
      ],
      duration: 180,
      category: .mindfulness,
      parameters: [:]
    )

    // Emergency Exercises
    templates["emergency_ice"] = ExerciseTemplate(
      id: "emergency_ice",
      title: "Ice Cube Technique",
      steps: [
        "Hold an ice cube in your hand",
        "Focus on the cold sensation",
        "Notice how it feels on your skin",
        "Breathe slowly and deeply",
        "Continue until you feel calmer",
        "If no ice, use cold water on wrists",
      ],
      duration: 120,
      category: .emergency,
      parameters: [:]
    )

    templates["emergency_urge_surfing"] = ExerciseTemplate(
      id: "emergency_urge_surfing",
      title: "Urge Surfing",
      steps: [
        "Notice the urge or feeling without fighting it",
        "Imagine it as a wave in the ocean",
        "Watch it rise and peak",
        "Notice it will naturally fall",
        "Ride the wave without being overwhelmed",
        "Breathe through the entire process",
      ],
      duration: 180,
      category: .emergency,
      parameters: [:]
    )

    return templates
  }
}

// MARK: - Template Response Models
struct TemplateResponse: Codable {
  let exerciseId: String
  let parameters: [String: AnyCodable]
  let note: String?

  struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
      self.value = value
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      if let intValue = try? container.decode(Int.self) {
        value = intValue
      } else if let stringValue = try? container.decode(String.self) {
        value = stringValue
      } else if let doubleValue = try? container.decode(Double.self) {
        value = doubleValue
      } else {
        throw DecodingError.typeMismatch(
          Any.self,
          DecodingError.Context(
            codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
      }
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      if let intValue = value as? Int {
        try container.encode(intValue)
      } else if let stringValue = value as? String {
        try container.encode(stringValue)
      } else if let doubleValue = value as? Double {
        try container.encode(doubleValue)
      } else {
        throw EncodingError.invalidValue(
          value,
          EncodingError.Context(
            codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
      }
    }
  }
}
