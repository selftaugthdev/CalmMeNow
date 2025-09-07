//
//  DeltaUpdateManager.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import Foundation

// MARK: - Delta Update Models
struct UserState {
  let moodBucket: String
  let intensity: Int
  let tags: [String]
  let timestamp: Date
  let userId: String?

  var signature: String {
    let sortedTags = tags.sorted().joined(separator: ",")
    return "\(moodBucket)_\(intensity)_\(sortedTags)"
  }
}

struct StateChange {
  let previousState: UserState?
  let currentState: UserState
  let changeType: ChangeType
  let requiresRegeneration: Bool
}

enum ChangeType {
  case moodBucketChange
  case intensityChange
  case tagsChange
  case minorChange
  case majorChange
  case newSession
}

// MARK: - Delta Update Manager
class DeltaUpdateManager: ObservableObject {
  static let shared = DeltaUpdateManager()

  private var userStates: [String: UserState] = [:]  // userId -> current state
  private let intensityThreshold = 3  // Changes within this range are minor
  private let moodBucketThresholds = [
    "low": (min: 1, max: 3),
    "med": (min: 4, max: 6),
    "high": (min: 7, max: 10),
  ]

  private init() {}

  // MARK: - State Management

  func updateUserState(
    userId: String,
    moodBucket: String,
    intensity: Int,
    tags: [String]
  ) -> StateChange {

    let currentState = UserState(
      moodBucket: moodBucket,
      intensity: intensity,
      tags: tags,
      timestamp: Date(),
      userId: userId
    )

    let previousState = userStates[userId]
    let changeType = determineChangeType(previous: previousState, current: currentState)
    let requiresRegeneration = shouldRegenerate(
      changeType: changeType, previous: previousState, current: currentState)

    let stateChange = StateChange(
      previousState: previousState,
      currentState: currentState,
      changeType: changeType,
      requiresRegeneration: requiresRegeneration
    )

    userStates[userId] = currentState

    return stateChange
  }

  func getCurrentState(for userId: String) -> UserState? {
    return userStates[userId]
  }

  func clearUserState(for userId: String) {
    userStates.removeValue(forKey: userId)
  }

  // MARK: - Change Detection

  private func determineChangeType(previous: UserState?, current: UserState) -> ChangeType {
    guard let previous = previous else {
      return .newSession
    }

    // Check if mood bucket changed
    if previous.moodBucket != current.moodBucket {
      return .moodBucketChange
    }

    // Check if intensity changed significantly
    let intensityDiff = abs(previous.intensity - current.intensity)
    if intensityDiff >= intensityThreshold {
      return .intensityChange
    }

    // Check if tags changed significantly
    let previousTags = Set(previous.tags)
    let currentTags = Set(current.tags)
    let tagDiff = previousTags.symmetricDifference(currentTags)

    if tagDiff.count > 2 {  // More than 2 tags changed
      return .tagsChange
    }

    // Minor changes
    if intensityDiff > 0 || !tagDiff.isEmpty {
      return .minorChange
    }

    return .minorChange
  }

  private func shouldRegenerate(changeType: ChangeType, previous: UserState?, current: UserState)
    -> Bool
  {
    switch changeType {
    case .newSession:
      return true

    case .moodBucketChange:
      return true

    case .intensityChange:
      // Only regenerate if crossing mood bucket thresholds
      return hasCrossedMoodBucketThreshold(previous: previous, current: current)

    case .tagsChange:
      // Regenerate if critical tags changed
      return hasCriticalTagChange(previous: previous, current: current)

    case .minorChange:
      return false

    case .majorChange:
      return true
    }
  }

  private func hasCrossedMoodBucketThreshold(previous: UserState?, current: UserState) -> Bool {
    guard let previous = previous else { return true }

    let previousBucket = getMoodBucket(for: previous.intensity)
    let currentBucket = getMoodBucket(for: current.intensity)

    return previousBucket != currentBucket
  }

  private func hasCriticalTagChange(previous: UserState?, current: UserState) -> Bool {
    guard let previous = previous else { return true }

    let criticalTags = ["panic", "crisis", "emergency", "suicidal", "self-harm"]

    let previousCritical = Set(previous.tags).intersection(Set(criticalTags))
    let currentCritical = Set(current.tags).intersection(Set(criticalTags))

    return !previousCritical.symmetricDifference(currentCritical).isEmpty
  }

  private func getMoodBucket(for intensity: Int) -> String {
    switch intensity {
    case 1...3: return "low"
    case 4...6: return "med"
    case 7...10: return "high"
    default: return "med"
    }
  }

