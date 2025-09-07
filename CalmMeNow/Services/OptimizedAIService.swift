//
//  OptimizedAIService.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import Foundation

// MARK: - Optimized AI Service
class OptimizedAIService: ObservableObject {
  static let shared = OptimizedAIService()

  @Published var isLoading = false
  @Published var lastError: String?

  let cacheManager = AICacheManager.shared
  private let templateManager = ExerciseTemplateManager.shared
  private let debounceManager = DebounceManager()

  private init() {}

  // MARK: - Main Entry Points

  /// Get exercise recommendation with caching and template fallback
  func getExerciseRecommendation(
    moodBucket: String,
    intensity: Int,
    tags: [String],
    userId: String? = nil,
    language: String = "en"
  ) async throws -> ExerciseRecommendation {

    let cacheKey = CacheKey.forDailyCheckIn(
      moodBucket: moodBucket,
      tags: tags,
      intensity: intensity,
      language: language
    )

    // Try cache first
    if let cachedData = cacheManager.getCachedResponse(for: cacheKey, userId: userId),
      let cached = try? JSONDecoder().decode(ExerciseRecommendation.self, from: cachedData)
    {
      return cached
    }

    // Try similarity cache
    if let similarData = cacheManager.findSimilarCachedResponse(for: cacheKey, userId: userId),
      let similar = try? JSONDecoder().decode(ExerciseRecommendation.self, from: similarData)
    {
      // Cache this result for future use
      if let data = try? JSONEncoder().encode(similar) {
        cacheManager.setCachedResponse(data, for: cacheKey, userId: userId)
      }
      return similar
    }

    // Try template first (no API call needed)
    if let template = templateManager.selectTemplate(
      for: moodBucket, intensity: intensity, tags: tags)
    {
      let recommendation = ExerciseRecommendation(
        exerciseId: template.id,
        title: template.title,
        steps: template.steps,
        duration: template.duration,
        parameters: template.parameters.mapValues { ExerciseRecommendation.AnyCodable($0) },
        note: generatePersonalizedNote(for: template, moodBucket: moodBucket, tags: tags)
      )

      // Cache the result
      if let data = try? JSONEncoder().encode(recommendation) {
        cacheManager.setCachedResponse(data, for: cacheKey, userId: userId)
      }

      return recommendation
    }

    // Fallback to AI generation (only for complex cases)
    return try await generateAIExerciseRecommendation(
      moodBucket: moodBucket,
      intensity: intensity,
      tags: tags,
      cacheKey: cacheKey,
      userId: userId
    )
  }

  /// Generate panic plan with caching
  func generatePanicPlan(
    moodBucket: String,
    intensity: Int,
    tags: [String],
    userId: String? = nil,
    language: String = "en"
  ) async throws -> PanicPlan {

    let cacheKey = CacheKey.forPanicPlan(
      moodBucket: moodBucket,
      tags: tags,
      intensity: intensity,
      language: language
    )

    // Try cache first
    if let cachedData = cacheManager.getCachedResponse(for: cacheKey, userId: userId),
      let cached = try? JSONDecoder().decode(PanicPlan.self, from: cachedData)
    {
      return cached
    }

    // Generate new plan
    let plan = try await generateAIPanicPlan(
      moodBucket: moodBucket,
      intensity: intensity,
      tags: tags
    )

    // Cache the result
    if let data = try? JSONEncoder().encode(plan) {
      cacheManager.setCachedResponse(data, for: cacheKey, userId: userId)
    }

    return plan
  }

  // MARK: - Debounced UI Calls

  func debouncedExerciseRecommendation(
    moodBucket: String,
    intensity: Int,
    tags: [String],
    userId: String? = nil,
    completion: @escaping (Result<ExerciseRecommendation, Error>) -> Void
  ) {
    debounceManager.debounce(key: "exercise_recommendation", delay: 0.5) {
      Task {
        do {
          let result = try await self.getExerciseRecommendation(
            moodBucket: moodBucket,
            intensity: intensity,
            tags: tags,
            userId: userId
          )
          await MainActor.run {
            completion(.success(result))
          }
        } catch {
          await MainActor.run {
            completion(.failure(error))
          }
        }
      }
    }
  }

  // MARK: - Private Methods

  private func generatePersonalizedNote(
    for template: ExerciseTemplate, moodBucket: String, tags: [String]
  ) -> String? {
    // Simple rule-based personalization without AI call
    if tags.contains("anxious") {
      return "Focus on slow, deep breaths to calm your nervous system."
    } else if tags.contains("angry") {
      return "Use this exercise to release tension and find your center."
    } else if tags.contains("sad") {
      return "This gentle practice can help lift your spirits."
    }
    return nil
  }

