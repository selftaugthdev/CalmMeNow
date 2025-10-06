import Foundation

struct PositiveQuote: Identifiable, Codable, Hashable {
  let id: String
  let text: String
  let reflection: String
  let tags: [String]?
  let tone: String?
  let lang: String?
}

final class PositiveQuotesService {
  static let shared = PositiveQuotesService()

  private let quotes: [PositiveQuote]
  private let favoritesKey = "favoriteQuotesTexts"

  private init() {
    if let url = Bundle.main.url(forResource: "PositiveQuotes", withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let decoded = try? JSONDecoder().decode([PositiveQuote].self, from: data)
    {
      quotes = decoded
    } else {
      quotes = [
        PositiveQuote(
          id: "fallback-1",
          text: "You are stronger than you think.",
          reflection: "Breathe into your power, one gentle moment at a time.",
          tags: ["strength", "reassurance", "anxious"],
          tone: "soothing",
          lang: "en"
        ),
        PositiveQuote(
          id: "fallback-2",
          text: "Every breath is a fresh start.",
          reflection: "Inhale calm, exhale what you no longer need.",
          tags: ["calm", "anxious"],
          tone: "soothing",
          lang: "en"
        ),
      ]
    }
  }

  func randomQuote() -> PositiveQuote {
    guard let quote = quotes.randomElement() else {
      return PositiveQuote(
        id: "fallback-3",
        text: "You are enough, exactly as you are.",
        reflection: "Let this be a soft place to land.",
        tags: ["reassurance"],
        tone: "soothing",
        lang: "en"
      )
    }
    return quote
  }

  func isFavorite(_ quote: PositiveQuote) -> Bool {
    let set = favoriteTexts()
    return set.contains(quote.text)
  }

  func toggleFavorite(_ quote: PositiveQuote) {
    var set = favoriteTexts()
    if set.contains(quote.text) {
      set.remove(quote.text)
    } else {
      set.insert(quote.text)
    }
    UserDefaults.standard.set(Array(set), forKey: favoritesKey)
  }

  func favorites() -> [PositiveQuote] {
    let set = favoriteTexts()
    return quotes.filter { set.contains($0.text) }
  }

  private func favoriteTexts() -> Set<String> {
    let array = UserDefaults.standard.array(forKey: favoritesKey) as? [String] ?? []
    return Set(array)
  }
}
