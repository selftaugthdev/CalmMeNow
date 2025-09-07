import FirebaseAuth
import FirebaseFunctions
import Foundation

// MARK: - Emergency Companion Response
struct EmergencyCompanionResponse: Codable {
  let response: String
  let isCrisis: Bool
  let usageCount: Int
  let rateLimited: Bool?
  let crisisDetected: Bool?
  let redirected: Bool?
  let outputFlagged: Bool?
}

// MARK: - Emergency Companion Service
class EmergencyCompanionService: ObservableObject {
  static let shared = EmergencyCompanionService()

  private let functions = Functions.functions(region: "europe-west1")
  private let companionFunction = "emergencyCompanion"

  // Rate limiting
  @Published var dailyUsageCount: Int = 0
  @Published var isRateLimited: Bool = false
  @Published var lastMessageTime: Date?

  // Cooldown settings
  private let cooldownInterval: TimeInterval = 1  // 1 second between messages (prevents spam)
  private let maxDailyUsage = 6  // Free tier limit
  private let maxSessionMessages = 6  // Max messages per session

  // Session tracking
  @Published var sessionMessageCount: Int = 0
  @Published var hasShownDisclaimer: Bool = false

  private init() {
    loadUsageData()
  }

  // MARK: - Public Methods

  func sendMessage(_ message: String) async throws -> EmergencyCompanionResponse {
    // Check cooldown
    if let lastTime = lastMessageTime {
      let timeSinceLastMessage = Date().timeIntervalSince(lastTime)
      if timeSinceLastMessage < cooldownInterval {
        throw EmergencyCompanionError.cooldownActive(
          remaining: cooldownInterval - timeSinceLastMessage)
      }
    }

    // Check session limit
    if sessionMessageCount >= maxSessionMessages {
      throw EmergencyCompanionError.sessionLimitReached
    }

    // Check rate limiting
    if isRateLimited {
      throw EmergencyCompanionError.rateLimited
    }

    // Prepare request
    let requestData: [String: Any] = [
      "message": message,
      "locale": Locale.current.identifier,
    ]

    do {
      // Call Firebase function
      let result = try await functions.httpsCallable(companionFunction).call(requestData)

      guard let data = result.data as? [String: Any] else {
        throw EmergencyCompanionError.invalidResponse
      }

      // Parse response
      let response = try parseResponse(from: data)

      // Update local state
      await MainActor.run {
        updateLocalState(with: response)
      }

      return response

    } catch {
      // Handle specific Firebase errors
      if let error = error as NSError? {
        switch error.code {
        case 14:  // UNAVAILABLE
          throw EmergencyCompanionError.serviceUnavailable
        case 8:  // RESOURCE_EXHAUSTED
          throw EmergencyCompanionError.rateLimited
        case 16:  // UNAUTHENTICATED
          throw EmergencyCompanionError.authenticationRequired
        default:
          throw EmergencyCompanionError.networkError(error.localizedDescription)
        }
      }

      throw EmergencyCompanionError.unknownError(error.localizedDescription)
    }
  }

  func resetSession() {
    sessionMessageCount = 0
    hasShownDisclaimer = false
  }

  func canSendMessage() -> Bool {
    // Check if user is authenticated
    guard Auth.auth().currentUser != nil else { return false }

    // Check rate limiting
    if isRateLimited { return false }

    // Check session limit
    if sessionMessageCount >= maxSessionMessages { return false }

    // Check cooldown
    if let lastTime = lastMessageTime {
      let timeSinceLastMessage = Date().timeIntervalSince(lastTime)
      if timeSinceLastMessage < cooldownInterval { return false }
    }

    return true
  }

  func getCooldownRemaining() -> TimeInterval {
    guard let lastTime = lastMessageTime else { return 0 }
    let timeSinceLastMessage = Date().timeIntervalSince(lastTime)
    return max(0, cooldownInterval - timeSinceLastMessage)
  }

