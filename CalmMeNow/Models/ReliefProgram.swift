import Foundation
import SwiftUI

// MARK: - Supporting Types

enum Emotion: String, CaseIterable, Identifiable {
  case anxious, angry, sad, frustrated
  var id: String { rawValue }
}

enum IntensityLevel {
  case mild
  case severe
}

enum BreathingPattern {
  case fiveFive  // inhale 5, exhale 5
  case fourSix  // inhale 4, exhale 6
  case box  // 4-4-4-4
  case physiologicalSigh
  case none
}

enum GuidanceType {
  case grounding54321
  case handOverHeart
  case jawRelease
  case smallAction
  case none
}

enum Theme {
  case pastel
  case dimmed
}

struct ReliefProgram {
  let emotion: Emotion
  let intensity: IntensityLevel
  let audio: String  // filename or asset ID
  let breathing: BreathingPattern
  let guidance: GuidanceType
  let showControlsAfter: TimeInterval
  let duration: TimeInterval
  let theme: Theme
  let headerText: String
  let subtext: String
  let voiceOverEnabled: Bool
  let hapticsEnabled: Bool
}

// MARK: - Relief Programs for Each Emotion × Intensity

extension ReliefProgram {
  static let programs: [ReliefProgram] = [

    // 😰 ANXIOUS
    ReliefProgram(
      emotion: .anxious,
      intensity: .mild,
      audio: "mixkit-serene-anxious",
      breathing: .fiveFive,
      guidance: .none,
      showControlsAfter: 0,
      duration: 60,
      theme: .pastel,
      headerText: "A little anxious",
      subtext: "One minute. Breathe with the circle or just close your eyes and listen.",
      voiceOverEnabled: false,
      hapticsEnabled: true
    ),
    ReliefProgram(
      emotion: .anxious,
      intensity: .severe,
      audio: "mixkit-serene-anxious",  // Will loop for 2 minutes
      breathing: .fourSix,
      guidance: .grounding54321,
      showControlsAfter: 15,
      duration: 120,
      theme: .pastel,
      headerText: "You're safe. Breathe with me.",
      subtext: "Focus on your breath. This will pass.",
      voiceOverEnabled: true,
      hapticsEnabled: true
    ),

    // 😡 ANGRY
    ReliefProgram(
      emotion: .angry,
      intensity: .mild,
      audio: "mixkit-just-chill-angry",
      breathing: .box,
      guidance: .none,
      showControlsAfter: 0,
      duration: 60,
      theme: .pastel,
      headerText: "A little annoyed",
      subtext: "Feel the tension release with each breath.",
      voiceOverEnabled: false,
      hapticsEnabled: true
    ),
    ReliefProgram(
      emotion: .angry,
      intensity: .severe,
      audio: "mixkit-just-chill-angry",  // Will loop for 2 minutes
      breathing: .physiologicalSigh,
      guidance: .jawRelease,
      showControlsAfter: 15,
      duration: 120,
      theme: .pastel,
      headerText: "Let the anger flow through you.",
      subtext: "Don't hold onto it. Breathe it out.",
      voiceOverEnabled: true,
      hapticsEnabled: true
    ),

    // 😢 SAD
    ReliefProgram(
      emotion: .sad,
      intensity: .mild,
      audio: "mixkit-jazz-sad",
      breathing: .fiveFive,
      guidance: .none,
      showControlsAfter: 0,
      duration: 60,
      theme: .pastel,
      headerText: "A bit down",
      subtext: "It's okay to feel this way. You're not alone.",
      voiceOverEnabled: false,
      hapticsEnabled: true
    ),
    ReliefProgram(
      emotion: .sad,
      intensity: .severe,
      audio: "mixkit-jazz-sad",  // Will loop for 2 minutes
      breathing: .fiveFive,
      guidance: .handOverHeart,
      showControlsAfter: 15,
      duration: 120,
      theme: .pastel,
      headerText: "Your feelings are valid.",
      subtext: "Let them be without judgment. You're safe.",
      voiceOverEnabled: true,
      hapticsEnabled: true
    ),

    // 😖 FRUSTRATED
    ReliefProgram(
      emotion: .frustrated,
      intensity: .mild,
      audio: "ethereal-night-loop",
      breathing: .fiveFive,
      guidance: .none,
      showControlsAfter: 0,
      duration: 60,
      theme: .pastel,
      headerText: "Slightly frustrated",
      subtext: "Step back and find your center.",
      voiceOverEnabled: false,
      hapticsEnabled: true
    ),
    ReliefProgram(
      emotion: .frustrated,
      intensity: .severe,
      audio: "ethereal-night-loop",  // Will loop for 2 minutes
      breathing: .fourSix,
      guidance: .smallAction,
      showControlsAfter: 15,
      duration: 120,
      theme: .pastel,
      headerText: "This moment is temporary.",
      subtext: "Find your inner strength. One breath at a time.",
      voiceOverEnabled: true,
      hapticsEnabled: true
    ),
  ]

  // MARK: - Lookup Function

  static func program(for emotion: Emotion, intensity: IntensityLevel) -> ReliefProgram? {
    programs.first { $0.emotion == emotion && $0.intensity == intensity }
  }

  // MARK: - Helper Functions

  func getBreathingInstructions() -> [String] {
    switch breathing {
    case .fiveFive:
      return ["Breathe in...", "Hold...", "Breathe out..."]
    case .fourSix:
      return ["Inhale gently...", "Hold...", "Longer exhale..."]
    case .box:
      return ["Inhale...", "Hold...", "Exhale...", "Hold..."]
    case .physiologicalSigh:
      return ["Two short inhales...", "Long exhale...", "Rest..."]
    case .none:
      return []
    }
  }

  func getGuidanceInstructions() -> [String] {
    switch guidance {
    case .grounding54321:
      return [
        "See 5 things around you",
        "Feel 4 things you can touch",
        "Hear 3 sounds",
        "Smell 2 things",
        "Taste 1 thing",
      ]
    case .handOverHeart:
      return [
        "Place your hand over your heart",
        "Feel the warmth and comfort",
        "You are safe and loved",
      ]
    case .jawRelease:
      return [
        "Drop your jaw slightly",
        "Let your tongue rest",
        "Release the tension",
      ]
    case .smallAction:
      return [
        "Pick one tiny action",
        "Something you can do right now",
        "Just one small step",
      ]
    case .none:
      return []
    }
  }

  func getVoiceOverLines() -> [String] {
    switch emotion {
    case .anxious:
      return intensity == .severe
        ? [
          "Inhale gently... Now longer exhale.",
          "You're doing enough.",
          "Let the body settle.",
        ] : []
    case .angry:
      return intensity == .severe
        ? [
          "Let the anger flow through you.",
          "Don't hold onto it.",
          "Breathe it out.",
        ] : []
    case .sad:
      return intensity == .severe
        ? [
          "Your feelings are valid.",
          "Let them be without judgment.",
          "You're safe and loved.",
        ] : []
    case .frustrated:
      return intensity == .severe
        ? [
          "This moment is temporary.",
          "Find your inner strength.",
          "One breath at a time.",
        ] : []
    }
  }
}
