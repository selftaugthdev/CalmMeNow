import Foundation

struct ThoughtRecord: Identifiable, Codable {
  var id: UUID = UUID()
  var date: Date = Date()

  var situation: String = ""
  var automaticThought: String = ""
  var emotion: String = ""
  var intensityBefore: Int = 50  // 0–100

  var evidenceFor: [String] = []
  var evidenceAgainst: [String] = []

  var balancedThought: String = ""
  var intensityAfter: Int? = nil  // set on completion
}
