import Foundation

// MARK: - Crisis Resource Models

struct CrisisResourceData: Codable {
  let name: String
  let number: String
  let description: String
}

struct CrisisResourceConfig: Codable {
  let emergencyNumber: String
  let crisisHotline: String
  let resources: [CrisisResourceData]
}

struct CrisisResourceDatabase: Codable {
  let US: CrisisResourceConfig
  let GB: CrisisResourceConfig
  let DE: CrisisResourceConfig
  let FR: CrisisResourceConfig
  let ES: CrisisResourceConfig
  let IT: CrisisResourceConfig
  let NL: CrisisResourceConfig
  let BE: CrisisResourceConfig
  let CA: CrisisResourceConfig
  let AU: CrisisResourceConfig
  let `default`: CrisisResourceConfig
}

// MARK: - Crisis Resource Service

class CrisisResourceService: ObservableObject {
  static let shared = CrisisResourceService()

  private var resourceDatabase: CrisisResourceDatabase?

  private init() {
    loadCrisisResources()
  }

  // MARK: - Public Methods

  func getCrisisResources(for locale: Locale = Locale.current) -> CrisisResourceConfig {
    guard let database = resourceDatabase else {
      return getDefaultResources()
    }

    let regionCode = locale.region?.identifier ?? "US"

    switch regionCode {
    case "US":
      return database.US
    case "GB":
      return database.GB
    case "DE":
      return database.DE
    case "FR":
      return database.FR
    case "ES":
      return database.ES
    case "IT":
      return database.IT
    case "NL":
      return database.NL
    case "BE":
      return database.BE
    case "CA":
      return database.CA
    case "AU":
      return database.AU
    default:
      return database.default
    }
  }

  func getEmergencyNumber(for locale: Locale = Locale.current) -> String {
    return getCrisisResources(for: locale).emergencyNumber
  }

  func getCrisisHotline(for locale: Locale = Locale.current) -> String {
    return getCrisisResources(for: locale).crisisHotline
  }

  func getCrisisMessage(for locale: Locale = Locale.current) -> String {
    let resources = getCrisisResources(for: locale)
    let emergencyNumber = resources.emergencyNumber
    let crisisHotline = resources.crisisHotline

    if emergencyNumber == crisisHotline {
      return """
        I'm very concerned about what you're sharing. Your safety is the most important thing right now.

        If you're in immediate danger, call \(emergencyNumber) for emergency services.

        For crisis support, visit findahelpline.com to find resources in your country.
        """
    } else {
      return """
        I'm very concerned about what you're sharing. Your safety is the most important thing right now.

        If you're in immediate danger, call \(emergencyNumber) for emergency services.

        For crisis support, call \(crisisHotline) or visit findahelpline.com for more resources.
        """
    }
  }

  func getFindAHelplineURL() -> URL {
    return URL(string: "https://findahelpline.com/")!
  }

  // MARK: - Private Methods

  private func loadCrisisResources() {
    guard let url = Bundle.main.url(forResource: "CrisisResources", withExtension: "json"),
      let data = try? Data(contentsOf: url)
    else {
      print("Failed to load CrisisResources.json")
      return
    }

    do {
      resourceDatabase = try JSONDecoder().decode(CrisisResourceDatabase.self, from: data)
    } catch {
      print("Failed to decode CrisisResources.json: \(error)")
    }
  }

  private func getDefaultResources() -> CrisisResourceConfig {
    return CrisisResourceConfig(
      emergencyNumber: "112",
      crisisHotline: "112",
      resources: [
        CrisisResourceData(
          name: "Local Emergency Services",
          number: "112",
          description: "Emergency services"
        )
      ]
    )
  }
}
