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
  private let maxDailyUsage = 30  // Premium tier limit (reasonable for paying customers)
  private let maxSessionMessages = 15  // Max messages per session (reasonable for paying customers)
  private let maxDailyResets = 10  // Max resets per day to prevent abuse

  // Session tracking
  @Published var sessionMessageCount: Int = 0
  @Published var hasShownDisclaimer: Bool = false
  @Published var dailyResetCount: Int = 0

  private init() {
    loadUsageData()
  }

  // MARK: - Public Methods

  func sendMessage(_ message: String, conversationHistory: [[String: String]] = []) async throws
    -> EmergencyCompanionResponse
  {
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
      "conversationHistory": conversationHistory,
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
        incrementSessionCount()
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

  func resetSession() throws {
    // Check reset limit
    if dailyResetCount >= maxDailyResets {
      throw EmergencyCompanionError.resetLimitReached
    }

    sessionMessageCount = 0
    hasShownDisclaimer = false
    dailyResetCount += 1
    saveUsageData()
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

    // Update last message time
    lastMessageTime = Date()

    // Save to UserDefaults
    saveUsageData()
  }

  private func incrementSessionCount() {
    sessionMessageCount += 1
    saveUsageData()
  }

  private func loadUsageData() {
    let today = getTodayString()
    let savedDate = UserDefaults.standard.string(forKey: "emergencyCompanionLastUsed")

    // Reset daily count if it's a new day
    if savedDate != today {
      dailyUsageCount = 0
      isRateLimited = false
      dailyResetCount = 0
    } else {
      dailyUsageCount = UserDefaults.standard.integer(forKey: "emergencyCompanionDailyCount")
      isRateLimited = UserDefaults.standard.bool(forKey: "emergencyCompanionRateLimited")
      dailyResetCount = UserDefaults.standard.integer(forKey: "emergencyCompanionDailyResets")
    }

    // Session count should always start at 0 for a new session
    sessionMessageCount = 0
    hasShownDisclaimer = UserDefaults.standard.bool(forKey: "emergencyCompanionDisclaimerShown")
  }

  private func saveUsageData() {
    let today = getTodayString()
    UserDefaults.standard.set(today, forKey: "emergencyCompanionLastUsed")
    UserDefaults.standard.set(dailyUsageCount, forKey: "emergencyCompanionDailyCount")
    UserDefaults.standard.set(isRateLimited, forKey: "emergencyCompanionRateLimited")
    UserDefaults.standard.set(dailyResetCount, forKey: "emergencyCompanionDailyResets")
    // Don't save sessionMessageCount - it should always start at 0 for new sessions
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
  case resetLimitReached
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
        "You've had a lot of conversations with your Companion today. Sometimes it helps to take a break and use your Emergency Plan or a breathing exercise. I'll be ready when you check in again tomorrow."
    case .sessionLimitReached:
      return
        "You've had a good conversation with your Companion. Sometimes it helps to take a break and use your Emergency Plan or a breathing exercise. I'll be ready when you start a new session."
    case .resetLimitReached:
      return
        "You've started many new conversations today. Sometimes it helps to take a break and use your Emergency Plan or a breathing exercise. I'll be ready when you check in again tomorrow."
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
