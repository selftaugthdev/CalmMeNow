//
//  PatternAnalysisService.swift
//  CalmMeNow
//
//  Analyzes journal entries to find patterns
//

import Foundation
import SwiftData

// MARK: - Analytics Insight Model

struct AnalyticsInsight: Identifiable {
  let id = UUID()
  let type: InsightType
  let title: String
  let description: String
  let confidence: Double  // 0.0 to 1.0
  let icon: String
  let color: String  // Hex color

  enum InsightType {
    case dayOfWeek
    case triggerFrequency
    case intensityTrend
    case timeOfDay
    case improvement
  }
}

// MARK: - Pattern Analysis Service

class PatternAnalysisService: ObservableObject {
  static let shared = PatternAnalysisService()

  @Published var insights: [AnalyticsInsight] = []
  @Published var isAnalyzing = false
  @Published var hasEnoughData = false

  private let minimumEntries = 7

  private init() {}

  // MARK: - Public Methods

  func analyzeEntries(_ entries: [JournalEntry]) {
    isAnalyzing = true

    // Check if we have enough data
    hasEnoughData = entries.count >= minimumEntries

    guard hasEnoughData else {
      insights = []
      isAnalyzing = false
      return
    }

    var newInsights: [AnalyticsInsight] = []

    // Analyze day of week patterns
    if let dayInsight = analyzeDayOfWeekPattern(entries) {
      newInsights.append(dayInsight)
    }

    // Analyze trigger frequency
    if let triggerInsight = analyzeTriggerFrequency(entries) {
      newInsights.append(triggerInsight)
    }

    // Analyze intensity trends
    if let trendInsight = analyzeIntensityTrend(entries) {
      newInsights.append(trendInsight)
    }

    // Analyze time of day patterns
    if let timeInsight = analyzeTimeOfDayPattern(entries) {
      newInsights.append(timeInsight)
    }

    // Sort by confidence
    insights = newInsights.sorted { $0.confidence > $1.confidence }
    isAnalyzing = false
  }

  func getEntriesNeeded() -> Int {
    return minimumEntries
  }

  // MARK: - Analysis Methods

  private func analyzeDayOfWeekPattern(_ entries: [JournalEntry]) -> AnalyticsInsight? {
    let calendar = Calendar.current
    var dayCounts: [Int: Int] = [:]  // weekday (1-7) : count

    for entry in entries {
      let weekday = calendar.component(.weekday, from: entry.timestamp)
      dayCounts[weekday, default: 0] += 1
    }

    guard let maxDay = dayCounts.max(by: { $0.value < $1.value }),
      maxDay.value > 1
    else {
      return nil
    }

    let dayNames = [
      "", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
    ]
    let dayName = dayNames[maxDay.key]

    let totalEntries = entries.count
    let percentage = Double(maxDay.value) / Double(totalEntries)

    // Only show if there's a meaningful pattern (>20% on one day)
    guard percentage > 0.2 else { return nil }

    return AnalyticsInsight(
      type: .dayOfWeek,
      title: "\(dayName)s are common",
      description:
        "You tend to journal more on \(dayName)s (\(Int(percentage * 100))% of entries). Consider extra self-care on these days.",
      confidence: min(0.9, percentage + 0.3),
      icon: "calendar",
      color: "#4A9B8C"
    )
  }

  private func analyzeTriggerFrequency(_ entries: [JournalEntry]) -> AnalyticsInsight? {
    var triggerCounts: [String: Int] = [:]

    for entry in entries {
      if let factors = entry.contributingFactors {
        for factor in factors {
          triggerCounts[factor, default: 0] += 1
        }
      }
    }

    guard let topTrigger = triggerCounts.max(by: { $0.value < $1.value }),
      topTrigger.value > 1
    else {
      return nil
    }

    let percentage = Double(topTrigger.value) / Double(entries.count)

    return AnalyticsInsight(
      type: .triggerFrequency,
      title: "Top trigger: \(topTrigger.key)",
      description:
        "\"\(topTrigger.key)\" appears in \(Int(percentage * 100))% of your entries. Awareness of patterns helps you prepare.",
      confidence: min(0.85, percentage + 0.25),
      icon: "exclamationmark.triangle",
      color: "#E8A838"
    )
  }

