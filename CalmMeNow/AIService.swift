import Firebase
import FirebaseAppCheck
import FirebaseAuth
import FirebaseFunctions
import Foundation

final class AiService {
  static let shared = AiService()

  private let functions: Functions

  private init() {
    // Initialize Firebase (only once in app lifecycle)
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()

      #if targetEnvironment(simulator)
        // Debug mode: works in Simulator, requires debug token in Console > App Check > Debug tokens
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
      #else
        // Production: uses Apple DeviceCheck on real devices / TestFlight
        AppCheck.setAppCheckProviderFactory(DeviceCheckProviderFactory())
      #endif
    }

    self.functions = Functions.functions(region: "europe-west1")
  }

  /// Ensure the user has an Auth session (anonymous is fine).
  private func ensureAuth() async throws {
    if Auth.auth().currentUser == nil {
      _ = try await Auth.auth().signInAnonymously()
    }
  }

  /// Generate a personalized panic plan from intake data.
  func generatePanicPlan(intake: [String: Any]) async throws -> [String: Any] {
    try await ensureAuth()
    let result = try await functions.httpsCallable("generatePanicPlan").call(["intake": intake])
    return result.data as? [String: Any] ?? [:]
  }

  /// Perform a daily check-in (classifier + micro-exercise).
  func dailyCheckIn(checkin: [String: Any]) async throws -> [String: Any] {
    try await ensureAuth()
    let result = try await functions.httpsCallable("dailyCheckIn").call(["checkin": checkin])
    return result.data as? [String: Any] ?? [:]
  }
}
