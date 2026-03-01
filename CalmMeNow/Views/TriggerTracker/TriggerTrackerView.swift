import SwiftData
import SwiftUI

struct TriggerTrackerView: View {
  @Environment(\.dismiss) private var dismiss
  @Query(sort: \TriggerEpisode.timestamp, order: .reverse) private var episodes: [TriggerEpisode]
  @State private var showingReport = false

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color(hex: "#2D4A6B"), Color(hex: "#1A2E4A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      if episodes.isEmpty {
        emptyState
      } else {
        ScrollView {
          VStack(spacing: 20) {
            header
            summaryStats
            topTriggersCard
            timeOfDayCard
            recentEpisodesCard
          }
          .padding(.horizontal, 20)
          .padding(.bottom, 40)
        }
      }
    }
    .sheet(isPresented: $showingReport) {
      PDFReportView()
    }
  }

  // MARK: - Header

  private var header: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("📊 Trigger Tracker")
          .font(.system(size: 26, weight: .bold, design: .rounded))
          .foregroundColor(.white)
        Text("Spot your panic patterns")
          .font(.subheadline)
          .foregroundColor(.white.opacity(0.6))
      }
      Spacer()
      HStack(spacing: 10) {
        Button(action: { showingReport = true }) {
          Image(systemName: "square.and.arrow.up")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white.opacity(0.7))
            .padding(10)
            .background(Circle().fill(Color.white.opacity(0.15)))
        }
        Button(action: { dismiss() }) {
          Image(systemName: "xmark")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white.opacity(0.7))
            .padding(10)
            .background(Circle().fill(Color.white.opacity(0.15)))
        }
      }
    }
    .padding(.top, 56)
  }

  // MARK: - Summary Stats

  private var summaryStats: some View {
    let thisWeek = episodes.filter {
      Calendar.current.isDate($0.timestamp, equalTo: Date(), toGranularity: .weekOfYear)
    }
    let successRate =
      episodes.isEmpty
      ? 0 : Int(Double(episodes.filter { $0.isSuccess }.count) / Double(episodes.count) * 100)

    return HStack(spacing: 12) {
      StatBubble(value: "\(episodes.count)", label: "Total\nepisodes")
      StatBubble(value: "\(thisWeek.count)", label: "This\nweek")
      StatBubble(value: "\(successRate)%", label: "Felt\nbetter")
    }
  }

  // MARK: - Top Triggers

  private var topTriggersCard: some View {
    let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    let recent = episodes.filter { $0.timestamp >= cutoff }
    let counts = Dictionary(grouping: recent, by: \.triggerKey).mapValues { $0.count }
    let sorted = counts.sorted { $0.value > $1.value }.prefix(5)
    let maxCount = sorted.first?.value ?? 1

    return trackerCard(title: "Top Triggers", subtitle: "Last 30 days") {
      if sorted.isEmpty {
        Text("No episodes in the last 30 days")
          .font(.caption)
          .foregroundColor(.white.opacity(0.5))
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 8)
      } else {
        VStack(spacing: 10) {
          ForEach(sorted, id: \.key) { key, count in
            if let cat = TriggerEpisode.categories.first(where: { $0.key == key }) {
              TriggerBar(emoji: cat.emoji, label: cat.label, count: count, maxCount: maxCount)
            }
          }
        }
      }
    }
  }

  // MARK: - Time of Day

  private var timeOfDayCard: some View {
    let labels = ["Morning", "Afternoon", "Evening", "Night"]
    var counts = [String: Int]()
    for ep in episodes { counts[ep.timeOfDayLabel, default: 0] += 1 }
    let maxCount = counts.values.max() ?? 1

    return trackerCard(title: "Time of Day", subtitle: "When episodes tend to happen") {
      HStack(alignment: .bottom, spacing: 16) {
        ForEach(labels, id: \.self) { label in
          let count = counts[label] ?? 0
          VStack(spacing: 6) {
            Text("\(count)")
              .font(.caption2)
              .foregroundColor(.white.opacity(0.7))

            RoundedRectangle(cornerRadius: 4)
              .fill(Color.white.opacity(count > 0 ? 0.5 : 0.15))
              .frame(
                width: 32,
                height: maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) * 80 + 8 : 8
              )

            Text(label)
              .font(.system(size: 9))
              .foregroundColor(.white.opacity(0.6))
              .multilineTextAlignment(.center)
          }
          .frame(maxWidth: .infinity)
        }
      }
      .frame(height: 110, alignment: .bottom)
    }
  }

  // MARK: - Recent Episodes

  private var recentEpisodesCard: some View {
    let recent = Array(episodes.prefix(10))
    return trackerCard(title: "Recent Episodes", subtitle: "Last 10 logged") {
      VStack(spacing: 10) {
        ForEach(recent) { ep in
          HStack(spacing: 12) {
            Text(ep.triggerEmoji)
              .font(.title3)
              .frame(width: 36, height: 36)
              .background(Circle().fill(Color.white.opacity(0.1)))

            VStack(alignment: .leading, spacing: 2) {
              Text(ep.triggerLabel)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
              Text(ep.formattedTime)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Text(ep.isSuccess ? "Better" : "Needed help")
              .font(.caption2)
              .fontWeight(.semibold)
              .foregroundColor(
                ep.isSuccess ? Color(hex: "#3AAA8C") : Color(hex: "#D4882A")
              )
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(
                Capsule().fill(
                  (ep.isSuccess ? Color(hex: "#3AAA8C") : Color(hex: "#D4882A")).opacity(0.15))
              )
          }

          if ep.id != recent.last?.id {
            Divider().background(Color.white.opacity(0.1))
          }
        }
      }
    }
  }

  // MARK: - Empty State

  private var emptyState: some View {
    VStack(spacing: 28) {
      Spacer()

      Text("📊")
        .font(.system(size: 72))

      VStack(spacing: 10) {
        Text("No episodes yet")
          .font(.system(size: 28, weight: .bold, design: .rounded))
          .foregroundColor(.white)

        Text(
          "After your next emergency calm session,\nyou'll be prompted to log what triggered it."
        )
        .font(.body)
        .foregroundColor(.white.opacity(0.7))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
      }

      Spacer()

      Button(action: { dismiss() }) {
        Text("Got it")
          .font(.title3)
          .fontWeight(.semibold)
          .foregroundColor(Color(hex: "#2D4A6B"))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(Color.white)
          .cornerRadius(14)
      }
      .padding(.horizontal, 40)
      .padding(.bottom, 50)
    }
  }

  // MARK: - Card Builder

  @ViewBuilder
  private func trackerCard<Content: View>(
    title: String,
    subtitle: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.system(size: 17, weight: .semibold))
          .foregroundColor(.white)
        Text(subtitle)
          .font(.caption)
          .foregroundColor(.white.opacity(0.5))
      }
      content()
    }
    .padding(18)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white.opacity(0.08))
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    )
  }
}

