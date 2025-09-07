//
//  ServerLayerService.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import Foundation

// MARK: - Server Layer Models
struct ServerRequest {
  let id: String
  let feature: String
  let userId: String?
  let parameters: [String: Any]
  let timestamp: Date
  let priority: RequestPriority
}

enum RequestPriority: Int, CaseIterable {
  case emergency = 1
  case high = 2
  case normal = 3
  case low = 4
}

struct ServerResponse {
  let requestId: String
  let data: Data
  let source: ResponseSource
  let timestamp: Date
  let processingTime: TimeInterval
}

enum ResponseSource {
  case cache
  case template
  case ai
  case fallback
}

struct UserQuota {
  let userId: String
  let requestsPerHour: Int
  let tokensPerHour: Int
  let costPerHour: Double
  var currentUsage: QuotaUsage
}

struct QuotaUsage {
  let requests: Int
  let tokens: Int
  let cost: Double
  let resetTime: Date
}

// MARK: - Server Layer Service
class ServerLayerService: ObservableObject {
  static let shared = ServerLayerService()

  @Published var isProcessing = false
  @Published var queueSize = 0
  @Published var lastError: String?

  private let cacheManager = AICacheManager.shared
  private let templateManager = ExerciseTemplateManager.shared
  private let monitoringService = AIMonitoringService.shared
  private let minimalAIService = UltraMinimalAIService.shared

  private var requestQueue: [ServerRequest] = []
  private var userQuotas: [String: UserQuota] = [:]
  private let processingQueue = DispatchQueue(label: "server.layer.queue", qos: .userInitiated)
  private let maxConcurrentRequests = 3
  private var activeRequests = 0

  private init() {
    startProcessingQueue()
    loadUserQuotas()
  }

  // MARK: - Main Entry Point

  func processRequest(
    feature: String,
    userId: String? = nil,
    parameters: [String: Any],
    priority: RequestPriority = .normal
  ) async throws -> ServerResponse {

    let request = ServerRequest(
      id: UUID().uuidString,
      feature: feature,
      userId: userId,
      parameters: parameters,
      timestamp: Date(),
      priority: priority
    )

    // Check quota first
    if let userId = userId, !canProcessRequest(for: userId) {
      throw AIError.quotaExceeded
    }

    // Try cache first
    if let cachedResponse = tryGetCachedResponse(for: request) {
      return cachedResponse
    }

    // Try template fallback
    if let templateResponse = tryGetTemplateResponse(for: request) {
      return templateResponse
    }

    // Process with AI
    return try await processWithAI(request: request)
  }

  // MARK: - Request Processing

  private func startProcessingQueue() {
    processingQueue.async {
      while true {
        if self.activeRequests < self.maxConcurrentRequests,
          let request = self.getNextRequest()
        {
          self.activeRequests += 1

          Task {
            do {
              _ = try await self.processRequestInternal(request)
            } catch {
              print("Request processing failed: \(error)")
            }
            self.activeRequests -= 1
          }
        } else {
          Thread.sleep(forTimeInterval: 0.1)
        }
      }
    }
  }

  private func getNextRequest() -> ServerRequest? {
    return processingQueue.sync {
      guard !requestQueue.isEmpty else { return nil }

      // Sort by priority and timestamp
      requestQueue.sort { first, second in
        if first.priority.rawValue != second.priority.rawValue {
          return first.priority.rawValue < second.priority.rawValue
        }
        return first.timestamp < second.timestamp
      }

      return requestQueue.removeFirst()
    }
  }

