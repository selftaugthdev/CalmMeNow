import Foundation

final class ThoughtRecordService: ObservableObject {
  static let shared = ThoughtRecordService()

  private let key = "thoughtRecords"

  @Published var records: [ThoughtRecord] = []

  private init() {
    load()
  }

  func save(_ record: ThoughtRecord) {
    if let idx = records.firstIndex(where: { $0.id == record.id }) {
      records[idx] = record
    } else {
      records.insert(record, at: 0)
    }
    persist()
  }

  func delete(id: UUID) {
    records.removeAll { $0.id == id }
    persist()
  }

  private func persist() {
    if let data = try? JSONEncoder().encode(records) {
      UserDefaults.standard.set(data, forKey: key)
    }
  }

  private func load() {
    guard let data = UserDefaults.standard.data(forKey: key),
      let decoded = try? JSONDecoder().decode([ThoughtRecord].self, from: data)
    else { return }
    records = decoded
  }
}
