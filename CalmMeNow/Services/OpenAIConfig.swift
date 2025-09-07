//
//  OpenAIConfig.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import Foundation

struct OpenAIConfig {
  // MARK: - API Configuration
  static let baseURL = "https://api.openai.com/v1"
  static let model = "gpt-4o-mini"
  static let maxTokens = 150
  static let maxTokensMinimal = 50  // For minimal classification tasks
  static let temperature = 0.3  // Lower for more consistent JSON
  static let temperatureMinimal = 0.1  // Very low for classification

  // MARK: - API Key Management
  static var apiKey: String {
    // Get from environment variables (your .env file) - users never see this
    if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
      return envKey
    }
    // For production, you can hardcode your API key here
    // Users will never see or input this
    return "sk-your-production-api-key-here"  // Replace with your actual key
  }

  static var organizationID: String? {
    // First try to get from environment variables (for development)
    if let envOrgID = ProcessInfo.processInfo.environment["OPENAI_ORGANIZATION_ID"],
      !envOrgID.isEmpty
    {
      return envOrgID
    }
    // Fallback to UserDefaults (for production)
    return UserDefaults.standard.string(forKey: "openai_org_id")
  }

  // MARK: - Headers
  static var headers: [String: String] {
    var headers = [
      "Authorization": "Bearer \(apiKey)",
      "Content-Type": "application/json",
    ]

    if let orgID = organizationID {
      headers["OpenAI-Organization"] = orgID
    }

    return headers
  }

  // MARK: - Validation
  // AI is always available - no user configuration needed

  // MARK: - Setup Methods
  // These methods are not needed - AI works automatically for users
}
