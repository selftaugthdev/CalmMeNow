import Combine
import Foundation

final class QuoteStore: ObservableObject {
  @Published private(set) var quotes: [PositiveQuote] = []
  private var lastShownIDs: [String] = []

  func load() {
    guard let url = Bundle.main.url(forResource: "PositiveQuotes", withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let items = try? JSONDecoder().decode([PositiveQuote].self, from: data)
    else { return }
    quotes = items.shuffled()
  }

  func next(for tag: String? = nil) -> PositiveQuote? {
    let pool: [PositiveQuote]
    if let tag = tag {
      pool = quotes.filter { $0.tags?.contains(tag) == true }
    } else {
      pool = quotes
    }
    guard !pool.isEmpty else { return nil }
    let candidate = pool.first { !lastShownIDs.contains($0.id) } ?? pool.randomElement()!
    lastShownIDs.append(candidate.id)
    if lastShownIDs.count > 10 { lastShownIDs.removeFirst() }
    return candidate
  }
}
