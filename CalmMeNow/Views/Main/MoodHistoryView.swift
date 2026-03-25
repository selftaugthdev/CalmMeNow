import Charts
import SwiftData
import SwiftUI

struct MoodHistoryView: View {
  @Environment(\.dismiss) private var dismiss
  @Query(sort: \MoodEntry.timestamp) private var allEntries: [MoodEntry]

  @State private var selectedRange: Int = 30  // 30 or 90 days

  // MARK: - Filtered entries

  private var cutoff: Date {
    Calendar.current.date(byAdding: .day, value: -selectedRange, to: Date()) ?? Date()
  }

  private var entries: [MoodEntry] {
    allEntries.filter { $0.timestamp >= cutoff }
  }

  // MARK: - Stats

  private var average: Double? {
    guard !entries.isEmpty else { return nil }
    return Double(entries.map(\.score).reduce(0, +)) / Double(entries.count)
  }

  private var trend: String {
    guard entries.count >= 4 else { return "" }
    let half = entries.count / 2
    let firstHalf = entries.prefix(half).map(\.score)
    let secondHalf = entries.suffix(half).map(\.score)
    let firstAvg = Double(firstHalf.reduce(0, +)) / Double(firstHalf.count)
    let secondAvg = Double(secondHalf.reduce(0, +)) / Double(secondHalf.count)
    let delta = secondAvg - firstAvg
    if delta > 0.5 { return "Improving" }
    if delta < -0.5 { return "Declining" }
    return "Stable"
  }

  private var trendColor: Color {
    switch trend {
    case "Improving": return .green
    case "Declining": return .red
    default: return Color(hex: "#A0C4FF")
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
              Text("📊")
                .font(.system(size: 48))
              Text("Mood History")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
              Text("Daily Check-in scores over time")
                .font(.subheadline)
                .foregroundColor(.black.opacity(0.55))
            }
            .padding(.top, 8)

            // Range toggle
            Picker("Range", selection: $selectedRange) {
              Text("30 days").tag(30)
              Text("90 days").tag(90)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)

            if entries.isEmpty {
              emptyState
            } else {
              statsRow
              chartCard
              if !entries.isEmpty {
                recentEntriesList
              }
            }
          }
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

  // MARK: - Empty state

