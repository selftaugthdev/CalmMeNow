import SwiftUI
import WatchKit

struct WatchMoodView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var selected: Int? = nil
  @State private var saved = false

  private let moods: [(emoji: String, label: String, score: Int)] = [
    ("😔", "Low", 2),
    ("😟", "Uneasy", 4),
    ("😐", "Okay", 6),
    ("🙂", "Good", 8),
    ("😊", "Great", 10),
  ]

  var body: some View {
    ZStack {
      Color(hex: "#0A1628").ignoresSafeArea()

      if saved {
        VStack(spacing: 8) {
          Text("✓")
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(Color(hex: "#6AB0FF"))
          Text("Logged.")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
        }
        .onAppear {
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
          }
        }
      } else {
        VStack(spacing: 10) {
          Text("How are you?")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white.opacity(0.7))

          HStack(spacing: 6) {
            ForEach(moods, id: \.score) { mood in
              Button {
                saveMood(score: mood.score)
              } label: {
                Text(mood.emoji)
                  .font(.system(size: 22))
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 8)
                  .background(
                    RoundedRectangle(cornerRadius: 10)
                      .fill(selected == mood.score
                        ? Color(hex: "#3A6ED4").opacity(0.5)
                        : Color.white.opacity(0.06))
                  )
              }
              .buttonStyle(.plain)
            }
          }

          Button("Skip") { dismiss() }
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.3))
        }
        .padding(.horizontal, 8)
      }
    }
  }

  private func saveMood(score: Int) {
    selected = score
    WKInterfaceDevice.current().play(.click)

    // Save to UserDefaults
    var entries = loadEntries()
    entries.append(["score": score, "date": Date().timeIntervalSince1970])
    if let data = try? JSONSerialization.data(withJSONObject: entries) {
      UserDefaults.standard.set(data, forKey: "watchMoodEntries")
    }

    withAnimation { saved = true }
  }

  private func loadEntries() -> [[String: Double]] {
    guard let data = UserDefaults.standard.data(forKey: "watchMoodEntries"),
      let entries = try? JSONSerialization.jsonObject(with: data) as? [[String: Double]]
    else { return [] }
    return entries
  }
}