  private func processRequestInternal(_ request: ServerRequest) async throws -> ServerResponse {
    let startTime = Date()

    // Normalize request
    let normalizedRequest = normalizeRequest(request)

    // Try cache
    if let cachedResponse = tryGetCachedResponse(for: normalizedRequest) {
      return cachedResponse
    }

    // Try template
    if let templateResponse = tryGetTemplateResponse(for: normalizedRequest) {
      return templateResponse
    }

    // Select appropriate model
    let model = selectModel(for: normalizedRequest)

    // Process with AI
    let response = try await processWithAIModel(normalizedRequest, model: model)

    // Cache response
    let serverResponse = ServerResponse(
      requestId: normalizedRequest.id,
      data: response.data,
      source: .ai,
      timestamp: Date(),
      processingTime: Date().timeIntervalSince(startTime)
    )
    cacheResponse(serverResponse, for: normalizedRequest)

    // Update quota
    if let userId = normalizedRequest.userId {
      updateUserQuota(userId: userId, tokens: estimateTokens(response.data))
    }

    let processingTime = Date().timeIntervalSince(startTime)
    return ServerResponse(
      requestId: normalizedRequest.id,
      data: response.data,
      source: .ai,
      timestamp: Date(),
      processingTime: processingTime
    )
  }

  // MARK: - Cache Management

  private func tryGetCachedResponse(for request: ServerRequest) -> ServerResponse? {
    let cacheKey = buildCacheKey(for: request)

    guard let cachedData = cacheManager.getCachedResponse(for: cacheKey, userId: request.userId)
    else {
      return nil
    }

    return ServerResponse(
      requestId: request.id,
      data: cachedData,
      source: .cache,
      timestamp: Date(),
      processingTime: 0.001
    )
  }

  private func tryGetTemplateResponse(for request: ServerRequest) -> ServerResponse? {
    guard let moodBucket = request.parameters["moodBucket"] as? String,
      let intensity = request.parameters["intensity"] as? Int,
      let tags = request.parameters["tags"] as? [String]
    else {
      return nil
    }

    guard
      let template = templateManager.selectTemplate(
        for: moodBucket,
        intensity: intensity,
        tags: tags
      )
    else {
      return nil
    }

    let recommendation = ExerciseRecommendation(
      exerciseId: template.id,
      title: template.title,
      steps: template.steps,
      duration: template.duration,
      parameters: template.parameters.mapValues { ExerciseRecommendation.AnyCodable($0) },
      note: nil
    )

    guard let data = try? JSONEncoder().encode(recommendation) else {
      return nil
    }

    return ServerResponse(
      requestId: request.id,
      data: data,
      source: .template,
      timestamp: Date(),
      processingTime: 0.001
    )
  }

  private func cacheResponse(_ response: ServerResponse, for request: ServerRequest) {
    let cacheKey = buildCacheKey(for: request)
    cacheManager.setCachedResponse(response.data, for: cacheKey, userId: request.userId)
  }

  private func buildCacheKey(for request: ServerRequest) -> CacheKey {
    let moodBucket = request.parameters["moodBucket"] as? String ?? "med"
    let intensity = request.parameters["intensity"] as? Int ?? 5
    let tags = request.parameters["tags"] as? [String] ?? []

    switch request.feature {
    case "daily_checkin":
      return CacheKey.forDailyCheckIn(moodBucket: moodBucket, tags: tags, intensity: intensity)
    case "panic_plan":
      return CacheKey.forPanicPlan(moodBucket: moodBucket, tags: tags, intensity: intensity)
    case "breathing_exercise":
      return CacheKey.forBreathingExercise(moodBucket: moodBucket, tags: tags, intensity: intensity)
    default:
      return CacheKey.forDailyCheckIn(moodBucket: moodBucket, tags: tags, intensity: intensity)
    }
  }

  // MARK: - Request Normalization

  private func normalizeRequest(_ request: ServerRequest) -> ServerRequest {
    var normalizedParameters = request.parameters

    // Normalize mood bucket
    if let intensity = normalizedParameters["intensity"] as? Int {
      let moodBucket = normalizeMoodBucket(intensity: intensity)
      normalizedParameters["moodBucket"] = moodBucket
    }

    // Normalize tags
    if let tags = normalizedParameters["tags"] as? [String] {
      normalizedParameters["tags"] = normalizeTags(tags)
    }

    return ServerRequest(
      id: request.id,
      feature: request.feature,
      userId: request.userId,
      parameters: normalizedParameters,
      timestamp: request.timestamp,
      priority: request.priority
    )
  }