  private func analyzeIntensityTrend(_ entries: [JournalEntry]) -> AnalyticsInsight? {
    // Sort entries by date
    let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }

    // Map intensity strings to numeric values
    let intensityMap: [String: Int] = [
      "mild": 1,
      "moderate": 2,
      "severe": 3,
      "extreme": 4,
    ]

    var intensityValues: [Int] = []
    for entry in sortedEntries {
      if let intensity = entry.intensity?.lowercased(),
        let value = intensityMap[intensity]
      {
        intensityValues.append(value)
      }
    }

    guard intensityValues.count >= 5 else { return nil }

    // Compare first half to second half
    let midpoint = intensityValues.count / 2
    let firstHalf = Array(intensityValues.prefix(midpoint))
    let secondHalf = Array(intensityValues.suffix(midpoint))

    let firstAvg = Double(firstHalf.reduce(0, +)) / Double(firstHalf.count)
    let secondAvg = Double(secondHalf.reduce(0, +)) / Double(secondHalf.count)

    let difference = firstAvg - secondAvg
    let percentChange = abs(difference / firstAvg * 100)

    if difference > 0.3 {
      // Improving
      return AnalyticsInsight(
        type: .improvement,
        title: "You're improving!",
        description:
          "Your average intensity has decreased by \(Int(percentChange))% over time. Keep up the good work!",
        confidence: min(0.9, 0.5 + abs(difference) * 0.3),
        icon: "arrow.down.circle",
        color: "#4CAF50"
      )
    } else if difference < -0.3 {
      // Getting harder
      return AnalyticsInsight(
        type: .intensityTrend,
        title: "Intensity increasing",
        description:
          "Recent entries show higher intensity. Consider reaching out for additional support if this continues.",
        confidence: min(0.85, 0.5 + abs(difference) * 0.3),
        icon: "arrow.up.circle",
        color: "#FF9800"
      )
    }

    return nil
  }

  private func analyzeTimeOfDayPattern(_ entries: [JournalEntry]) -> AnalyticsInsight? {
    let calendar = Calendar.current
    var timeSlots: [String: Int] = [
      "morning": 0,  // 5-11
      "afternoon": 0,  // 12-17
      "evening": 0,  // 18-21
      "night": 0,  // 22-4
    ]

    for entry in entries {
      let hour = calendar.component(.hour, from: entry.timestamp)

      if hour >= 5 && hour < 12 {
        timeSlots["morning"]! += 1
      } else if hour >= 12 && hour < 18 {
        timeSlots["afternoon"]! += 1
      } else if hour >= 18 && hour < 22 {
        timeSlots["evening"]! += 1
      } else {
        timeSlots["night"]! += 1
      }
    }

    guard let peakTime = timeSlots.max(by: { $0.value < $1.value }),
      peakTime.value > 2
    else {
      return nil
    }

    let percentage = Double(peakTime.value) / Double(entries.count)
    guard percentage > 0.35 else { return nil }

    let timeDescription: String
    let suggestion: String

    switch peakTime.key {
    case "morning":
      timeDescription = "mornings"
      suggestion = "Try a brief grounding exercise when you wake up."
    case "afternoon":
      timeDescription = "afternoons"
      suggestion = "Consider scheduling a brief break midday."
    case "evening":
      timeDescription = "evenings"
      suggestion = "A wind-down routine might help in the evenings."
    case "night":
      timeDescription = "late at night"
      suggestion = "Sleep hygiene and a calming routine may help."
    default:
      return nil
    }

    return AnalyticsInsight(
      type: .timeOfDay,
      title: "Peak time: \(timeDescription.capitalized)",
      description:
        "Most of your entries (\(Int(percentage * 100))%) are in the \(timeDescription). \(suggestion)",
      confidence: min(0.8, percentage + 0.2),
      icon: "clock",
      color: "#7B68EE"
    )
  }
}
