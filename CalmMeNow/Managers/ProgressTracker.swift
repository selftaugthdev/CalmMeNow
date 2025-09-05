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

  // NEW: Track all days the user has used the app
  @Published var allUsageDates: Set<Date> = []

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
  private let allUsageDatesKey = "allUsageDates"

  init() {
    loadData()
    checkWeekReset()
    updateStreaks()
    generateLast90DaysActivity()
  }

  func recordUsage() {
    totalUsage += 1
    weeklyUsage += 1

    let today = Date()

    lastUsedDate = Date()

    // Add today to the set of usage dates
    allUsageDates.insert(today)

    // Update streaks (this will calculate current streak properly)
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

    // Calculate current streak based on consecutive days
    var consecutiveDays = 0
    var checkDate = today

    // Count backwards from today to find consecutive days
    while true {
      var foundUsageOnThisDay = false
      for usageDate in allUsageDates {
        if calendar.isDate(checkDate, inSameDayAs: usageDate) {
          foundUsageOnThisDay = true
          break
        }
      }

      if foundUsageOnThisDay {
        consecutiveDays += 1
        // Move to previous day
        checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
      } else {
        break  // Found a gap, stop counting
      }
    }

    currentStreak = consecutiveDays

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
        // Check if any usage date matches this day
        for usageDate in allUsageDates {
          if calendar.isDate(date, inSameDayAs: usageDate) {
            daysCount += 1
            break  // Only count each day once
          }
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
        // Check if any usage date matches this day
        var wasActive = false
        for usageDate in allUsageDates {
          if calendar.isDate(date, inSameDayAs: usageDate) {
            wasActive = true
            break
          }
        }
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

    // Load all usage dates
    if let datesData = userDefaults.object(forKey: allUsageDatesKey) as? [Date] {
      allUsageDates = Set(datesData)
    }
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

    // Save all usage dates
    userDefaults.set(Array(allUsageDates), forKey: allUsageDatesKey)
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

  // MARK: - Debug/Reset Methods

  func resetStreakData() {
    currentStreak = 0
    longestStreak = 0
    lastUsedDate = nil
    allUsageDates.removeAll()
    saveData()
  }

  // Debug method to add usage for specific dates (for testing)
  func addUsageForDate(_ date: Date) {
    allUsageDates.insert(date)
    updateStreaks()
    generateLast90DaysActivity()
    saveData()
  }

  // Debug method to add usage for multiple consecutive days (for testing)
  func addUsageForConsecutiveDays(_ count: Int) {
    let calendar = Calendar.current
    let today = Date()

    for i in 0..<count {
      if let date = calendar.date(byAdding: .day, value: -i, to: today) {
        allUsageDates.insert(date)
      }
    }

    updateStreaks()
    generateLast90DaysActivity()
    saveData()
  }

  func resetAllData() {
    weeklyUsage = 0
    totalUsage = 0
    lastUsedDate = nil
    currentStreak = 0
    longestStreak = 0
    reliefOutcomes = []
    helpOptionsUsed = []
    daysThisWeek = 0
    last90DaysActivity = []
    allUsageDates = []  // Reset all usage dates

    // Clear UserDefaults
    userDefaults.removeObject(forKey: weeklyUsageKey)
    userDefaults.removeObject(forKey: totalUsageKey)
    userDefaults.removeObject(forKey: lastUsedDateKey)
    userDefaults.removeObject(forKey: weekStartDateKey)
    userDefaults.removeObject(forKey: currentStreakKey)
    userDefaults.removeObject(forKey: longestStreakKey)
    userDefaults.removeObject(forKey: reliefOutcomesKey)
    userDefaults.removeObject(forKey: helpOptionsUsedKey)
    userDefaults.removeObject(forKey: last90DaysActivityKey)
    userDefaults.removeObject(forKey: allUsageDatesKey)
  }
}
