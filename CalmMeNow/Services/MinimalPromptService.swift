//
//  MinimalPromptService.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import Foundation

// MARK: - Minimal Prompt Templates
struct MinimalPrompt {
  let id: String
  let systemPrompt: String
  let userTemplate: String
  let expectedResponseFormat: ResponseFormat
  let maxTokens: Int
  let temperature: Double
}

enum ResponseFormat {
  case json
  case exerciseId
  case classification
  case simpleText
}

// MARK: - Minimal Prompt Service
class MinimalPromptService {
  static let shared = MinimalPromptService()

  private let prompts: [String: MinimalPrompt]

  private init() {
    self.prompts = Self.loadMinimalPrompts()
  }

  // MARK: - Prompt Access

  func getPrompt(id: String) -> MinimalPrompt? {
    return prompts[id]
  }

  func buildRequest(promptId: String, parameters: [String: String]) -> (
    systemPrompt: String, userMessage: String, maxTokens: Int, temperature: Double
  )? {
    guard let prompt = getPrompt(id: promptId) else { return nil }

    var userMessage = prompt.userTemplate
    for (key, value) in parameters {
      userMessage = userMessage.replacingOccurrences(of: "{{\(key)}}", with: value)
    }

    return (
      systemPrompt: prompt.systemPrompt,
      userMessage: userMessage,
      maxTokens: prompt.maxTokens,
      temperature: prompt.temperature
    )
  }

  // MARK: - Prompt Loading

  private static func loadMinimalPrompts() -> [String: MinimalPrompt] {
    var prompts: [String: MinimalPrompt] = [:]

    // Exercise Classification (Ultra-minimal)
    prompts["exercise_classifier"] = MinimalPrompt(
      id: "exercise_classifier",
      systemPrompt: "Router. Return JSON only.",
      userTemplate: "mood:{{mood}} intensity:{{intensity}} tags:{{tags}}",
      expectedResponseFormat: .json,
      maxTokens: 30,
      temperature: 0.1
    )

    // Breathing Pattern Selection
    prompts["breathing_pattern"] = MinimalPrompt(
      id: "breathing_pattern",
      systemPrompt: "Return JSON: {pattern:\"4-2-6\",duration:60}",
      userTemplate: "{{mood}} {{intensity}}",
      expectedResponseFormat: .json,
      maxTokens: 25,
      temperature: 0.1
    )

    // Emergency Classification
    prompts["emergency_check"] = MinimalPrompt(
      id: "emergency_check",
      systemPrompt: "Return JSON: {emergency:true/false,level:1-3}",
      userTemplate: "{{description}}",
      expectedResponseFormat: .json,
      maxTokens: 20,
      temperature: 0.0
    )

    // Exercise ID Selection
    prompts["exercise_id"] = MinimalPrompt(
      id: "exercise_id",
      systemPrompt: "Return exercise ID only.",
      userTemplate: "{{mood}} {{tags}}",
      expectedResponseFormat: .exerciseId,
      maxTokens: 15,
      temperature: 0.1
    )

    // Simple Note Generation
    prompts["personalized_note"] = MinimalPrompt(
      id: "personalized_note",
      systemPrompt: "Brief note, max 80 chars.",
      userTemplate: "{{exercise}} for {{mood}}",
      expectedResponseFormat: .simpleText,
      maxTokens: 20,
      temperature: 0.3
    )

    return prompts
  }
}

// MARK: - Optimized Request Builder
class OptimizedRequestBuilder {
  static let shared = OptimizedRequestBuilder()

  private let promptService = MinimalPromptService.shared

  private init() {}

  // MARK: - Request Building

  func buildExerciseClassificationRequest(
    moodBucket: String,
    intensity: Int,
    tags: [String]
  ) -> OpenAIRequest? {

    let parameters = [
      "mood": moodBucket,
      "intensity": String(intensity),
      "tags": tags.joined(separator: ","),
    ]

    guard
      let request = promptService.buildRequest(
        promptId: "exercise_classifier",
        parameters: parameters
      )
    else { return nil }

    return OpenAIRequest(
      model: OpenAIConfig.model,
      messages: [
        OpenAIMessage(role: "system", content: request.systemPrompt),
        OpenAIMessage(role: "user", content: request.userMessage),
      ],
      maxTokens: request.maxTokens,
      temperature: request.temperature
    )
  }

  func buildBreathingPatternRequest(
    moodBucket: String,
    intensity: Int
  ) -> OpenAIRequest? {

    let parameters = [
      "mood": moodBucket,
      "intensity": String(intensity),
    ]

    guard
      let request = promptService.buildRequest(
        promptId: "breathing_pattern",
        parameters: parameters
      )
    else { return nil }

    return OpenAIRequest(
      model: OpenAIConfig.model,
      messages: [
        OpenAIMessage(role: "system", content: request.systemPrompt),
        OpenAIMessage(role: "user", content: request.userMessage),
      ],
      maxTokens: request.maxTokens,
      temperature: request.temperature
    )
  }

  func buildEmergencyCheckRequest(description: String) -> OpenAIRequest? {
    let parameters = ["description": description]

    guard
      let request = promptService.buildRequest(
        promptId: "emergency_check",
        parameters: parameters
      )
    else { return nil }

    return OpenAIRequest(
      model: OpenAIConfig.model,
      messages: [
        OpenAIMessage(role: "system", content: request.systemPrompt),
        OpenAIMessage(role: "user", content: request.userMessage),
      ],
      maxTokens: request.maxTokens,
      temperature: request.temperature
    )
  }

