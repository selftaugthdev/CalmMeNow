import FirebaseAuth
import FirebaseCore
import FirebaseFunctions
import Foundation

// MARK: - Custom Error Types
enum AIServiceError: LocalizedError {
  case functionCallFailed(String)
  case authenticationFailed(String)
  case invalidResponse(String)

  var errorDescription: String? {
    switch self {
    case .functionCallFailed(let message):
      return message
    case .authenticationFailed(let message):
      return message
    case .invalidResponse(let message):
      return message
    }
  }
}

final class AIService: ObservableObject {
  // Firebase Functions instance for europe-west1 region
  private lazy var functions = Functions.functions(region: "europe-west1")

  // Optional: ensure the user is signed in (anonymous is fine)
  func ensureAuth() async throws {
    if Auth.auth().currentUser == nil {
      try await Auth.auth().signInAnonymously()
    }
  }

  // Generate Personalized Panic Plan
  func generatePanicPlanFromIntake(intake: [String: Any]) async throws -> [String: Any] {
    try await ensureAuth()

    let data: [String: Any] = ["intake": intake]
    let result = try await functions.httpsCallable("generatePanicPlan").call(data)
    return result.data as? [String: Any] ?? [:]
  }

  // Daily Check-in
  func dailyCheckIn(checkin: [String: Any]) async throws -> [String: Any] {
    try await ensureAuth()

    let result = try await functions.httpsCallable("dailyCheckIn").call(["checkin": checkin])
    return result.data as? [String: Any] ?? [:]
  }

  // MARK: - Convenience Methods for Common Use Cases

  /// Generate a panic plan with structured input
  func generatePanicPlan(
    triggers: [String],
    symptoms: [String],
    preferences: [String],
    duration: Int,
    phrase: String
  ) async throws -> [String: Any] {
    let intake: [String: Any] = [
      "triggers": triggers,
      "symptoms": symptoms,
      "preferences": preferences,
      "duration": duration,
      "phrase": phrase,
    ]
    return try await generatePanicPlanFromIntake(intake: intake)
  }

  /// Submit a daily check-in with structured input
  func submitDailyCheckIn(
    mood: Int,
    tags: [String],
    note: String
  ) async throws -> [String: Any] {
    let checkin: [String: Any] = [
      "mood": mood,
      "tags": tags,
      "note": note,
    ]
    return try await dailyCheckIn(checkin: checkin)
  }
}