  private func normalizeMoodBucket(intensity: Int) -> String {
    switch intensity {
    case 1...3: return "low"
    case 4...6: return "med"
    case 7...10: return "high"
    default: return "med"
    }
  }

  private func normalizeTags(_ tags: [String]) -> [String] {
    return tags.map { $0.lowercased() }.sorted()
  }

  // MARK: - Model Selection

  private func selectModel(for request: ServerRequest) -> String {
    // Always use gpt-4o-mini for all requests
    return OpenAIConfig.model
  }

  // MARK: - AI Processing

  private func processWithAI(request: ServerRequest) async throws -> ServerResponse {
    let startTime = Date()

    let model = selectModel(for: request)
    let response = try await processWithAIModel(request, model: model)

    let processingTime = Date().timeIntervalSince(startTime)
    return ServerResponse(
      requestId: request.id,
      data: response.data,
      source: .ai,
      timestamp: Date(),
      processingTime: processingTime
    )
  }

  private func processWithAIModel(_ request: ServerRequest, model: String) async throws -> (
    data: Data, tokens: Int
  ) {
    // This would integrate with the actual AI service
    // For now, return a placeholder
    let placeholderData = """
      {
          "exerciseId": "breath_4_2_6",
          "title": "4-2-6 Breathing",
          "steps": ["Sit comfortably", "Inhale for 4", "Hold for 2", "Exhale for 6"],
          "duration": 300
      }
      """.data(using: .utf8) ?? Data()

    return (data: placeholderData, tokens: 50)
  }

  // MARK: - Quota Management

  private func canProcessRequest(for userId: String) -> Bool {
    guard let quota = userQuotas[userId] else {
      // Default quota for new users
      userQuotas[userId] = createDefaultQuota(for: userId)
      return true
    }

    let now = Date()
    if now >= quota.currentUsage.resetTime {
      // Reset quota
      userQuotas[userId] = createDefaultQuota(for: userId)
      return true
    }

    return quota.currentUsage.requests < quota.requestsPerHour
      && quota.currentUsage.tokens < quota.tokensPerHour
      && quota.currentUsage.cost < quota.costPerHour
  }

  private func createDefaultQuota(for userId: String) -> UserQuota {
    return UserQuota(
      userId: userId,
      requestsPerHour: 50,
      tokensPerHour: 5000,
      costPerHour: 2.0,
      currentUsage: QuotaUsage(
        requests: 0,
        tokens: 0,
        cost: 0.0,
        resetTime: Date().addingTimeInterval(3600)
      )
    )
  }

  private func updateUserQuota(userId: String, tokens: Int) {
    guard var quota = userQuotas[userId] else { return }

    let cost = Double(tokens) * 0.0001  // Rough cost estimate

    quota.currentUsage = QuotaUsage(
      requests: quota.currentUsage.requests + 1,
      tokens: quota.currentUsage.tokens + tokens,
      cost: quota.currentUsage.cost + cost,
      resetTime: quota.currentUsage.resetTime
    )

    userQuotas[userId] = quota
    saveUserQuotas()
  }

  private func loadUserQuotas() {
    guard let data = UserDefaults.standard.data(forKey: "user_quotas"),
      let quotas = try? JSONDecoder().decode([String: UserQuota].self, from: data)
    else {
      return
    }
    userQuotas = quotas
  }

  private func saveUserQuotas() {
    guard let data = try? JSONEncoder().encode(userQuotas) else { return }
    UserDefaults.standard.set(data, forKey: "user_quotas")
  }

  // MARK: - Utility Methods

  private func estimateTokens(_ data: Data) -> Int {
    let text = String(data: data, encoding: .utf8) ?? ""
    return max(1, text.count / 4)
  }
}

// MARK: - User Quota Extensions
extension UserQuota: Codable {}
extension QuotaUsage: Codable {}
