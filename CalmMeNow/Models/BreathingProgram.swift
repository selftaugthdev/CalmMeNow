import Foundation

struct BreathingProgram: Codable, Identifiable {
  var id: UUID = UUID()
  var name: String
  var emoji: String
  var description: String
  var inhale: Double
  var holdAfterInhale: Double
  var exhale: Double
  var holdAfterExhale: Double
  var duration: Int
  var category: Category
  var style: AnimationStyle
  var isFree: Bool
  var isBuiltIn: Bool

  enum Category: String, Codable, CaseIterable {
    case stress, panic, anxiety, sleep, advanced
  }

  enum AnimationStyle: String, Codable {
    case orb
    case physiologicalSigh
    case box
  }

  var cycleDuration: Double {
    inhale + holdAfterInhale + exhale + holdAfterExhale
  }

  // "4 · 4 · 4 · 4" — each segment formatted without trailing .0
  var ratioLabel: String {
    [inhale, holdAfterInhale, exhale, holdAfterExhale].map { v in
      v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(v)
    }.joined(separator: " · ")
  }

  // "2 min" / "90 sec"
  var durationLabel: String {
    duration >= 60 ? "\(duration / 60) min" : "\(duration) sec"
  }
}
