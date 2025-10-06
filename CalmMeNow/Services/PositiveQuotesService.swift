import Foundation

struct PositiveQuote: Codable, Hashable {
  let text: String
  let reflection: String
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
          text: "You are stronger than you think.",
          reflection: "Breathe into your power, one gentle moment at a time."
        ),
        PositiveQuote(
          text: "Every breath is a fresh start.",
          reflection: "Inhale calm, exhale what you no longer need."
        ),
      ]
    }
  }

  func randomQuote() -> PositiveQuote {
    guard let quote = quotes.randomElement() else {
      return PositiveQuote(
        text: "You are enough, exactly as you are.",
        reflection: "Let this be a soft place to land."
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
