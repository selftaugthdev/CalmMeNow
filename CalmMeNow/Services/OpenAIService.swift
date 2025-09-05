//
//  OpenAIService.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import Foundation

// MARK: - OpenAI Models
struct OpenAIRequest: Codable {
  let model: String
  let messages: [OpenAIMessage]
  let maxTokens: Int
  let temperature: Double

  enum CodingKeys: String, CodingKey {
    case model, messages, temperature
    case maxTokens = "max_tokens"
  }
}

struct OpenAIMessage: Codable {
  let role: String
  let content: String
}

struct OpenAIResponse: Codable {
  let choices: [Choice]
  let usage: Usage?
}

struct Choice: Codable {
  let message: OpenAIMessage
  let finishReason: String?

  enum CodingKeys: String, CodingKey {
    case message
    case finishReason = "finish_reason"
  }
}

struct Usage: Codable {
  let promptTokens: Int
  let completionTokens: Int
  let totalTokens: Int

  enum CodingKeys: String, CodingKey {
    case promptTokens = "prompt_tokens"
    case completionTokens = "completion_tokens"
    case totalTokens = "total_tokens"
  }
}

// MARK: - OpenAI Service
class OpenAIService: ObservableObject {
  static let shared = OpenAIService()

  @Published var isLoading = false
  @Published var lastError: String?

  private init() {}

  // MARK: - Main Chat Completion
  func sendMessage(_ message: String, systemPrompt: String? = nil) async throws -> String {
    // AI is automatically configured - no user setup needed

    let messages = buildMessages(userMessage: message, systemPrompt: systemPrompt)

    let request = OpenAIRequest(
      model: OpenAIConfig.model,
      messages: messages,
      maxTokens: OpenAIConfig.maxTokens,
      temperature: OpenAIConfig.temperature
    )

    return try await performRequest(request)
  }

  // MARK: - Calm-Specific AI Features

  /// Generate personalized calming advice based on user's emotion
  func generateCalmingAdvice(for emotion: String, intensity: String) async throws -> String {
    let prompt = """
      You are a compassionate mental health companion. The user is feeling \(emotion) with \(intensity) intensity.
      Provide a brief, gentle, and practical calming suggestion in 1-2 sentences.
      Be supportive and actionable. Focus on immediate relief techniques.
      """

    return try await sendMessage("I need help calming down", systemPrompt: prompt)
  }

  /// Generate personalized breathing exercise instructions
  func generateBreathingInstructions(for emotion: String) async throws -> String {
    let prompt = """
      You are a breathing exercise expert. The user is feeling \(emotion).
      Provide a simple, calming breathing pattern instruction in 1-2 sentences.
      Include specific counts (like "inhale for 4, hold for 4, exhale for 6").
      Make it gentle and accessible.
      """

    return try await sendMessage("I need breathing help", systemPrompt: prompt)
  }

  /// Generate personalized journaling prompts
  func generateJournalingPrompt(for emotion: String, context: String? = nil) async throws -> String
  {
    let contextText = context ?? "general reflection"
    let prompt = """
      You are a therapeutic journaling guide. The user is feeling \(emotion) and wants to \(contextText).
      Create a gentle, reflective journaling prompt in 1-2 sentences.
      Make it open-ended and non-judgmental. Focus on self-compassion.
      """

    return try await sendMessage("I need a journaling prompt", systemPrompt: prompt)
  }

  /// Generate emergency calm strategies
  func generateEmergencyCalmStrategies(for situation: String) async throws -> String {
    let prompt = """
      You are an emergency mental health responder. The user is in crisis: \(situation).
      Provide 2-3 immediate, practical calming strategies in 2-3 sentences.
      Focus on immediate safety and grounding techniques.
      Be direct but gentle. If this seems like a medical emergency, suggest professional help.
      """

    return try await sendMessage("I need emergency help", systemPrompt: prompt)
  }

  // MARK: - Private Methods
  private func buildMessages(userMessage: String, systemPrompt: String?) -> [OpenAIMessage] {
    var messages: [OpenAIMessage] = []

    if let systemPrompt = systemPrompt {
      messages.append(OpenAIMessage(role: "system", content: systemPrompt))
    }

    messages.append(OpenAIMessage(role: "user", content: userMessage))
    return messages
  }

  private func performRequest(_ request: OpenAIRequest) async throws -> String {
    guard let url = URL(string: "\(OpenAIConfig.baseURL)/chat/completions") else {
      throw OpenAIError.invalidURL
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.allHTTPHeaderFields = OpenAIConfig.headers

    do {
      let jsonData = try JSONEncoder().encode(request)
      urlRequest.httpBody = jsonData
    } catch {
      throw OpenAIError.encodingError(error)
    }

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw OpenAIError.invalidResponse
    }

    guard httpResponse.statusCode == 200 else {
      let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
      throw OpenAIError.apiError(httpResponse.statusCode, errorMessage)
    }

    do {
      let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
      guard let firstChoice = openAIResponse.choices.first else {
        throw OpenAIError.noResponse
      }

      return firstChoice.message.content
    } catch {
      throw OpenAIError.decodingError(error)
    }
  }
}

// MARK: - OpenAI Errors
enum OpenAIError: LocalizedError {
  case invalidURL
  case encodingError(Error)
  case invalidResponse
  case apiError(Int, String)
  case noResponse
  case decodingError(Error)

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
    }
  }
}
