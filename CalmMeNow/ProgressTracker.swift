import Foundation
import SwiftUI

class ProgressTracker: ObservableObject {
  static let shared = ProgressTracker()

  @Published var weeklyUsage: Int = 0
  @Published var totalUsage: Int = 0
  @Published var lastUsedDate: Date?

  private let userDefaults = UserDefaults.standard
  private let weeklyUsageKey = "weeklyUsage"
  private let totalUsageKey = "totalUsage"
  private let lastUsedDateKey = "lastUsedDate"
  private let weekStartDateKey = "weekStartDate"

  init() {
    loadData()
    checkWeekReset()
  }

  func recordUsage() {
    totalUsage += 1
    weeklyUsage += 1
    lastUsedDate = Date()

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

  private func loadData() {
    weeklyUsage = userDefaults.integer(forKey: weeklyUsageKey)
    totalUsage = userDefaults.integer(forKey: totalUsageKey)
    lastUsedDate = userDefaults.object(forKey: lastUsedDateKey) as? Date
  }

  private func saveData() {
    userDefaults.set(weeklyUsage, forKey: weeklyUsageKey)
    userDefaults.set(totalUsage, forKey: totalUsageKey)
    userDefaults.set(lastUsedDate, forKey: lastUsedDateKey)
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
