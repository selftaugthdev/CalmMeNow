import Foundation
import SwiftUI

enum ReliefOutcome: String, CaseIterable {
  case betterNow = "Better Now"
  case stillNeedHelp = "Still Need Help"
}

struct DayActivity {
  let date: Date
  let usageCount: Int
  let wasActive: Bool
}

class ProgressTracker: ObservableObject {
  static let shared = ProgressTracker()

  @Published var weeklyUsage: Int = 0
  @Published var totalUsage: Int = 0
  @Published var lastUsedDate: Date?
  @Published var reliefOutcomes: [ReliefOutcome] = []
  @Published var helpOptionsUsed: [String] = []

  // New streak tracking properties
  @Published var currentStreak: Int = 0
  @Published var longestStreak: Int = 0
  @Published var daysThisWeek: Int = 0
  @Published var last90DaysActivity: [DayActivity] = []

  private let userDefaults = UserDefaults.standard
  private let weeklyUsageKey = "weeklyUsage"
  private let totalUsageKey = "totalUsage"
  private let lastUsedDateKey = "lastUsedDate"
  private let weekStartDateKey = "weekStartDate"
  private let reliefOutcomesKey = "reliefOutcomes"
  private let helpOptionsUsedKey = "helpOptionsUsed"

  // New keys for streak tracking
  private let currentStreakKey = "currentStreak"
  private let longestStreakKey = "longestStreak"
  private let last90DaysActivityKey = "last90DaysActivity"

  init() {
    loadData()
    checkWeekReset()
    updateStreaks()
    generateLast90DaysActivity()
  }

  func recordUsage() {
    totalUsage += 1
    weeklyUsage += 1
    lastUsedDate = Date()

    // Update streaks
    updateStreaks()
    generateLast90DaysActivity()

    saveData()
  }

  func recordReliefOutcome(_ outcome: ReliefOutcome) {
    reliefOutcomes.append(outcome)
    saveData()
  }

  func recordStillNeedHelp(option: String) {
    helpOptionsUsed.append(option)
    saveData()
  }

  private func checkWeekReset() {
    let calendar = Calendar.current
    let now = Date()

    if let weekStartDate = userDefaults.object(forKey: weekStartDateKey) as? Date {
      // Check if we're in a new week
      if !calendar.isDate(now, equalTo: weekStartDate, toGranularity: .weekOfYear) {
        // Reset weekly usage for new week
        weeklyUsage = 0
        let newWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        userDefaults.set(newWeekStart, forKey: weekStartDateKey)
      }
    } else {
      // First time using the app, set current week start
      let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
      userDefaults.set(weekStart, forKey: weekStartDateKey)
    }

    saveData()
  }

  // MARK: - Streak Management

  private func updateStreaks() {
    let calendar = Calendar.current
    let today = Date()

    // Calculate current streak
    if let lastUsed = lastUsedDate {
      let daysSinceLastUse = calendar.dateComponents([.day], from: lastUsed, to: today).day ?? 0

      if daysSinceLastUse == 0 {
        // Used today, increment streak
        currentStreak += 1
      } else if daysSinceLastUse == 1 {
        // Used yesterday, maintain streak
        // currentStreak stays the same
      } else {
        // Gap of 2+ days, reset streak
        currentStreak = 1
      }
    } else {
      // First time using
      currentStreak = 1
    }

    // Update longest streak
    if currentStreak > longestStreak {
      longestStreak = currentStreak
    }

    // Calculate days this week
    daysThisWeek = calculateDaysThisWeek()
  }

  private func calculateDaysThisWeek() -> Int {
    let calendar = Calendar.current
    let today = Date()
    let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today

    var daysCount = 0
    for i in 0..<7 {
      if let date = calendar.date(byAdding: .day, value: i, to: weekStart) {
        if calendar.isDate(date, inSameDayAs: lastUsedDate ?? Date.distantPast) {
          daysCount += 1
        }
      }
    }

    return daysCount
  }