  private var emptyState: some View {
    VStack(spacing: 16) {
      Text("💙")
        .font(.system(size: 48))
      Text("Nothing here yet.")
        .font(.headline)
        .foregroundColor(.black)
      Text("Do your first Daily Check-in and\nyour mood will start showing up here.")
        .font(.subheadline)
        .foregroundColor(.black.opacity(0.55))
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(32)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white)
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
    )
    .padding(.horizontal, 20)
  }

  // MARK: - Stats row

  private var statsRow: some View {
    HStack(spacing: 12) {
      MoodStatTile(
        value: average.map { String(format: "%.1f", $0) } ?? "--",
        label: "Average",
        color: Color(hex: "#A0C4FF")
      )
      MoodStatTile(
        value: "\(entries.count)",
        label: "Check-ins",
        color: Color(hex: "#98D8C8")
      )
      if !trend.isEmpty {
        MoodStatTile(
          value: trend,
          label: "Trend",
          color: trendColor.opacity(0.5),
          smallValue: true
        )
      }
    }
    .padding(.horizontal, 20)
  }

  // MARK: - Chart card

  private var chartCard: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Mood Over Time")
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundColor(.black)

      Chart {
        // Average reference line
        if let avg = average {
          RuleMark(y: .value("Average", avg))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
            .foregroundStyle(Color.gray.opacity(0.4))
            .annotation(position: .trailing, alignment: .leading) {
              Text("avg")
                .font(.system(size: 9))
                .foregroundColor(.gray.opacity(0.6))
            }
        }

        // Area fill
        ForEach(entries) { entry in
          AreaMark(
            x: .value("Date", entry.timestamp),
            y: .value("Mood", entry.score)
          )
          .foregroundStyle(
            LinearGradient(
              colors: [Color(hex: "#A0C4FF").opacity(0.3), Color(hex: "#A0C4FF").opacity(0.0)],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .interpolationMethod(.catmullRom)
        }

        // Line
        ForEach(entries) { entry in
          LineMark(
            x: .value("Date", entry.timestamp),
            y: .value("Mood", entry.score)
          )
          .foregroundStyle(Color(hex: "#5B8FCC"))
          .lineStyle(StrokeStyle(lineWidth: 2.5))
          .interpolationMethod(.catmullRom)
        }

        // Dots colored by score
        ForEach(entries) { entry in
          PointMark(
            x: .value("Date", entry.timestamp),
            y: .value("Mood", entry.score)
          )
          .foregroundStyle(dotColor(for: entry.score))
          .symbolSize(32)
        }
      }
      .chartYScale(domain: 1...10)
      .chartYAxis {
        AxisMarks(values: [1, 3, 5, 7, 10]) { value in
          AxisGridLine()
            .foregroundStyle(Color.gray.opacity(0.15))
          AxisValueLabel {
            if let v = value.as(Int.self) {
              Text("\(v)")
                .font(.system(size: 10))
                .foregroundColor(.black.opacity(0.4))
            }
          }
        }
      }
      .chartXAxis {
        AxisMarks(values: .stride(by: selectedRange == 30 ? .day : .weekOfYear, count: selectedRange == 30 ? 7 : 2)) { _ in
          AxisGridLine().foregroundStyle(Color.gray.opacity(0.1))
          AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            .font(.system(size: 10))
            .foregroundStyle(Color.black.opacity(0.4))
        }
      }
      .frame(height: 200)

      // Legend
      HStack(spacing: 16) {
        LegendDot(color: .green, label: "7–10 Good")
        LegendDot(color: Color(hex: "#FFD6A5"), label: "4–6 Okay")
        LegendDot(color: .red.opacity(0.7), label: "1–3 Low")
      }
      .padding(.top, 4)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white)
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
    )
    .padding(.horizontal, 20)
  }

  // MARK: - Recent entries list

  private var recentEntriesList: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Recent Check-ins")
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundColor(.black)

      VStack(spacing: 10) {
        ForEach(entries.suffix(10).reversed()) { entry in
          HStack(spacing: 12) {
            Circle()
              .fill(dotColor(for: entry.score))
              .frame(width: 10, height: 10)

            Text(entry.timestamp, style: .date)
              .font(.subheadline)
              .foregroundColor(.black.opacity(0.7))

            Spacer()

            Text("\(entry.score)/10")
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundColor(.black)

            if !entry.tags.isEmpty {
              Text(entry.tags.prefix(2).joined(separator: ", "))
                .font(.caption)
                .foregroundColor(.black.opacity(0.45))
                .lineLimit(1)
            }
          }

          if entry.id != entries.suffix(10).reversed().last?.id {
            Divider()
          }
        }
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white)
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
    )
    .padding(.horizontal, 20)
  }

  // MARK: - Helpers

  private func dotColor(for score: Int) -> Color {
    if score >= 7 { return .green }
    if score >= 4 { return Color(hex: "#FFD6A5") }
    return .red.opacity(0.7)
  }
}

// MARK: - Sub-components

struct MoodStatTile: View {
  let value: String
  let label: String
  let color: Color
  var smallValue: Bool = false

  var body: some View {
    VStack(spacing: 4) {
      Text(value)
        .font(smallValue
          ? .system(size: 16, weight: .bold, design: .rounded)
          : .system(size: 26, weight: .bold, design: .rounded))
        .foregroundColor(.black)
        .minimumScaleFactor(0.7)
        .lineLimit(1)
      Text(label)
        .font(.caption)
        .foregroundColor(.black.opacity(0.55))
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 14)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(color.opacity(0.35))
    )
  }
}

struct LegendDot: View {
  let color: Color
  let label: String

  var body: some View {
    HStack(spacing: 5) {
      Circle()
        .fill(color)
        .frame(width: 8, height: 8)
      Text(label)
        .font(.caption2)
        .foregroundColor(.black.opacity(0.5))
    }
  }
}
