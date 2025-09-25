import Firebase
import FirebaseAppCheck
import FirebaseAuth
import FirebaseFunctions
import Foundation

final class AiService {
  static let shared = AiService()

  private let functions: Functions

  private init() {
    // Firebase is already configured by AppDelegate with proper App Check setup
    // Just get the Functions instance for europe-west1 region
    self.functions = Functions.functions(region: "europe-west1")
  }

  private func describe(_ error: Error) -> String {
    let ns = error as NSError
    if ns.domain == FunctionsErrorDomain {
      let code = FunctionsErrorCode(rawValue: ns.code) ?? .unknown
      let details = ns.userInfo[FunctionsErrorDetailsKey] as? String
      return
        "Functions error (\(code.rawValue)): \(details ?? ns.localizedDescription) | userInfo=\(ns.userInfo)"
    }
    return ns.localizedDescription
  }

  // MARK: - Callables

  func generatePanicPlan(intake: [String: Any]) async throws -> [String: Any] {
    print("🧠 AiService: Generating panic plan...")
    _ = try await AuthManager.shared.ensureSignedIn()  // ✅ guarantees req.auth
    print("🧠 AiService: Calling generatePanicPlan function...")
    let result = try await functions.httpsCallable("generatePanicPlan").call(["intake": intake])
    print("🧠 AiService: Function call successful")
    return result.data as? [String: Any] ?? [:]
  }

  /// Perform a daily check-in (classifier + micro-exercise).
  func dailyCheckIn(checkin: [String: Any]) async throws -> [String: Any] {
    print("📅 AiService: Submitting daily check-in...")
    _ = try await AuthManager.shared.ensureSignedIn()  // ✅
    print("📅 AiService: Calling dailyCheckIn function...")

    let requestData = ["checkin": checkin]
    printJSON(requestData, prefix: "📤 Sending to Firebase")

    let result = try await functions.httpsCallable("dailyCheckIn").call(requestData)
    print("📅 AiService: Function call successful")

    printJSON(result.data, prefix: "🧩 CheckIn raw response")

    guard let dict = result.data as? [String: Any] else {
      print("❌ Failed to cast response to [String: Any]")
      return [:]
    }

    return dict
  }

  // MARK: - Debug Methods

  /// Test the daily check-in function with a hardcoded response
  func testDailyCheckIn() async {
    print("🧪 Testing daily check-in function...")
    do {
      let result = try await functions.httpsCallable("testDailyCheckIn").call([:])
      printJSON(result.data, prefix: "🧪 Test response")

      if let dict = result.data as? [String: Any] {
        let response = DailyCheckInResponse(from: dict)
        print(
          "🧪 Parsed test response - coachLine: \(response.coachLine ?? "nil"), quickResetSteps: \(response.quickResetSteps?.count ?? 0)"
        )
      }
    } catch {
      print("🧪 Test failed: \(error)")
    }
  }

  func generatePlanDebug() async {
    print("🧠 AiService: Generating panic plan...")
    do {
      _ = try await AuthManager.shared.ensureSignedIn()

      // IMPORTANT: Use JSON-friendly types (no Swift structs)
      let intake: [String: Any] = [
        "situation": "crowded train",
        "body": ["racing heart", "dizzy"],
        "preferences": ["breathing": "478", "grounding": "54321"],
      ]
      let data: [String: Any] = ["intake": intake]

      let callable = functions.httpsCallable("generatePanicPlan")
      let result = try await callable.call(data)
      print("✅ plan result:", result.data)
    } catch {
      print("Callable error:", describe(error))
    }
  }

  func dailyCheckInDebug() async {
    print("📅 AiService: Submitting daily check-in...")
    do {
      _ = try await AuthManager.shared.ensureSignedIn()

      let checkin: [String: Any] = [
        "mood": 4,
        "tags": ["tired", "overwhelmed"],
        "note": "slept 4h",
      ]
      let data: [String: Any] = ["checkin": checkin]

      let callable = functions.httpsCallable("dailyCheckIn")
      let result = try await callable.call(data)
      print("✅ checkin result:", result.data)
    } catch {
      print("Callable error:", describe(error))
    }
  }
}
