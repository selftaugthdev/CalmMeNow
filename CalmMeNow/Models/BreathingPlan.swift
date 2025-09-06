import Foundation

/// Model for parameterized breathing exercises with safe math to prevent NaN issues
struct BreathingPlan {
  var inhale: Double
  var hold: Double
  var exhale: Double
  var pause: Double
  var total: Double

  /// Default 60-second breathing plan (4-4-6-2 pattern)
  static let default60s = Self(inhale: 4, hold: 4, exhale: 6, pause: 2, total: 60)

  /// Box breathing plan (4-4-4-4 pattern)
  static let boxBreathing = Self(inhale: 4, hold: 4, exhale: 4, pause: 4, total: 120)

  /// Physiological sigh plan (2+1-0-5-0 pattern)
  static let physiologicalSigh = Self(inhale: 3, hold: 0, exhale: 5, pause: 0, total: 60)

  /// Coherence breathing plan (5-0-5-0 pattern)
  static let coherenceBreathing = Self(inhale: 5, hold: 0, exhale: 5, pause: 0, total: 90)

  /// Safe cycle duration with NaN protection
  var cycleDuration: Double {
    let d = inhale + hold + exhale + pause
    return (d.isFinite && d > 0) ? d : 16.0  // Default to 16s if invalid
  }

  /// Safe number of cycles with NaN protection
  var cycles: Int {
    let c = total / cycleDuration
    return (c.isFinite && c > 0) ? Int(c.rounded(.down)) : 4  // Default to 4 cycles if invalid
  }

  /// Initialize with validation to prevent NaN issues
  init(inhale: Double, hold: Double, exhale: Double, pause: Double, total: Double) {
    // Ensure all values are finite and positive
    self.inhale = (inhale.isFinite && inhale > 0) ? inhale : 4.0
    self.hold = (hold.isFinite && hold >= 0) ? hold : 0.0
    self.exhale = (exhale.isFinite && exhale > 0) ? exhale : 6.0
    self.pause = (pause.isFinite && pause >= 0) ? pause : 2.0
    self.total = (total.isFinite && total > 0) ? total : 60.0
  }

  /// Create a plan from AI recommendation text
  static func fromRecommendation(_ text: String) -> BreathingPlan {
    // Look for common breathing patterns in the text
    let lowercased = text.lowercased()

    if lowercased.contains("box") || lowercased.contains("4-4-4-4") {
      return .boxBreathing
    } else if lowercased.contains("physiological") || lowercased.contains("sigh") {
      return .physiologicalSigh
    } else if lowercased.contains("coherence") || lowercased.contains("5-5") {
      return .coherenceBreathing
    } else {
      // Default to the recommended pattern from the screenshot
      return .default60s
    }
  }
}

/// Extension to convert to BreathingTechnique for existing UI
extension BreathingPlan {
  var technique: BreathingTechnique {
    if inhale == 4 && hold == 4 && exhale == 4 && pause == 4 {
      return .boxBreathing
    } else if hold == 0 && pause == 0 && exhale > inhale {
      return .physiologicalSigh
    } else if hold == 0 && pause == 0 && inhale == exhale {
      return .coherenceBreathing
    } else {
      return .physiologicalSigh  // Default fallback
    }
  }
}
