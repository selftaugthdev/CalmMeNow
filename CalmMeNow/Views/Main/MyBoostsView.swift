import SwiftUI

struct MyBoostsView: View {
  @Environment(\.presentationMode) var presentationMode
  @State private var favorites: [PositiveQuote] = PositiveQuotesService.shared.favorites()

  var body: some View {
    NavigationView {
      List {
        if favorites.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            Text("No saved boosts yet")
              .font(.headline)
            Text("Tap the heart on any quote to save it here.")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .padding(.vertical, 12)
        }

        ForEach(favorites, id: \.id) { q in
          VStack(alignment: .leading, spacing: 8) {
            Text("“\(q.text)”")
              .font(.system(size: 18, weight: .semibold, design: .serif))
            Text(q.reflection)
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .padding(.vertical, 8)
          .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
              remove(q)
            } label: {
              Label("Remove", systemImage: "heart.slash")
            }
          }
        }
      }
      .listStyle(.insetGrouped)
      .navigationTitle("My Boosts")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { presentationMode.wrappedValue.dismiss() }
        }
      }
      .onAppear { reload() }
    }
  }

  private func reload() {
    favorites = PositiveQuotesService.shared.favorites()
  }

  private func remove(_ q: PositiveQuote) {
    PositiveQuotesService.shared.toggleFavorite(q)
    reload()
  }
}