  func getUsageStatus() -> (count: Int, limit: Int, isLimited: Bool) {
    return (dailyUsageCount, maxDailyUsage, isRateLimited)
  }

  // MARK: - Private Methods

  private func parseResponse(from data: [String: Any]) throws -> EmergencyCompanionResponse {
    guard let response = data["response"] as? String else {
      throw EmergencyCompanionError.invalidResponse
    }

    let isCrisis = data["isCrisis"] as? Bool ?? false
    let usageCount = data["usageCount"] as? Int ?? 0
    let rateLimited = data["rateLimited"] as? Bool ?? false
    let crisisDetected = data["crisisDetected"] as? Bool ?? false
    let redirected = data["redirected"] as? Bool ?? false
    let outputFlagged = data["outputFlagged"] as? Bool ?? false

    return EmergencyCompanionResponse(
      response: response,
      isCrisis: isCrisis,
      usageCount: usageCount,
      rateLimited: rateLimited,
      crisisDetected: crisisDetected,
      redirected: redirected,
      outputFlagged: outputFlagged
    )
  }

  private func updateLocalState(with response: EmergencyCompanionResponse) {
    // Update usage count
    dailyUsageCount = response.usageCount

    // Update rate limiting status
    if let rateLimited = response.rateLimited {
      isRateLimited = rateLimited
    }

    // Update session count
    sessionMessageCount += 1

    // Update last message time
    lastMessageTime = Date()

    // Save to UserDefaults
    saveUsageData()
  }

  private func loadUsageData() {
    let today = getTodayString()
    let savedDate = UserDefaults.standard.string(forKey: "emergencyCompanionLastUsed")

    // Reset daily count if it's a new day
    if savedDate != today {
      dailyUsageCount = 0
      isRateLimited = false
    } else {
      dailyUsageCount = UserDefaults.standard.integer(forKey: "emergencyCompanionDailyCount")
      isRateLimited = UserDefaults.standard.bool(forKey: "emergencyCompanionRateLimited")
    }

    sessionMessageCount = UserDefaults.standard.integer(forKey: "emergencyCompanionSessionCount")
    hasShownDisclaimer = UserDefaults.standard.bool(forKey: "emergencyCompanionDisclaimerShown")
  }

  private func saveUsageData() {
    let today = getTodayString()
    UserDefaults.standard.set(today, forKey: "emergencyCompanionLastUsed")
    UserDefaults.standard.set(dailyUsageCount, forKey: "emergencyCompanionDailyCount")
    UserDefaults.standard.set(isRateLimited, forKey: "emergencyCompanionRateLimited")
    UserDefaults.standard.set(sessionMessageCount, forKey: "emergencyCompanionSessionCount")
    UserDefaults.standard.set(hasShownDisclaimer, forKey: "emergencyCompanionDisclaimerShown")
  }

  private func getTodayString() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd"
    return formatter.string(from: Date())
  }
}

// MARK: - Emergency Companion Errors
enum EmergencyCompanionError: LocalizedError {
  case rateLimited
  case sessionLimitReached
  case cooldownActive(remaining: TimeInterval)
  case serviceUnavailable
  case authenticationRequired
  case networkError(String)
  case invalidResponse
  case unknownError(String)

  var errorDescription: String? {
    switch self {
    case .rateLimited:
      return
        "You've reached your daily limit for the Emergency Companion. Please try again tomorrow or consider upgrading to Premium."
    case .sessionLimitReached:
      return
        "You've reached the maximum messages for this session. Let's close with a grounding exercise."
    case .cooldownActive(let remaining):
      return "Please wait \(Int(remaining)) seconds before sending another message."
    case .serviceUnavailable:
      return "The Emergency Companion is temporarily unavailable. Please try again later."
    case .authenticationRequired:
      return "Please sign in to use the Emergency Companion."
    case .networkError(let message):
      return "Network error: \(message)"
    case .invalidResponse:
      return "Received an invalid response. Please try again."
    case .unknownError(let message):
      return "An error occurred: \(message)"
    }
  }
}
