import SwiftData
import SwiftUI

struct WeeklyWellnessReportView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  @StateObject private var progressTracker = ProgressTracker.shared

  @Query private var allTriggerEpisodes: [TriggerEpisode]
  @Query private var allJournalEntries: [JournalEntry]

  // MARK: - Computed week window

  private var weekStart: Date {
    Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
  }

  private var weekRangeLabel: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    let end = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? Date()
    return "\(formatter.string(from: weekStart)) – \(formatter.string(from: end))"
  }

  // MARK: - Filtered data

  private var weekEpisodes: [TriggerEpisode] {
    allTriggerEpisodes.filter { $0.timestamp >= weekStart }
  }

  private var weekJournalEntries: [JournalEntry] {
    allJournalEntries.filter { $0.timestamp >= weekStart }
  }

  // MARK: - Derived stats

  private var topTrigger: (label: String, emoji: String, count: Int)? {
    guard !weekEpisodes.isEmpty else { return nil }
    let grouped = Dictionary(grouping: weekEpisodes, by: \.triggerKey).mapValues { $0.count }
    guard let topKey = grouped.max(by: { $0.value < $1.value })?.key,
      let sample = weekEpisodes.first(where: { $0.triggerKey == topKey })
    else { return nil }
    return (sample.triggerLabel, sample.triggerEmoji, grouped[topKey]!)
  }

  private var successRate: Int? {
    guard !weekEpisodes.isEmpty else { return nil }
    let successes = weekEpisodes.filter(\.isSuccess).count
    return Int(Double(successes) / Double(weekEpisodes.count) * 100)
  }

  private var encouragementMessage: String {
    let days = progressTracker.daysThisWeek
    let streak = progressTracker.currentStreak
    if streak >= 7 {
      return "A full week of showing up for yourself. That takes real commitment — well done."
    } else if days >= 5 {
      return "Strong week. You reached for support more days than not — that's the habit forming."
    } else if days >= 3 {
      return "Solid effort this week. Every session counts, no matter how small."
    } else if days >= 1 {
      return "You showed up this week. That's what matters — one step at a time."
    } else {
      return "This week is still ahead of you. Opening this report is already a good sign."
    }
  }

  // MARK: - Body

  var body: some View {
    NavigationView {
      ZStack {
        LinearGradient(
          gradient: Gradient(colors: [
            Color(hex: "#F5D5E8"),
            Color(hex: "#E8C9D0"),
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        ScrollView {
          VStack(spacing: 20) {

            // Header
            VStack(spacing: 6) {
              Text("📋")
                .font(.system(size: 48))
              Text("Weekly Wellness Report")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
              Text(weekRangeLabel)
                .font(.subheadline)
                .foregroundColor(.black.opacity(0.55))
            }
            .padding(.top, 8)

            // At a Glance — 2x2 stat grid
            ReportSectionCard(title: "At a Glance") {
              LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
              ) {
                StatTile(
                  value: "\(progressTracker.daysThisWeek)/7",
                  label: "Days Active",
                  color: Color(hex: "#A0C4FF")
                )
                StatTile(
                  value: "\(progressTracker.weeklyUsage)",
                  label: "Sessions",
                  color: Color(hex: "#98D8C8")
                )
                StatTile(
                  value: "\(progressTracker.currentStreak)",
                  label: "Day Streak",
                  color: Color(hex: "#FFD6A5"),
                  suffix: progressTracker.currentStreak == 1 ? "" : ""
                )
                StatTile(
                  value: "\(weekJournalEntries.count)",
                  label: "Journal Entries",
                  color: Color(hex: "#E8C9D0")
                )
              }
            }

            // Top Trigger
            if let trigger = topTrigger {
              ReportSectionCard(title: "Top Trigger This Week") {
                HStack(spacing: 16) {
                  Text(trigger.emoji)
                    .font(.system(size: 40))

                  VStack(alignment: .leading, spacing: 4) {
                    Text(trigger.label)
                      .font(.headline)
                      .foregroundColor(.black)
                    Text("\(trigger.count) episode\(trigger.count == 1 ? "" : "s") logged")
                      .font(.subheadline)
                      .foregroundColor(.black.opacity(0.6))
                    if let rate = successRate {
                      Text("Relief success rate: \(rate)%")
                        .font(.caption)
                        .foregroundColor(rate >= 70 ? .green : rate >= 40 ? .orange : .red)
                        .fontWeight(.medium)
                    }
                  }

                  Spacer()
                }
                .padding(.vertical, 4)

                if weekEpisodes.count > 1 {
                  Divider().padding(.vertical, 6)

                  HStack {
                    Text("\(weekEpisodes.count) total episode\(weekEpisodes.count == 1 ? "" : "s") this week")
                      .font(.caption)
                      .foregroundColor(.black.opacity(0.55))
                    Spacer()
                    Text("\(weekEpisodes.filter(\.isSuccess).count) resolved")
                      .font(.caption)
                      .foregroundColor(.green)
                      .fontWeight(.medium)
                  }
                }
              }
            } else {
              ReportSectionCard(title: "Top Trigger This Week") {
                HStack {
                  Text("A calm week so far. Keep going.")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.55))
                  Spacer()
                }
              }
            }

            // Streak Card
            ReportSectionCard(title: "Streak Progress") {
              HStack(spacing: 0) {
                VStack(spacing: 4) {
                  Text("\(progressTracker.currentStreak)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#FFD6A5"))
                  Text("Current streak")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.55))
                }
                .frame(maxWidth: .infinity)

                Divider()
                  .frame(height: 50)

                VStack(spacing: 4) {
                  Text("\(progressTracker.longestStreak)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#C9B8E8"))
                  Text("Best streak")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.55))
                }
                .frame(maxWidth: .infinity)
              }
              .padding(.vertical, 4)

              // Weekly dots
              HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                  let date = Calendar.current.date(byAdding: .day, value: i, to: weekStart) ?? weekStart
                  let active = progressTracker.allUsageDates.contains(where: {
                    Calendar.current.isDate($0, inSameDayAs: date)
                  })
                  VStack(spacing: 3) {
                    Circle()
                      .fill(active ? Color(hex: "#A0C4FF") : Color.gray.opacity(0.2))
                      .frame(width: 28, height: 28)
                      .overlay(
                        Text(active ? "✓" : "")
                          .font(.system(size: 12, weight: .bold))
                          .foregroundColor(.white)
                      )
                    Text(dayLetter(for: i))
                      .font(.system(size: 10))
                      .foregroundColor(.black.opacity(0.45))
                  }
                  .frame(maxWidth: .infinity)
                }
              }
              .padding(.top, 8)
            }

            // Encouragement
            ReportSectionCard(title: "Your Week in Words") {
              HStack(alignment: .top, spacing: 12) {
                Text("💬")
                  .font(.title2)
                Text(encouragementMessage)
                  .font(.body)
                  .foregroundColor(.black.opacity(0.8))
                  .fixedSize(horizontal: false, vertical: true)
              }
            }

          }
          .padding(.horizontal, 20)
          .padding(.bottom, 40)
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Close") { dismiss() }
            .foregroundColor(.black.opacity(0.7))
        }
      }
    }
    .navigationViewStyle(.stack)
  }

  private func dayLetter(for offset: Int) -> String {
    let days = ["M", "T", "W", "T", "F", "S", "S"]
    // weekStart is Monday in most locales — offset maps directly
    let weekday = Calendar.current.component(.weekday, from: weekStart)
    // Rotate days array so it starts on the correct day
    let startIndex = (weekday - 2 + 7) % 7
    return days[(startIndex + offset) % 7]
  }
}

// MARK: - Sub-components

struct ReportSectionCard<Content: View>: View {
  let title: String
  let content: Content

  init(title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(title)
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundColor(.black)

      content
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white)
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
    )
  }
}

struct StatTile: View {
  let value: String
  let label: String
  let color: Color
  var suffix: String = ""

  var body: some View {
    VStack(spacing: 4) {
      Text(value + suffix)
        .font(.system(size: 28, weight: .bold, design: .rounded))
        .foregroundColor(.black)
      Text(label)
        .font(.caption)
        .foregroundColor(.black.opacity(0.55))
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(color.opacity(0.25))
    )
  }
}