// MARK: - Stat Bubble

private struct StatBubble: View {
  let value: String
  let label: String

  var body: some View {
    VStack(spacing: 4) {
      Text(value)
        .font(.system(size: 28, weight: .bold, design: .rounded))
        .foregroundColor(.white)
      Text(label)
        .font(.caption2)
        .foregroundColor(.white.opacity(0.6))
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
    .background(
      RoundedRectangle(cornerRadius: 14)
        .fill(Color.white.opacity(0.1))
    )
  }
}

// MARK: - Trigger Bar

private struct TriggerBar: View {
  let emoji: String
  let label: String
  let count: Int
  let maxCount: Int

  var body: some View {
    HStack(spacing: 10) {
      Text(emoji)
        .font(.body)
        .frame(width: 24)

      Text(label)
        .font(.caption)
        .foregroundColor(.white.opacity(0.8))
        .frame(width: 110, alignment: .leading)
        .lineLimit(1)

      GeometryReader { geo in
        Capsule()
          .fill(Color.white.opacity(0.35))
          .frame(
            width: max(8, geo.size.width * CGFloat(count) / CGFloat(maxCount)),
            height: 8
          )
          .frame(maxHeight: .infinity)
      }
      .frame(height: 8)

      Text("\(count)")
        .font(.caption2)
        .foregroundColor(.white.opacity(0.6))
        .frame(width: 20, alignment: .trailing)
    }
  }
}

#Preview {
  TriggerTrackerView()
    .modelContainer(for: TriggerEpisode.self, inMemory: true)
}
