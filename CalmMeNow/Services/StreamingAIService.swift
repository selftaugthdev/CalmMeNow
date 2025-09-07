//
//  StreamingAIService.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import Foundation

// MARK: - Streaming Response Models
struct StreamingResponse {
  let id: String
  let object: String
  let created: Int
  let model: String
  let choices: [StreamingChoice]
}

struct StreamingChoice {
  let index: Int
  let delta: StreamingDelta
  let finishReason: String?
}

struct StreamingDelta {
  let role: String?
  let content: String?
}

// MARK: - JSON Parser for Early Stopping
class JSONStreamParser {
  private var buffer = ""
  private var isComplete = false
  private var parsedObject: [String: Any] = [:]

  func appendChunk(_ chunk: String) -> (isComplete: Bool, parsedObject: [String: Any]?) {
    buffer += chunk

    // Try to parse JSON incrementally
    if let jsonObject = tryParseJSON() {
      isComplete = true
      return (true, jsonObject)
    }

    return (false, nil)
  }

  private func tryParseJSON() -> [String: Any]? {
    // Look for complete JSON objects in the buffer
    let lines = buffer.components(separatedBy: "\n")

    for line in lines {
      if line.hasPrefix("data: ") {
        let jsonString = String(line.dropFirst(6))

        if jsonString == "[DONE]" {
          return parsedObject
        }

        guard let data = jsonString.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let choices = json["choices"] as? [[String: Any]],
          let firstChoice = choices.first,
          let delta = firstChoice["delta"] as? [String: Any],
          let content = delta["content"] as? String
        else {
          continue
        }

        // Accumulate content
        if parsedObject["content"] == nil {
          parsedObject["content"] = ""
        }
        parsedObject["content"] = (parsedObject["content"] as? String ?? "") + content

        // Check if we have enough to parse the final JSON
        if let accumulatedContent = parsedObject["content"] as? String,
          let finalJSON = tryParseFinalJSON(from: accumulatedContent)
        {
          return finalJSON
        }
      }
    }

    return nil
  }

  private func tryParseFinalJSON(from content: String) -> [String: Any]? {
    // Try to extract JSON from the accumulated content
    if let jsonData = content.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
    {
      return json
    }

    // Look for JSON-like patterns in the content
    let jsonPattern = "\\{[^}]*\\}"
    let regex = try? NSRegularExpression(pattern: jsonPattern)
    let range = NSRange(location: 0, length: content.utf16.count)

    if let match = regex?.firstMatch(in: content, options: [], range: range) {
      let jsonString = (content as NSString).substring(with: match.range)
      if let jsonData = jsonString.data(using: .utf8),
        let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
      {
        return json
      }
    }

    return nil
  }
}

// MARK: - Streaming AI Service
class StreamingAIService: ObservableObject {
  static let shared = StreamingAIService()

  @Published var isStreaming = false
  @Published var streamedContent = ""
  @Published var lastError: String?

  private let monitoringService = AIMonitoringService.shared
  private let retryManager = AIRetryManager.shared

  private init() {}

  // MARK: - Streaming Request

  func streamRequest(
    prompt: String,
    model: String = OpenAIConfig.model,
    maxTokens: Int = OpenAIConfig.maxTokens,
    temperature: Double = OpenAIConfig.temperature,
    onComplete: @escaping ([String: Any]?) -> Void
  ) async throws {

    let requestId = UUID().uuidString

    // Check quota before making request
    guard monitoringService.canMakeRequest(feature: "streaming", model: model) else {
      throw AIError.quotaExceeded
    }

    isStreaming = true
    streamedContent = ""

    do {
      try await performStreamingRequest(
        prompt: prompt,
        model: model,
        maxTokens: maxTokens,
        temperature: temperature,
        requestId: requestId,
        onComplete: onComplete
      )

      retryManager.resetRetryCount(requestId: requestId)

    } catch {
      if retryManager.shouldRetry(requestId: requestId) {
        retryManager.incrementRetryCount(requestId: requestId)
        let delay = retryManager.getRetryDelay(requestId: requestId)

        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        try await performStreamingRequest(
          prompt: prompt,
          model: model,
          maxTokens: maxTokens,
          temperature: temperature,
          requestId: requestId,
          onComplete: onComplete
        )
      } else {
        throw error
      }
    }

    isStreaming = false
  }

  private func performStreamingRequest(
    prompt: String,
    model: String,
    maxTokens: Int,
    temperature: Double,
    requestId: String,
    onComplete: @escaping ([String: Any]?) -> Void
  ) async throws {

    guard let url = URL(string: "\(OpenAIConfig.baseURL)/chat/completions") else {
      throw AIError.invalidURL
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.allHTTPHeaderFields = OpenAIConfig.headers

    let requestBody: [String: Any] = [
      "model": model,
      "messages": [["role": "user", "content": prompt]],
      "max_tokens": maxTokens,
      "temperature": temperature,
      "stream": true,
    ]

    do {
      let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
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

    // Process streaming response
    let responseString = String(data: data, encoding: .utf8) ?? ""
    let parser = JSONStreamParser()

    let lines = responseString.components(separatedBy: "\n")
    var finalJSON: [String: Any]?

    for line in lines {
      let (isComplete, parsedObject) = parser.appendChunk(line + "\n")

      if isComplete, let json = parsedObject {
        finalJSON = json
        break
      }

      // Update UI with partial content
      await MainActor.run {
        if let content = parsedObject?["content"] as? String {
          self.streamedContent = content
        }
      }
    }

    // Track usage
    let estimatedTokens = estimateTokenCount(prompt + streamedContent)
    monitoringService.trackUsage(
      feature: "streaming",
      model: model,
      promptTokens: estimateTokenCount(prompt),
      completionTokens: estimateTokenCount(streamedContent)
    )

    onComplete(finalJSON)
  }

  // MARK: - Optimized Streaming for Exercise Recommendations

  func streamExerciseRecommendation(
    moodBucket: String,
    intensity: Int,
    tags: [String],
    onComplete: @escaping (ExerciseRecommendation?) -> Void
  ) async throws {

    let prompt = """
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

    try await streamRequest(
      prompt: prompt,
      model: OpenAIConfig.model,
      maxTokens: OpenAIConfig.maxTokensMinimal,
      temperature: OpenAIConfig.temperatureMinimal
    ) { json in

      guard let json = json,
        let exercise = json["exercise"] as? String,
        let params = json["params"] as? [String: Any]
      else {
        onComplete(nil)
        return
      }

      // Convert to ExerciseRecommendation using templates
      let templateManager = ExerciseTemplateManager.shared
      let category = ExerciseCategory(rawValue: exercise) ?? .breathing

      if let template = templateManager.getRandomTemplate(for: category) {
        let recommendation = ExerciseRecommendation(
          exerciseId: template.id,
          title: template.title,
          steps: template.steps,
          duration: template.duration,
          parameters: template.parameters.mapValues { ExerciseRecommendation.AnyCodable($0) },
          note: json["note"] as? String
        )

        onComplete(recommendation)
      } else {
        onComplete(nil)
      }
    }
  }

  // MARK: - Utility Methods

  private func estimateTokenCount(_ text: String) -> Int {
    // Rough estimation: 1 token ≈ 4 characters for English text
    return max(1, text.count / 4)
  }
}

// MARK: - AI Error Extensions
extension AIError {
  static let quotaExceeded = AIError.apiError(429, "Quota exceeded")
}
