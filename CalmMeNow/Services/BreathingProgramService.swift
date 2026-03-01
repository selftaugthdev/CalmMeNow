import Combine
import Foundation

class BreathingProgramService: ObservableObject {
  static let shared = BreathingProgramService()

  // Fixed UUIDs so saved favorites survive app restarts
  let builtInPrograms: [BreathingProgram] = [
    BreathingProgram(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
      name: "Physiological Sigh",
      emoji: "🌬️",
      description:
        "Double inhale followed by a long exhale. Scientifically proven for rapid stress relief.",
      inhale: 3, holdAfterInhale: 0, exhale: 6, holdAfterExhale: 0,
      duration: 90,
      category: .stress,
      style: .physiologicalSigh,
      isFree: true,
      isBuiltIn: true
    ),
    BreathingProgram(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
      name: "Box Breathing",
      emoji: "⬜",
      description: "4-4-4-4 pattern used by Navy SEALs to build calm and focus under pressure.",
      inhale: 4, holdAfterInhale: 4, exhale: 4, holdAfterExhale: 4,
      duration: 120,
      category: .stress,
      style: .box,
      isFree: true,
      isBuiltIn: true
    ),
    BreathingProgram(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
      name: "Resonance Breathing",
      emoji: "🫀",
      description:
        "5.5-second inhale and exhale. Synchronizes breath with heart rate for deep calm.",
      inhale: 5.5, holdAfterInhale: 0, exhale: 5.5, holdAfterExhale: 0,
      duration: 120,
      category: .anxiety,
      style: .orb,
      isFree: false,
      isBuiltIn: true
    ),
    BreathingProgram(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
      name: "4-7-8 Technique",
      emoji: "🌙",
      description:
        "Inhale 4s, hold 7s, exhale 8s. Activates the parasympathetic nervous system for sleep.",
      inhale: 4, holdAfterInhale: 7, exhale: 8, holdAfterExhale: 0,
      duration: 120,
      category: .sleep,
      style: .orb,
      isFree: false,
      isBuiltIn: true
    ),
    BreathingProgram(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
      name: "Wim Hof Style",
      emoji: "⚡",
      description:
        "Fast rhythmic breathing to energize the body and lower baseline stress levels.",
      inhale: 1.5, holdAfterInhale: 0, exhale: 1.5, holdAfterExhale: 0,
      duration: 90,
      category: .advanced,
      style: .orb,
      isFree: false,
      isBuiltIn: true
    ),
  ]

  @Published var customPrograms: [BreathingProgram] = []
  @Published var favoriteIds: Set<UUID> = []

  var favoritePrograms: [BreathingProgram] {
    (builtInPrograms + customPrograms).filter { favoriteIds.contains($0.id) }
  }

  private init() {
    loadCustomPrograms()
    loadFavorites()
  }

  func toggleFavorite(_ program: BreathingProgram) {
    if favoriteIds.contains(program.id) {
      favoriteIds.remove(program.id)
    } else {
      favoriteIds.insert(program.id)
    }
    saveFavorites()
  }

  func saveCustom(_ program: BreathingProgram) {
    customPrograms.append(program)
    saveCustomPrograms()
  }

  func deleteCustom(id: UUID) {
    customPrograms.removeAll { $0.id == id }
    favoriteIds.remove(id)
    saveCustomPrograms()
    saveFavorites()
  }

  // MARK: - Persistence

  private func saveCustomPrograms() {
    if let data = try? JSONEncoder().encode(customPrograms) {
      UserDefaults.standard.set(data, forKey: "customBreathingPrograms")
    }
  }

  private func loadCustomPrograms() {
    guard let data = UserDefaults.standard.data(forKey: "customBreathingPrograms"),
      let programs = try? JSONDecoder().decode([BreathingProgram].self, from: data)
    else { return }
    customPrograms = programs
  }

  private func saveFavorites() {
    let ids = favoriteIds.map { $0.uuidString }
    UserDefaults.standard.set(ids, forKey: "breathingFavoriteIds")
  }

  private func loadFavorites() {
    guard let ids = UserDefaults.standard.stringArray(forKey: "breathingFavoriteIds") else {
      return
    }
    favoriteIds = Set(ids.compactMap { UUID(uuidString: $0) })
  }
}
