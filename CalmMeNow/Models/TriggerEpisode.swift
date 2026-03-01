import Foundation
import SwiftData

@Model
class TriggerEpisode {
  var id: UUID
  var timestamp: Date
  var triggerKey: String    // "work", "social", "sleep", etc.
  var triggerLabel: String  // "Work stress"
  var triggerEmoji: String  // "💼"
  var note: String?
  var outcome: String       // "better_now" or "still_needed_help"

  init(
    triggerKey: String,
    triggerLabel: String,
    triggerEmoji: String,
    note: String? = nil,
    outcome: String
  ) {
    self.id = UUID()
    self.timestamp = Date()
    self.triggerKey = triggerKey
    self.triggerLabel = triggerLabel
    self.triggerEmoji = triggerEmoji
    self.note = note
    self.outcome = outcome
  }

  var isSuccess: Bool { outcome == "better_now" }

  var formattedTime: String {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .short
    return f.string(from: timestamp)
  }

  var hourOfDay: Int {
    Calendar.current.component(.hour, from: timestamp)
  }

  var timeOfDayLabel: String {
    switch hourOfDay {
    case 5..<12: return "Morning"
    case 12..<17: return "Afternoon"
    case 17..<21: return "Evening"
    default: return "Night"
    }
  }
}

// MARK: - Trigger Categories

extension TriggerEpisode {
  struct TriggerCategory {
    let key: String
    let label: String
    let emoji: String
  }

  static let categories: [TriggerCategory] = [
    TriggerCategory(key: "work",         label: "Work stress",        emoji: "💼"),
    TriggerCategory(key: "sleep",        label: "Poor sleep",         emoji: "😴"),
    TriggerCategory(key: "social",       label: "Social anxiety",     emoji: "👥"),
    TriggerCategory(key: "health",       label: "Health worry",       emoji: "🩺"),
    TriggerCategory(key: "money",        label: "Financial stress",   emoji: "💸"),
    TriggerCategory(key: "body",         label: "Physical sensation", emoji: "💓"),
    TriggerCategory(key: "crowd",        label: "Crowded place",      emoji: "🏙️"),
    TriggerCategory(key: "relationship", label: "Relationship",       emoji: "💔"),
    TriggerCategory(key: "news",         label: "News / media",       emoji: "📱"),
    TriggerCategory(key: "unknown",      label: "Not sure",           emoji: "❓"),
  ]
}
