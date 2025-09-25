import Foundation
import SwiftUI

@MainActor
class AIServiceViewModel: ObservableObject {
  @Published var isLoading = false
  @Published var currentPlan: PanicPlan?
  @Published var lastCheckIn: DailyCheckInResponse?
  @Published var errorMessage: String?

  private let aiService = AiService.shared

  // MARK: - Panic Plan Generation

  func generatePanicPlan(
    triggers: [String],
    symptoms: [String],
    preferences: [String],
    duration: Int,
    phrase: String
  ) async {
    isLoading = true
    errorMessage = nil

    do {
      let intake: [String: Any] = [
        "triggers": triggers,
        "symptoms": symptoms,
        "preferences": preferences,
        "duration": duration,
        "personalizedPhrase": phrase,
        "phrase": phrase,  // Keep both for compatibility
      ]

      let planData = try await aiService.generatePanicPlan(intake: intake)

      currentPlan = PanicPlan(from: planData)

      // Store the user's phrase in UserDefaults for fallback
      UserDefaults.standard.set(phrase, forKey: "userCalmingPhrase")

      // Store the plan locally for future reference
      await storePlanLocally(currentPlan!)

    } catch {
      errorMessage = "Failed to generate plan: \(error.localizedDescription)"
      print("Error generating panic plan: \(error)")
    }

    isLoading = false
  }

  // MARK: - Daily Check-in

  func submitDailyCheckIn(
    mood: Int,
    tags: [String],
    note: String
  ) async {
    isLoading = true
    errorMessage = nil
    let startTime = CFAbsoluteTimeGetCurrent()

    do {
      let checkin: [String: Any] = [
        "mood": mood,
        "tags": tags,
        "note": note,
      ]

      let checkInData = try await aiService.dailyCheckIn(checkin: checkin)

      // Debug: Pretty print the raw response
      printJSON(checkInData, prefix: "🧩 CheckIn raw")

      guard let dict = checkInData as? [String: Any] else {
        print("❌ Failed to cast response to [String: Any]")
        throw NSError(
          domain: "ParseError", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
      }

      let parsedResponse = DailyCheckInResponse(from: dict)

      // Ensure UI update happens on main thread
      await MainActor.run {
        self.lastCheckIn = parsedResponse
      }

      // Handle the response based on severity
      await handleCheckInResponse(parsedResponse)

      // Track successful check-in submission
      let latencyMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)
      AnalyticsLogger.shared.dailyCheckinSubmitted(
        severity: lastCheckIn?.severity ?? 0,
        suggestedPath: lastCheckIn?.exercise ?? "none",
        latencyMs: latencyMs
      )

    } catch {
      errorMessage = "Failed to submit check-in: \(error.localizedDescription)"
      print("Error submitting daily check-in: \(error)")
    }

    isLoading = false
  }

  // MARK: - Helper Methods

  private func storePlanLocally(_ plan: PanicPlan) async {
    // Store the plan in UserDefaults or local storage
    // This could be expanded to use Core Data or other persistence
    if let encoded = try? JSONEncoder().encode(plan) {
      UserDefaults.standard.set(encoded, forKey: "currentPanicPlan")
    }
  }

  private func handleCheckInResponse(_ response: DailyCheckInResponse) async {
    // If severity is high, show resources
    if response.severity >= 2 {
      // Navigate to resources view or show emergency options
      print("High severity detected: \(response.severity)")
    } else if let exercise = response.exercise {
      // Run the suggested exercise
      print("Suggested exercise: \(exercise)")
    }
  }

  // MARK: - Plan Retrieval

  func loadStoredPlan() {
    if let data = UserDefaults.standard.data(forKey: "currentPanicPlan"),
      let plan = try? JSONDecoder().decode(PanicPlan.self, from: data)
    {
      currentPlan = plan
    }
  }

  func clearStoredPlan() {
    UserDefaults.standard.removeObject(forKey: "currentPanicPlan")
    currentPlan = nil
  }
}
