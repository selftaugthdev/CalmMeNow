import FirebaseAuth
import FirebaseCore
import FirebaseFunctions
import Foundation

// MARK: - Custom Error Types
enum AIServiceError: LocalizedError {
  case functionCallFailed(String)
  case authenticationFailed(String)
  case invalidResponse(String)
  case paywallRequired(String)

  var errorDescription: String? {
    switch self {
    case .functionCallFailed(let message):
      return message
    case .authenticationFailed(let message):
      return message
    case .invalidResponse(let message):
      return message
    case .paywallRequired(let message):
      return message
    }
  }
}

final class AIService: ObservableObject {
  // Firebase Functions instance for europe-west1 region
  private lazy var functions = Functions.functions(region: "europe-west1")

  // Track if user has access to AI features
  @Published var hasAIAccess = false

  // MARK: - Anonymous Authentication

  /// Seamlessly ensures user is authenticated for AI features
  /// This happens behind the scenes - no UI interruption
  private func ensureAuthForAI() async throws {
    if Auth.auth().currentUser == nil {
      do {
        // Sign in anonymously without any user interaction
        let result = try await Auth.auth().signInAnonymously()
        print("🤖 AI Service: User automatically signed in anonymously with ID: \(result.user.uid)")

        // Mark that user now has AI access
        await MainActor.run {
          self.hasAIAccess = true
        }
      } catch {
        print("❌ AI Service: Anonymous authentication failed: \(error)")
        throw AIServiceError.authenticationFailed(
          "Failed to authenticate for AI features: \(error.localizedDescription)")
      }
    } else {
      // User already authenticated
      await MainActor.run {
        self.hasAIAccess = true
      }
    }
  }

  // MARK: - AI Feature Methods (Behind Paywall)

  /// Generate Personalized Panic Plan - requires AI access
  func generatePanicPlanFromIntake(intake: [String: Any]) async throws -> [String: Any] {
    try await ensureAuthForAI()

    let data: [String: Any] = ["intake": intake]
    let result = try await functions.httpsCallable("generatePanicPlan").call(data)
    return result.data as? [String: Any] ?? [:]
  }

  /// Daily Check-in with AI insights - requires AI access
  func dailyCheckIn(checkin: [String: Any]) async throws -> [String: Any] {
    try await ensureAuthForAI()

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

  // MARK: - Access Control

  /// Check if user currently has AI access
  var isAIAvailable: Bool {
    return Auth.auth().currentUser != nil
  }

  /// Sign out user (for testing or if needed)
  func signOut() {
    do {
      try Auth.auth().signOut()
      hasAIAccess = false
      print("👋 AI Service: User signed out")
    } catch {
      print("❌ AI Service: Sign out failed: \(error)")
    }
  }
}
