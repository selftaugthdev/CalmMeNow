import Foundation
import Combine

class BreathingChallengeService: ObservableObject {
  static let shared = BreathingChallengeService()

  // MARK: - Published state

  @Published var challengeLength: Int = 0   // 0 = none active, 7, or 21
  @Published var startDate: Date = Date()
  @Published var completedDays: Set<Int> = []

  // MARK: - UserDefaults keys

  private let keyLength = "breathingChallengeLength"
  private let keyStartDate = "breathingChallengeStartDate"
  private let keyCompletedDays = "breathingChallengeCompletedDays"

  // MARK: - Day sequences (indices into BreathingProgramService.builtInPrograms)
  // 0 = Physiological Sigh, 1 = Box Breathing, 2 = Resonance, 3 = 4-7-8, 4 = Wim Hof Style

  private let sequence7: [Int] = [0, 1, 0, 2, 1, 3, 4]

  private let sequence21: [Int] = [
    // Week 1 — Foundation
    0, 1, 0, 1, 2, 0, 1,
    // Week 2 — Deepening
    2, 3, 1, 2, 3, 0, 3,
    // Week 3 — Mastery
    4, 2, 3, 4, 1, 3, 4,
  ]

  // MARK: - Init

  private init() {
    load()
  }

  // MARK: - Computed properties

  var isActive: Bool { challengeLength > 0 }

  var currentDayNumber: Int {
    guard isActive else { return 0 }
    let elapsed = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
    return min(elapsed + 1, challengeLength)
  }

  var isTodayComplete: Bool {
    completedDays.contains(currentDayNumber)
  }

  var isCompleted: Bool {
    isActive && completedDays.count >= challengeLength
  }

  var progressFraction: Double {
    guard challengeLength > 0 else { return 0 }
    return Double(completedDays.count) / Double(challengeLength)
  }

  var daysRemaining: Int {
    guard isActive else { return 0 }
    return max(challengeLength - completedDays.count, 0)
  }

  // MARK: - Program for day

  func programForDay(_ day: Int) -> BreathingProgram {
    let programs = BreathingProgramService.shared.builtInPrograms
    let sequence = challengeLength == 21 ? sequence21 : sequence7
    let index = day - 1  // day is 1-based
    guard index >= 0, index < sequence.count, !programs.isEmpty else {
      return programs.first ?? BreathingProgramService.shared.builtInPrograms[0]
    }
    let programIndex = sequence[index]
    return programs[min(programIndex, programs.count - 1)]
  }

  func dayTheme(_ day: Int) -> String {
    let themes7 = [
      "Calm & Reset",
      "Find Your Rhythm",
      "Release Tension",
      "Deep Resonance",
      "Steady & Grounded",
      "Rest & Restore",
      "Mastery Day",
    ]
    let themes21 = [
      "First Breath", "Build the Habit", "Release & Reset",
      "Find Your Pace", "Deep Resonance", "Gentle Reset", "Week 1 Complete",
      "Deepen Your Practice", "Rest & Restore", "Steady Flow",
      "Heart Coherence", "Slow & Steady", "Gentle Foundation", "Week 2 Complete",
      "Power Breath", "Resonance Mastery", "Full Recovery", "Wim Hof Flow",
      "Inner Balance", "Deep Restore", "Challenge Complete!",
    ]
    let themes = challengeLength == 21 ? themes21 : themes7
    let idx = day - 1
    guard idx >= 0, idx < themes.count else { return "Day \(day)" }
    return themes[idx]
  }

  // MARK: - Actions

  func startChallenge(length: Int) {
    challengeLength = length
    startDate = Calendar.current.startOfDay(for: Date())
    completedDays = []
    save()
  }

  func markDayComplete(_ day: Int) {
    completedDays.insert(day)
    save()
  }

  func abandonChallenge() {
    challengeLength = 0
    completedDays = []
    save()
  }

  // MARK: - Persistence

  private func save() {
    UserDefaults.standard.set(challengeLength, forKey: keyLength)
    UserDefaults.standard.set(startDate, forKey: keyStartDate)
    UserDefaults.standard.set(Array(completedDays), forKey: keyCompletedDays)
  }

  private func load() {
    challengeLength = UserDefaults.standard.integer(forKey: keyLength)
    startDate = UserDefaults.standard.object(forKey: keyStartDate) as? Date ?? Date()
    let saved = UserDefaults.standard.array(forKey: keyCompletedDays) as? [Int] ?? []
    completedDays = Set(saved)
  }
}