  func buildPersonalizedNoteRequest(
    exerciseId: String,
    moodBucket: String
  ) -> OpenAIRequest? {

    let parameters = [
      "exercise": exerciseId,
      "mood": moodBucket,
    ]

    guard
      let request = promptService.buildRequest(
        promptId: "personalized_note",
        parameters: parameters
      )
    else { return nil }

    return OpenAIRequest(
      model: OpenAIConfig.model,
      messages: [
        OpenAIMessage(role: "system", content: request.systemPrompt),
        OpenAIMessage(role: "user", content: request.userMessage),
      ],
      maxTokens: request.maxTokens,
      temperature: request.temperature
    )
  }
}

// MARK: - Local Text Lookup
class LocalTextManager {
  static let shared = LocalTextManager()

  private let localizedTexts: [String: [String: String]]

  private init() {
    self.localizedTexts = Self.loadLocalizedTexts()
  }

  func getText(for key: String, language: String = "en") -> String {
    return localizedTexts[language]?[key] ?? localizedTexts["en"]?[key] ?? key
  }

  func getExerciseText(exerciseId: String, language: String = "en") -> (
    title: String, steps: [String]
  )? {
    let titleKey = "exercise_\(exerciseId)_title"
    let stepsKey = "exercise_\(exerciseId)_steps"

    let title = getText(for: titleKey, language: language)
    let stepsText = getText(for: stepsKey, language: language)

    let steps = stepsText.components(separatedBy: "|")
    return (title: title, steps: steps)
  }

  private static func loadLocalizedTexts() -> [String: [String: String]] {
    return [
      "en": [
        // Exercise titles
        "exercise_breath_4_2_6_title": "4-2-6 Breathing",
        "exercise_breath_box_title": "Box Breathing",
        "exercise_grounding_54321_title": "5-4-3-2-1 Grounding",
        "exercise_grounding_body_scan_title": "Body Scan Grounding",
        "exercise_stretch_neck_title": "Neck and Shoulder Release",
        "exercise_mindfulness_breath_title": "Mindful Breathing",
        "exercise_emergency_ice_title": "Ice Cube Technique",
        "exercise_emergency_urge_surfing_title": "Urge Surfing",

        // Exercise steps
        "exercise_breath_4_2_6_steps":
          "Sit comfortably with your back straight|Inhale slowly through your nose for 4 counts|Hold your breath for 2 counts|Exhale slowly through your mouth for 6 counts|Repeat this cycle 5-10 times",
        "exercise_breath_box_steps":
          "Sit in a comfortable position|Inhale for 4 counts|Hold for 4 counts|Exhale for 4 counts|Hold empty for 4 counts|Repeat the box pattern 8-10 times",
        "exercise_grounding_54321_steps":
          "Name 5 things you can see around you|Name 4 things you can touch|Name 3 things you can hear|Name 2 things you can smell|Name 1 thing you can taste",

        // Personalized notes
        "note_anxious": "Focus on slow, deep breaths to calm your nervous system.",
        "note_angry": "Use this exercise to release tension and find your center.",
        "note_sad": "This gentle practice can help lift your spirits.",
        "note_stressed": "Take your time and focus on the present moment.",
        "note_tired": "This will help energize and refresh you.",
      ]
    ]
  }
}

// MARK: - Ultra-Minimal AI Service
class UltraMinimalAIService: ObservableObject {
  static let shared = UltraMinimalAIService()

  @Published var isLoading = false
  @Published var lastError: String?

  private let requestBuilder = OptimizedRequestBuilder.shared
  private let textManager = LocalTextManager.shared
  private let monitoringService = AIMonitoringService.shared

  private init() {}

  // MARK: - Ultra-Minimal Requests

  func getExerciseClassification(
    moodBucket: String,
    intensity: Int,
    tags: [String]
  ) async throws -> ExerciseClassification {

    guard
      let request = requestBuilder.buildExerciseClassificationRequest(
        moodBucket: moodBucket,
        intensity: intensity,
        tags: tags
      )
    else {
      throw AIError.invalidRequest
    }

    let response = try await performRequest(request)

    guard let data = response.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let exercise = json["exercise"] as? String,
      let params = json["params"] as? [String: Any]
    else {
      throw AIError.invalidResponse
    }

    // Track minimal usage
    monitoringService.trackUsage(
      feature: "classification",
      model: OpenAIConfig.model,
      promptTokens: estimateTokens(request),
      completionTokens: estimateTokens(response)
    )

    return ExerciseClassification(
      exercise: exercise,
      parameters: params,
      note: json["note"] as? String
    )
  }

  func getPersonalizedNote(
    exerciseId: String,
    moodBucket: String
  ) async throws -> String {

    // Try local lookup first
    let localNote = textManager.getText(for: "note_\(moodBucket)")
    if !localNote.isEmpty {
      return localNote
    }

    // Fallback to minimal AI call
    guard
      let request = requestBuilder.buildPersonalizedNoteRequest(
        exerciseId: exerciseId,
        moodBucket: moodBucket
      )
    else {
      return "Take your time and focus on the present moment."
    }

    let response = try await performRequest(request)

    // Track minimal usage
    monitoringService.trackUsage(
      feature: "personalization",
      model: OpenAIConfig.model,
      promptTokens: estimateTokens(request),
      completionTokens: estimateTokens(response)
    )

    return response.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  // MARK: - Private Methods

  private func performRequest(_ request: OpenAIRequest) async throws -> String {
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

  private func estimateTokens(_ text: String) -> Int {
    return max(1, text.count / 4)
  }

  private func estimateTokens(_ request: OpenAIRequest) -> Int {
    let totalText = request.messages.map { $0.content }.joined()
    return estimateTokens(totalText)
  }
}

// MARK: - Response Models
struct ExerciseClassification {
  let exercise: String
  let parameters: [String: Any]
  let note: String?
}

// MARK: - AI Error Extensions
extension AIError {
  static let invalidRequest = AIError.apiError(400, "Invalid request format")
}