  private func generateAIExerciseRecommendation(
    moodBucket: String,
    intensity: Int,
    tags: [String],
    cacheKey: CacheKey,
    userId: String?
  ) async throws -> ExerciseRecommendation {

    // Use minimal model for classification
    let classificationPrompt = """
      You are a router. Map inputs into a compact JSON for a calming exercise.
      Return ONLY JSON:
      {
       "exercise": "breathing|grounding|stretch",
       "params": { "inhale":4,"hold":2,"exhale":6,"duration_s":60 },
       "note": ""
      }
      Inputs:
      mood_bucket: \(moodBucket)
      intensity: \(intensity)
      tags: \(tags.joined(separator: ","))
      """

    let response = try await sendOptimizedRequest(
      prompt: classificationPrompt,
      useMinimalModel: true,
      maxTokens: OpenAIConfig.maxTokensMinimal
    )

    // Parse response and create recommendation
    guard let data = response.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let exercise = json["exercise"] as? String
    else {
      throw AIError.invalidResponse
    }

    // Get template based on classification
    let category = ExerciseCategory(rawValue: exercise) ?? .breathing
    guard let template = templateManager.getRandomTemplate(for: category) else {
      throw AIError.templateNotFound
    }

    let recommendation = ExerciseRecommendation(
      exerciseId: template.id,
      title: template.title,
      steps: template.steps,
      duration: template.duration,
      parameters: template.parameters.mapValues { ExerciseRecommendation.AnyCodable($0) },
      note: json["note"] as? String
    )

    return recommendation
  }

  private func generateAIPanicPlan(
    moodBucket: String,
    intensity: Int,
    tags: [String]
  ) async throws -> PanicPlan {

    let prompt = """
      Return ONLY JSON. No prose.
      {
       "title": "Personalized Calm Plan",
       "steps": ["...", "...", "..."],
       "duration_s": 300,
       "safety": "If symptoms escalate, stop and seek help."
      }
      Constraints: max 6 steps, each <= 110 chars.
      Context: mood=\(moodBucket), intensity=\(intensity), tags=\(tags.joined(separator: ","))
      """

    let response = try await sendOptimizedRequest(
      prompt: prompt,
      useMinimalModel: false,
      maxTokens: OpenAIConfig.maxTokens
    )

    guard let data = response.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let title = json["title"] as? String,
      let steps = json["steps"] as? [String],
      let duration = json["duration_s"] as? Int,
      let safety = json["safety"] as? String
    else {
      throw AIError.invalidResponse
    }

    return PanicPlan(
      title: title,
      description: "AI-generated panic plan",
      steps: steps,
      duration: duration,
      techniques: ["Breathing", "Grounding", "Mindfulness"],
      emergencyContact: nil,
      personalizedPhrase: safety
    )
  }

  private func sendOptimizedRequest(
    prompt: String,
    useMinimalModel: Bool,
    maxTokens: Int
  ) async throws -> String {

    let model = OpenAIConfig.model  // Always use gpt-4o-mini
    let temperature = useMinimalModel ? OpenAIConfig.temperatureMinimal : OpenAIConfig.temperature

    let request = OpenAIRequest(
      model: model,
      messages: [OpenAIMessage(role: "user", content: prompt)],
      maxTokens: maxTokens,
      temperature: temperature
    )

    return try await performOptimizedRequest(request)
  }

  private func performOptimizedRequest(_ request: OpenAIRequest) async throws -> String {
    guard let url = URL(string: "\(OpenAIConfig.baseURL)/chat/completions") else {
      throw AIError.invalidURL
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.allHTTPHeaderFields = OpenAIConfig.headers

    do {
      let jsonData = try JSONEncoder().encode(request)
      urlRequest.httpBody = jsonData
    } catch {
      throw AIError.encodingError(error)
    }

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw AIError.invalidResponse
    }

    guard httpResponse.statusCode == 200 else {
      let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
      throw AIError.apiError(httpResponse.statusCode, errorMessage)
    }

    do {
      let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
      guard let firstChoice = openAIResponse.choices.first else {
        throw AIError.noResponse
      }

      return firstChoice.message.content
    } catch {
      throw AIError.decodingError(error)
    }
  }
}

// MARK: - Response Models
struct ExerciseRecommendation: Codable {
  let exerciseId: String
  let title: String
  let steps: [String]
  let duration: Int
  let parameters: [String: AnyCodable]
  let note: String?

  struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
      self.value = value
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      if let intValue = try? container.decode(Int.self) {
        value = intValue
      } else if let stringValue = try? container.decode(String.self) {
        value = stringValue
      } else if let doubleValue = try? container.decode(Double.self) {
        value = doubleValue
      } else {
        throw DecodingError.typeMismatch(
          Any.self,
          DecodingError.Context(
            codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
      }
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      if let intValue = value as? Int {
        try container.encode(intValue)
      } else if let stringValue = value as? String {
        try container.encode(stringValue)
      } else if let doubleValue = value as? Double {
        try container.encode(doubleValue)
      } else {
        throw EncodingError.invalidValue(
          value,
          EncodingError.Context(
            codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
      }
    }
  }
}

// MARK: - Debounce Manager
class DebounceManager {
  private var timers: [String: Timer] = [:]

  func debounce(key: String, delay: TimeInterval, action: @escaping () -> Void) {
    timers[key]?.invalidate()
    timers[key] = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
      action()
      self.timers.removeValue(forKey: key)
    }
  }
}

// MARK: - AI Errors
enum AIError: LocalizedError {
  case invalidURL
  case encodingError(Error)
  case invalidResponse
  case apiError(Int, String)
  case noResponse
  case decodingError(Error)
  case templateNotFound

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid API URL"
    case .encodingError(let error):
      return "Failed to encode request: \(error.localizedDescription)"
    case .invalidResponse:
      return "Invalid response from server"
    case .apiError(let statusCode, let message):
      return "API Error \(statusCode): \(message)"
    case .noResponse:
      return "No response from AI model"
    case .decodingError(let error):
      return "Failed to decode response: \(error.localizedDescription)"
    case .templateNotFound:
      return "Exercise template not found"
    }
  }
}
