import HealthKit
import SwiftUI

final class HealthKitManager: ObservableObject {
  static let shared = HealthKitManager()

  private let store = HKHealthStore()

  @Published var authStatus: AuthStatus = .notDetermined
  @Published var heartRate: Double? = nil
  @Published var hrv: Double? = nil
  @Published var isFetching = false

  enum AuthStatus {
    case notDetermined, authorized, denied, unavailable
  }

  // MARK: - Stress Level

  enum StressLevel {
    case calm, mild, elevated

    var label: String {
      switch self {
      case .calm:     return "Heart rate looks calm"
      case .mild:     return "Slightly elevated"
      case .elevated: return "Heart rate elevated"
      }
    }

    var color: Color {
      switch self {
      case .calm:     return Color(red: 0.2, green: 0.75, blue: 0.45)
      case .mild:     return Color(red: 0.95, green: 0.65, blue: 0.1)
      case .elevated: return Color(red: 0.9, green: 0.3, blue: 0.3)
      }
    }

    var suggestion: String? {
      switch self {
      case .calm:     return nil
      case .mild:     return "Resonance breathing can lower it further."
      case .elevated: return "A physiological sigh works fastest right now."
      }
    }

    // Returns the program name to pre-select in the breathing library
    var suggestedProgramName: String? {
      switch self {
      case .calm:     return nil
      case .mild:     return "Resonance Breathing"
      case .elevated: return "Physiological Sigh"
      }
    }
  }

  var stressLevel: StressLevel {
    var score = 0

    if let hr = heartRate {
      if hr > 95 { score += 2 }
      else if hr > 80 { score += 1 }
    }
    if let hrv = hrv {
      if hrv < 20 { score += 2 }
      else if hrv < 40 { score += 1 }
    }

    switch score {
    case 0:    return .calm
    case 1, 2: return .mild
    default:   return .elevated
    }
  }

  // MARK: - Authorization

  func requestAuthorization() async {
    guard HKHealthStore.isHealthDataAvailable() else {
      await MainActor.run { authStatus = .unavailable }
      return
    }

    let types: Set<HKObjectType> = [
      HKQuantityType(.heartRate),
      HKQuantityType(.heartRateVariabilitySDNN),
    ]

    do {
      try await store.requestAuthorization(toShare: [], read: types)
      await MainActor.run { authStatus = .authorized }
      await fetchLatestData()
    } catch {
      await MainActor.run { authStatus = .denied }
    }
  }

  // MARK: - Fetch

  func fetchLatestData() async {
    await MainActor.run { isFetching = true }

    async let hr = fetchLatest(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()))
    async let hrv = fetchLatest(.heartRateVariabilitySDNN, unit: HKUnit.secondUnit(with: .milli))

    let (heartRateValue, hrvValue) = await (hr, hrv)

    await MainActor.run {
      self.heartRate = heartRateValue
      self.hrv = hrvValue
      self.isFetching = false
    }
  }

  private func fetchLatest(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
    let type = HKQuantityType(identifier)
    let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

    return await withCheckedContinuation { continuation in
      let query = HKSampleQuery(
        sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]
      ) { _, samples, _ in
        guard let sample = samples?.first as? HKQuantitySample else {
          continuation.resume(returning: nil)
          return
        }
        continuation.resume(returning: sample.quantity.doubleValue(for: unit))
      }
      store.execute(query)
    }
  }
}
