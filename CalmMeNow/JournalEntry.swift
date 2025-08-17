import Foundation
import SwiftData

@Model
class JournalEntry {
  var id: UUID
  var content: String
  var timestamp: Date
  var emotion: String?
  var intensity: String?
  var isLocked: Bool
  
  init(content: String, emotion: String? = nil, intensity: String? = nil) {
    self.id = UUID()
    self.content = content
    self.timestamp = Date()
    self.emotion = emotion
    self.intensity = intensity
    self.isLocked = false
  }
}
