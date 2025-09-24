import Foundation
import SwiftUI

/// Lightweight persistence layer for PanicPlan using UserDefaults + Codable
/// Provides CRUD operations and automatic seeding of default plans
final class PlanStore: ObservableObject {
  @Published private(set) var plans: [PanicPlan] = []

  private let key = "relaxingcalm.panicPlans.v1"
  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

  init() {
    load()
    seedIfEmpty()
  }

  /// Load plans from UserDefaults
  func load() {
    guard let data = UserDefaults.standard.data(forKey: key) else { return }
    if let decoded = try? decoder.decode([PanicPlan].self, from: data) {
      self.plans = decoded
    }
  }

  /// Save plans to UserDefaults
  func save() {
    if let data = try? encoder.encode(plans) {
      UserDefaults.standard.set(data, forKey: key)
    }
  }

  // MARK: - CRUD Operations

  /// Insert or update a plan
  func upsert(_ plan: PanicPlan) {
    if let i = plans.firstIndex(where: { $0.id == plan.id }) {
      plans[i] = plan
    } else {
      plans.append(plan)
    }
    save()
  }

  /// Delete a plan
  func delete(_ plan: PanicPlan) {
    plans.removeAll { $0.id == plan.id }
    save()
  }

  /// Get a plan by ID
  func getPlan(by id: UUID) -> PanicPlan? {
    return plans.first { $0.id == id }
  }

  // MARK: - Seeding

  /// Seed default plans if none exist
  private func seedIfEmpty() {
    guard plans.isEmpty else { return }
    plans = [
      PanicPlan(
        title: "My Emergency Plan",
        description: "Quick relief for panic attacks",
        steps: [
          "Take 5 slow breaths (in 4 • hold 4 • out 4 • hold 4)",
          "5-4-3-2-1 grounding: 5 see • 4 touch • 3 hear • 2 smell • 1 taste",
          "Repeat: 'I am safe. This will pass.'"
        ],
        duration: 120,
        techniques: ["Breathing", "Grounding", "Affirmation"],
        personalizedPhrase: "I am safe and I can handle this"
      )
    ]
    save()
  }

  // MARK: - Utility

  /// Clear all plans (useful for testing or reset)
  func clearAll() {
    plans.removeAll()
    save()
  }

  /// Get plan count
  var count: Int {
    return plans.count
  }

  /// Check if store is empty
  var isEmpty: Bool {
    return plans.isEmpty
  }
}