  private func generateLast90DaysActivity() {
    let calendar = Calendar.current
    let today = Date()
    var activity: [DayActivity] = []

    for i in 0...89 {
      if let date = calendar.date(byAdding: .day, value: -i, to: today) {
        let wasActive = calendar.isDate(date, inSameDayAs: lastUsedDate ?? Date.distantPast)
        let usageCount = wasActive ? 1 : 0
        activity.append(DayActivity(date: date, usageCount: usageCount, wasActive: wasActive))
      }
    }

    last90DaysActivity = activity
  }

  // MARK: - Encouraging Messages

  func getStreakMessage() -> String {
    if currentStreak == 0 {
      return "🌱 Ready to start your calming journey?"
    } else if currentStreak == 1 {
      return "🌱 Great start! You calmed yourself today."
    } else if currentStreak <= 3 {
      return "🌱 You've calmed yourself \(currentStreak) days in a row. That's progress!"
    } else if currentStreak <= 7 {
      return "🌱 Amazing! \(currentStreak) days of self-care in a row."
    } else if currentStreak <= 14 {
      return "🌱 Incredible! You've been taking care of yourself for \(currentStreak) days straight."
    } else {
      return "🌱 You're a self-care champion! \(currentStreak) days and counting."
    }
  }

  func getWeeklyMessage() -> String {
    if daysThisWeek == 0 {
      return "This week: No sessions yet"
    } else if daysThisWeek == 1 {
      return "This week: 1 day of self-care"
    } else {
      return "This week: \(daysThisWeek) days of self-care"
    }
  }

  func getLongestStreakMessage() -> String {
    if longestStreak == 0 {
      return "Your longest streak: 0 days"
    } else if longestStreak == 1 {
      return "Your longest streak: 1 day"
    } else {
      return "Your longest streak: \(longestStreak) days"
    }
  }

  private func loadData() {
    weeklyUsage = userDefaults.integer(forKey: weeklyUsageKey)
    totalUsage = userDefaults.integer(forKey: totalUsageKey)
    lastUsedDate = userDefaults.object(forKey: lastUsedDateKey) as? Date

    // Load streak data
    currentStreak = userDefaults.integer(forKey: currentStreakKey)
    longestStreak = userDefaults.integer(forKey: longestStreakKey)

    // Load relief outcomes
    if let outcomeData = userDefaults.array(forKey: reliefOutcomesKey) as? [String] {
      reliefOutcomes = outcomeData.compactMap { ReliefOutcome(rawValue: $0) }
    }

    // Load help options used
    helpOptionsUsed = userDefaults.stringArray(forKey: helpOptionsUsedKey) ?? []
  }

  private func saveData() {
    userDefaults.set(weeklyUsage, forKey: weeklyUsageKey)
    userDefaults.set(totalUsage, forKey: totalUsageKey)
    userDefaults.set(lastUsedDate, forKey: lastUsedDateKey)

    // Save streak data
    userDefaults.set(currentStreak, forKey: currentStreakKey)
    userDefaults.set(longestStreak, forKey: longestStreakKey)

    // Save relief outcomes
    let outcomeStrings = reliefOutcomes.map { $0.rawValue }
    userDefaults.set(outcomeStrings, forKey: reliefOutcomesKey)

    // Save help options used
    userDefaults.set(helpOptionsUsed, forKey: helpOptionsUsedKey)
  }

  func getUsageMessage() -> String {
    if weeklyUsage == 0 {
      return "Welcome! This is your first time using CalmMeNow."
    } else if weeklyUsage == 1 {
      return "You've used CalmMeNow once this week. Great start!"
    } else {
      return "You've used CalmMeNow \(weeklyUsage) times this week."
    }
  }

  func getTotalUsageMessage() -> String {
    if totalUsage == 1 {
      return "First time using the app"
    } else {
      return "Total: \(totalUsage) sessions"
    }
  }
}
