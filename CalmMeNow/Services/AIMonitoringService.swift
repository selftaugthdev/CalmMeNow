//
//  AIMonitoringService.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import Foundation

// MARK: - Token Usage Tracking
struct TokenUsage {
  let feature: String
  let model: String
  let promptTokens: Int
  let completionTokens: Int
  let totalTokens: Int
  let timestamp: Date
  let userId: String?
  let cost: Double
}

// MARK: - Usage Statistics
struct UsageStats {
  let totalRequests: Int
  let totalTokens: Int
  let totalCost: Double
  let averageTokensPerRequest: Double
  let requestsByFeature: [String: Int]
  let tokensByModel: [String: Int]
  let costByFeature: [String: Double]
}

// MARK: - AI Monitoring Service
class AIMonitoringService: ObservableObject {
  static let shared = AIMonitoringService()

  @Published var currentUsage: UsageStats?
  @Published var isOverQuota = false

  private var usageHistory: [TokenUsage] = []
  private let maxRequestsPerHour = 100
  private let maxTokensPerHour = 10000
  private let maxCostPerHour = 5.0

  // Token costs per 1K tokens (as of 2024)
  private let tokenCosts: [String: (input: Double, output: Double)] = [
    "gpt-4o-mini": (input: 0.00015, output: 0.0006),
    "gpt-3.5-turbo": (input: 0.0005, output: 0.0015),
  ]

  private init() {
    loadUsageHistory()
    updateCurrentUsage()
  }

  // MARK: - Usage Tracking

  func trackUsage(
    feature: String,
    model: String,
    promptTokens: Int,
    completionTokens: Int,
    userId: String? = nil
  ) {
    let totalTokens = promptTokens + completionTokens
    let cost = calculateCost(
      model: model, promptTokens: promptTokens, completionTokens: completionTokens)

    let usage = TokenUsage(
      feature: feature,
      model: model,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: totalTokens,
      timestamp: Date(),
      userId: userId,
      cost: cost
    )

    usageHistory.append(usage)
    updateCurrentUsage()
    checkQuotaLimits()
    saveUsageHistory()
  }

  func trackRequest(feature: String, model: String, response: OpenAIResponse, userId: String? = nil)
  {
    let usage = response.usage
    trackUsage(
      feature: feature,
      model: model,
      promptTokens: usage?.promptTokens ?? 0,
      completionTokens: usage?.completionTokens ?? 0,
      userId: userId
    )
  }

  // MARK: - Quota Management

  func canMakeRequest(feature: String, model: String) -> Bool {
    let recentUsage = getRecentUsage(within: 3600)  // Last hour

    if recentUsage.count >= maxRequestsPerHour {
      return false
    }

    let recentTokens = recentUsage.reduce(0) { $0 + $1.totalTokens }
    if recentTokens >= maxTokensPerHour {
      return false
    }

    let recentCost = recentUsage.reduce(0.0) { $0 + $1.cost }
    if recentCost >= maxCostPerHour {
      return false
    }

    return true
  }

  func getRemainingQuota() -> (requests: Int, tokens: Int, cost: Double) {
    let recentUsage = getRecentUsage(within: 3600)

    let remainingRequests = max(0, maxRequestsPerHour - recentUsage.count)
    let usedTokens = recentUsage.reduce(0) { $0 + $1.totalTokens }
    let remainingTokens = max(0, maxTokensPerHour - usedTokens)
    let usedCost = recentUsage.reduce(0.0) { $0 + $1.cost }
    let remainingCost = max(0.0, maxCostPerHour - usedCost)

    return (remainingRequests, remainingTokens, remainingCost)
  }

  // MARK: - Statistics

  func getUsageStats(for period: TimeInterval = 86400) -> UsageStats {
    let recentUsage = getRecentUsage(within: period)

    let totalRequests = recentUsage.count
    let totalTokens = recentUsage.reduce(0) { $0 + $1.totalTokens }
    let totalCost = recentUsage.reduce(0.0) { $0 + $1.cost }
    let averageTokensPerRequest =
      totalRequests > 0 ? Double(totalTokens) / Double(totalRequests) : 0

    var requestsByFeature: [String: Int] = [:]
    var tokensByModel: [String: Int] = [:]
    var costByFeature: [String: Double] = [:]

    for usage in recentUsage {
      requestsByFeature[usage.feature, default: 0] += 1
      tokensByModel[usage.model, default: 0] += usage.totalTokens
      costByFeature[usage.feature, default: 0.0] += usage.cost
    }

    return UsageStats(
      totalRequests: totalRequests,
      totalTokens: totalTokens,
      totalCost: totalCost,
      averageTokensPerRequest: averageTokensPerRequest,
      requestsByFeature: requestsByFeature,
      tokensByModel: tokensByModel,
      costByFeature: costByFeature
    )
  }

  // MARK: - Alerts and Monitoring