  // MARK: - Delta Update Logic

  func getDeltaUpdate(
    for userId: String,
    newMoodBucket: String,
    newIntensity: Int,
    newTags: [String]
  ) -> DeltaUpdateResult {

    let stateChange = updateUserState(
      userId: userId,
      moodBucket: newMoodBucket,
      intensity: newIntensity,
      tags: newTags
    )

    if stateChange.requiresRegeneration {
      return DeltaUpdateResult(
        shouldRegenerate: true,
        reason: "\(stateChange.changeType) requires full regeneration",
        previousState: stateChange.previousState,
        currentState: stateChange.currentState
      )
    } else {
      return DeltaUpdateResult(
        shouldRegenerate: false,
        reason: "Minor change, using cached result",
        previousState: stateChange.previousState,
        currentState: stateChange.currentState
      )
    }
  }

  // MARK: - Smart Caching Integration

  func getCachedResultIfValid(
    for userId: String,
    moodBucket: String,
    intensity: Int,
    tags: [String]
  ) -> Bool {

    let stateChange = updateUserState(
      userId: userId,
      moodBucket: moodBucket,
      intensity: intensity,
      tags: tags
    )

    return !stateChange.requiresRegeneration
  }
}

// MARK: - Delta Update Result
struct DeltaUpdateResult {
  let shouldRegenerate: Bool
  let reason: String
  let previousState: UserState?
  let currentState: UserState
}

// MARK: - Integration with Optimized AI Service
extension OptimizedAIService {

  func getExerciseRecommendationWithDelta(
    userId: String,
    moodBucket: String,
    intensity: Int,
    tags: [String],
    language: String = "en"
  ) async throws -> ExerciseRecommendation {

    let deltaManager = DeltaUpdateManager.shared
    let deltaResult = deltaManager.getDeltaUpdate(
      for: userId,
      newMoodBucket: moodBucket,
      newIntensity: intensity,
      newTags: tags
    )

    if !deltaResult.shouldRegenerate {
      // Try to get cached result
      let cacheKey = CacheKey.forDailyCheckIn(
        moodBucket: deltaResult.previousState?.moodBucket ?? moodBucket,
        tags: deltaResult.previousState?.tags ?? tags,
        intensity: deltaResult.previousState?.intensity ?? intensity,
        language: language
      )

      if let cachedData = cacheManager.getCachedResponse(for: cacheKey, userId: userId),
        let cached = try? JSONDecoder().decode(ExerciseRecommendation.self, from: cachedData)
      {
        return cached
      }
    }

    // Generate new recommendation
    return try await getExerciseRecommendation(
      moodBucket: moodBucket,
      intensity: intensity,
      tags: tags,
      userId: userId,
      language: language
    )
  }
}

// MARK: - UI Integration Helper
class DeltaAwareViewModel: ObservableObject {
  @Published var currentMoodBucket = "med"
  @Published var currentIntensity = 5
  @Published var currentTags: [String] = []
  @Published var lastRecommendation: ExerciseRecommendation?
  @Published var isGenerating = false

  private let aiService = OptimizedAIService.shared
  private let deltaManager = DeltaUpdateManager.shared
  private var userId: String?

  func updateMoodBucket(_ bucket: String) {
    currentMoodBucket = bucket
    generateRecommendationIfNeeded()
  }

  func updateIntensity(_ intensity: Int) {
    currentIntensity = intensity
    generateRecommendationIfNeeded()
  }

  func updateTags(_ tags: [String]) {
    currentTags = tags
    generateRecommendationIfNeeded()
  }

  private func generateRecommendationIfNeeded() {
    guard let userId = userId else { return }

    let deltaResult = deltaManager.getDeltaUpdate(
      for: userId,
      newMoodBucket: currentMoodBucket,
      newIntensity: currentIntensity,
      newTags: currentTags
    )

    if deltaResult.shouldRegenerate {
      Task {
        await generateNewRecommendation()
      }
    }
  }

  private func generateNewRecommendation() async {
    guard let userId = userId else { return }

    isGenerating = true

    do {
      let recommendation = try await aiService.getExerciseRecommendationWithDelta(
        userId: userId,
        moodBucket: currentMoodBucket,
        intensity: currentIntensity,
        tags: currentTags
      )

      await MainActor.run {
        self.lastRecommendation = recommendation
        self.isGenerating = false
      }
    } catch {
      await MainActor.run {
        self.isGenerating = false
      }
    }
  }
}
