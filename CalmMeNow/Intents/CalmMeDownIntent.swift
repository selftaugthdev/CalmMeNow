import AppIntents

struct CalmMeDownIntent: AppIntent {
  static let title: LocalizedStringResource = "Calm Me Down"
  static let description = IntentDescription("Opens emergency calm mode to help you through a panic attack.")
  static let openAppWhenRun = true

  @MainActor
  func perform() async throws -> some IntentResult {
    DeepLinkManager.shared.shouldShowEmergencyCalm = true
    return .result()
  }
}