  func checkForAnomalies() -> [String] {
    var alerts: [String] = []

    let stats = getUsageStats()

    // Check for high token usage
    if stats.averageTokensPerRequest > 200 {
      alerts.append(
        "High average token usage: \(Int(stats.averageTokensPerRequest)) tokens/request")
    }

    // Check for expensive features
    for (feature, cost) in stats.costByFeature {
      if cost > 2.0 {
        alerts.append("High cost for \(feature): $\(String(format: "%.2f", cost))")
      }
    }

    // Check for quota approaching
    let quota = getRemainingQuota()
    if quota.requests < 10 {
      alerts.append("Low request quota remaining: \(quota.requests)")
    }

    if quota.cost < 1.0 {
      alerts.append("Low cost quota remaining: $\(String(format: "%.2f", quota.cost))")
    }

    return alerts
  }

  // MARK: - Private Methods

  private func calculateCost(model: String, promptTokens: Int, completionTokens: Int) -> Double {
    guard let costs = tokenCosts[model] else { return 0.0 }

    let inputCost = (Double(promptTokens) / 1000.0) * costs.input
    let outputCost = (Double(completionTokens) / 1000.0) * costs.output

    return inputCost + outputCost
  }

  private func getRecentUsage(within seconds: TimeInterval) -> [TokenUsage] {
    let cutoff = Date().addingTimeInterval(-seconds)
    return usageHistory.filter { $0.timestamp >= cutoff }
  }

  private func updateCurrentUsage() {
    currentUsage = getUsageStats()
  }

  private func checkQuotaLimits() {
    let recentUsage = getRecentUsage(within: 3600)
    isOverQuota =
      recentUsage.count >= maxRequestsPerHour
      || recentUsage.reduce(0) { $0 + $1.totalTokens } >= maxTokensPerHour
      || recentUsage.reduce(0.0) { $0 + $1.cost } >= maxCostPerHour
  }

  private func loadUsageHistory() {
    guard let data = UserDefaults.standard.data(forKey: "ai_usage_history"),
      let decoded = try? JSONDecoder().decode([TokenUsage].self, from: data)
    else {
      return
    }

    // Keep only last 7 days of history
    let cutoff = Date().addingTimeInterval(-7 * 24 * 3600)
    usageHistory = decoded.filter { $0.timestamp >= cutoff }
  }

  private func saveUsageHistory() {
    // Keep only last 7 days of history
    let cutoff = Date().addingTimeInterval(-7 * 24 * 3600)
    let recentHistory = usageHistory.filter { $0.timestamp >= cutoff }

    guard let data = try? JSONEncoder().encode(recentHistory) else { return }
    UserDefaults.standard.set(data, forKey: "ai_usage_history")
  }
}

// MARK: - Retry Manager with Exponential Backoff
class AIRetryManager {
  static let shared = AIRetryManager()

  private var retryCounts: [String: Int] = [:]
  private let maxRetries = 3
  private let baseDelay: TimeInterval = 1.0

  private init() {}

  func shouldRetry(requestId: String) -> Bool {
    let count = retryCounts[requestId, default: 0]
    return count < maxRetries
  }

  func getRetryDelay(requestId: String) -> TimeInterval {
    let count = retryCounts[requestId, default: 0]
    return baseDelay * pow(2.0, Double(count))
  }

  func incrementRetryCount(requestId: String) {
    retryCounts[requestId, default: 0] += 1
  }

  func resetRetryCount(requestId: String) {
    retryCounts.removeValue(forKey: requestId)
  }

  func clearOldRetryCounts() {
    // Clear retry counts older than 1 hour
    retryCounts.removeAll()
  }
}

// MARK: - Token Usage Extensions
extension TokenUsage: Codable {
  enum CodingKeys: String, CodingKey {
    case feature, model, promptTokens, completionTokens, totalTokens, timestamp, userId, cost
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    feature = try container.decode(String.self, forKey: .feature)
    model = try container.decode(String.self, forKey: .model)
    promptTokens = try container.decode(Int.self, forKey: .promptTokens)
    completionTokens = try container.decode(Int.self, forKey: .completionTokens)
    totalTokens = try container.decode(Int.self, forKey: .totalTokens)
    timestamp = try container.decode(Date.self, forKey: .timestamp)
    userId = try container.decodeIfPresent(String.self, forKey: .userId)
    cost = try container.decode(Double.self, forKey: .cost)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(feature, forKey: .feature)
    try container.encode(model, forKey: .model)
    try container.encode(promptTokens, forKey: .promptTokens)
    try container.encode(completionTokens, forKey: .completionTokens)
    try container.encode(totalTokens, forKey: .totalTokens)
    try container.encode(timestamp, forKey: .timestamp)
    try container.encodeIfPresent(userId, forKey: .userId)
    try container.encode(cost, forKey: .cost)
  }
}
