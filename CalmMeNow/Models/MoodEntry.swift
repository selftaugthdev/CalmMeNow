import Foundation
import SwiftData

@Model
class MoodEntry {
  var id: UUID
  var score: Int       // 1–10
  var tags: [String]
  var timestamp: Date

  init(score: Int, tags: [String] = []) {
    self.id = UUID()
    self.score = score
    self.tags = tags
    self.timestamp = Date()
  }
}
