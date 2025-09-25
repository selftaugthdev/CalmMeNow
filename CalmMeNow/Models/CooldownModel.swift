import SwiftUI

struct CooldownModel {
  let id: String
  let emotion: String
  let emoji: String
  let soundFileName: String
  let backgroundColors: [Color]
  let hasBreathingOrb: Bool
  let optionalText: String?
  let animationType: AnimationType
  let intensity: String?

  enum AnimationType {
    case breathing
    case vibrating
    case pulsing
    case hugging
  }
}

// Predefined cooldown experiences
extension CooldownModel {
  static let cooldowns: [CooldownModel] = [
    CooldownModel(
      id: "anxious",
      emotion: "Anxious",
      emoji: "😰",
      soundFileName: "mixkit-serene-anxious",
      backgroundColors: [
        Color(hex: "#B5D8F6"),
        Color(hex: "#D7CFF5"),
      ],
      hasBreathingOrb: true,
      optionalText: "Take a moment to breathe. Let's find your calm together.",
      animationType: .breathing,
      intensity: nil
    ),
    CooldownModel(
      id: "angry",
      emotion: "Angry",
      emoji: "😠",
      soundFileName: "mixkit-just-chill-angry",
      backgroundColors: [
        Color(hex: "#FF6B6B"),
        Color(hex: "#4ECDC4"),
      ],
      hasBreathingOrb: false,
      optionalText: "Take deep breaths and feel the anger dissolve",
      animationType: .vibrating,
      intensity: nil
    ),
    CooldownModel(
      id: "sad",
      emotion: "Sad",
      emoji: "😢",
      soundFileName: "mixkit-jazz-sad",
      backgroundColors: [
        Color(red: 0.95, green: 0.90, blue: 0.98),
        Color(red: 0.98, green: 0.85, blue: 0.90),
        Color(red: 0.98, green: 0.95, blue: 0.90),
      ],
      hasBreathingOrb: false,
      optionalText: "It's okay to feel sad. Let's find comfort together.",
      animationType: .hugging,
      intensity: nil
    ),
    CooldownModel(
      id: "frustrated",
      emotion: "Frustrated",
      emoji: "😤",
      soundFileName: "ethereal-night-loop",
      backgroundColors: [
        Color(red: 0.85, green: 0.95, blue: 0.85),
        Color(red: 0.70, green: 0.90, blue: 0.90),
      ],
      hasBreathingOrb: false,
      optionalText: "Take a step back. Let's find clarity together.",
      animationType: .pulsing,
      intensity: nil
    ),
  ]
}
