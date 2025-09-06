import Foundation

/// Model for AI-generated exercises (breathing or non-breathing)
struct Exercise: Identifiable, Codable {
  let id: UUID
  let title: String
  let duration: Int  // in seconds
  let steps: [String]
  let prompt: String?

  /// Determine if this is a breathing exercise based on content
  var isBreathingExercise: Bool {
    let content = "\(title) \(steps.joined(separator: " "))".lowercased()
    return content.contains("breath") || content.contains("inhale") || content.contains("exhale")
      || content.contains("breathing") || content.contains("physiological")
      || content.contains("box breathing") || content.contains("coherence")
  }

  /// Convert to breathing plan if this is a breathing exercise
  var breathingPlan: BreathingPlan? {
    guard isBreathingExercise else { return nil }

    let content = "\(title) \(steps.joined(separator: " "))".lowercased()

    // Parse specific breathing patterns from the content
    if content.contains("box") || content.contains("4-4-4-4") {
      return .boxBreathing
    } else if content.contains("physiological") || content.contains("sigh") {
      return .physiologicalSigh
    } else if content.contains("coherence") || content.contains("5-5") {
      return .coherenceBreathing
    } else {
      // Create custom plan based on duration
      let totalDuration = max(60, Double(duration))
      return BreathingPlan(
        inhale: 4,
        hold: 4,
        exhale: 6,
        pause: 2,
        total: totalDuration
      )
    }
  }

  /// Create from AI response dictionary
  static func fromAIResponse(_ data: [String: Any]) -> Exercise? {
    guard let title = data["title"] as? String else { return nil }

    let duration = data["duration_sec"] as? Int ?? 60
    let steps = data["steps"] as? [String] ?? []
    let prompt = data["prompt"] as? String

    return Exercise(
      id: UUID(),
      title: title,
      duration: duration,
      steps: steps,
      prompt: prompt
    )
  }
}
