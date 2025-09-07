//
//  AICacheManager.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import CryptoKit
import Foundation

// MARK: - Cache Models
struct CacheKey: Hashable {
  let feature: String
  let moodBucket: String
  let tags: [String]
  let intensity: Int
  let language: String

  var signature: String {
    let sortedTags = tags.sorted().joined(separator: ",")
    return "\(feature)_\(moodBucket)_\(sortedTags)_\(intensity)_\(language)"
  }
}

struct CachedResponse: Codable {
  let data: Data
  let timestamp: Date
  let userId: String?

  var isExpired: Bool {
    Date().timeIntervalSince(timestamp) > 3600  // 1 hour expiry
  }
}

// MARK: - AI Cache Manager
class AICacheManager: ObservableObject {
  static let shared = AICacheManager()

  private var cache: [String: CachedResponse] = [:]
  private let cacheQueue = DispatchQueue(label: "ai.cache.queue", attributes: .concurrent)
  private let maxCacheSize = 1000

  private init() {
    loadCacheFromDisk()
  }

  // MARK: - Cache Operations

  func getCachedResponse(for key: CacheKey, userId: String? = nil) -> Data? {
    return cacheQueue.sync {
      guard let cached = cache[key.signature],
        !cached.isExpired,
        cached.userId == userId || cached.userId == nil
      else {
        return nil
      }
      return cached.data
    }
  }

  func setCachedResponse(_ data: Data, for key: CacheKey, userId: String? = nil) {
    cacheQueue.async(flags: .barrier) {
      // Clean expired entries
      self.cleanExpiredEntries()

      // Limit cache size
      if self.cache.count >= self.maxCacheSize {
        self.evictOldestEntries()
      }

      self.cache[key.signature] = CachedResponse(
        data: data,
        timestamp: Date(),
        userId: userId
      )

      self.saveCacheToDisk()
    }
  }

  func clearCache(for userId: String? = nil) {
    cacheQueue.async(flags: .barrier) {
      if let userId = userId {
        self.cache = self.cache.filter { $0.value.userId != userId }
      } else {
        self.cache.removeAll()
      }
      self.saveCacheToDisk()
    }
  }

  // MARK: - Similarity Cache

  func findSimilarCachedResponse(for key: CacheKey, userId: String? = nil, threshold: Double = 0.9)
    -> Data?
  {
    return cacheQueue.sync {
      let currentSignature = key.signature

      for (signature, cached) in cache {
        guard !cached.isExpired,
          cached.userId == userId || cached.userId == nil,
          signature != currentSignature
        else {
          continue
        }

        let similarity = calculateSimilarity(currentSignature, signature)
        if similarity >= threshold {
          return cached.data
        }
      }

      return nil
    }
  }

  // MARK: - Private Methods

  private func cleanExpiredEntries() {
    cache = cache.filter { !$0.value.isExpired }
  }

  private func evictOldestEntries() {
    let sortedEntries = cache.sorted { $0.value.timestamp < $1.value.timestamp }
    let entriesToRemove = sortedEntries.prefix(cache.count - maxCacheSize + 100)

    for (key, _) in entriesToRemove {
      cache.removeValue(forKey: key)
    }
  }

  private func calculateSimilarity(_ sig1: String, _ sig2: String) -> Double {
    // Simple similarity based on common components
    let components1 = Set(sig1.components(separatedBy: "_"))
    let components2 = Set(sig2.components(separatedBy: "_"))

    let intersection = components1.intersection(components2)
    let union = components1.union(components2)

    return Double(intersection.count) / Double(union.count)
  }

  private func loadCacheFromDisk() {
    guard let data = UserDefaults.standard.data(forKey: "ai_cache"),
      let decoded = try? JSONDecoder().decode([String: CachedResponse].self, from: data)
    else {
      return
    }

    cacheQueue.async(flags: .barrier) {
      self.cache = decoded
      self.cleanExpiredEntries()
    }
  }

  private func saveCacheToDisk() {
    guard let data = try? JSONEncoder().encode(cache) else { return }
    UserDefaults.standard.set(data, forKey: "ai_cache")
  }
}

// MARK: - Cache Key Extensions
extension CacheKey {
  static func forDailyCheckIn(
    moodBucket: String, tags: [String], intensity: Int, language: String = "en"
  ) -> CacheKey {
    return CacheKey(
      feature: "daily_checkin",
      moodBucket: moodBucket,
      tags: tags,
      intensity: intensity,
      language: language
    )
  }

  static func forPanicPlan(
    moodBucket: String, tags: [String], intensity: Int, language: String = "en"
  ) -> CacheKey {
    return CacheKey(
      feature: "panic_plan",
      moodBucket: moodBucket,
      tags: tags,
      intensity: intensity,
      language: language
    )
  }

  static func forBreathingExercise(
    moodBucket: String, tags: [String], intensity: Int, language: String = "en"
  ) -> CacheKey {
    return CacheKey(
      feature: "breathing_exercise",
      moodBucket: moodBucket,
      tags: tags,
      intensity: intensity,
      language: language
    )
  }
}
