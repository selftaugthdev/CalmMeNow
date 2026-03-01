import SwiftData
import SwiftUI

struct TriggerTrackerView: View {
  @Environment(\.dismiss) private var dismiss
  @Query(sort: \TriggerEpisode.timestamp, order: .reverse) private var episodes: [TriggerEpisode]
  @StateObject private var reminderService = CheckInReminderService.shared
  @State private var showingReport = false
  @State private var showingReminderTimePicker = false

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
            weeklyTrendsCard
            topTriggersCard
            timeOfDayCard
            recentEpisodesCard
            reminderCard
            downloadReportButton
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

  // MARK: - Weekly Trends Card

  private var weeklyTrendsCard: some View {
    let weeks = last8Weeks()
    let counts = weeks.map { (start, end) in
      episodes.filter { $0.timestamp >= start && $0.timestamp < end }.count
    }
    let maxCount = counts.max() ?? 1
    let thisWeekCount = counts.last ?? 0
    let lastWeekCount = counts.dropLast().last ?? 0
    let delta = thisWeekCount - lastWeekCount

    return trackerCard(title: "Weekly Trend", subtitle: "Episodes per week — last 8 weeks") {
      VStack(spacing: 12) {
        // Delta badge
        HStack(spacing: 6) {
          Image(systemName: delta < 0 ? "arrow.down.circle.fill" : delta > 0 ? "arrow.up.circle.fill" : "minus.circle.fill")
            .foregroundColor(delta < 0 ? Color(hex: "#3AAA8C") : delta > 0 ? Color(hex: "#C0514F") : .white.opacity(0.4))
          Text(delta == 0
               ? "Same as last week"
               : "\(abs(delta)) \(abs(delta) == 1 ? "episode" : "episodes") \(delta < 0 ? "fewer" : "more") than last week")
            .font(.caption)
            .foregroundColor(.white.opacity(0.7))
          Spacer()
          Text("This week: \(thisWeekCount)")
            .font(.caption).fontWeight(.semibold)
            .foregroundColor(.white)
        }

        // Mini bar chart
        HStack(alignment: .bottom, spacing: 6) {
          ForEach(Array(counts.enumerated()), id: \.offset) { idx, count in
            let isCurrentWeek = idx == counts.count - 1
            let barH: CGFloat = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) * 56 + 4 : 4
            VStack(spacing: 4) {
              if count > 0 {
                Text("\(count)")
                  .font(.system(size: 8))
                  .foregroundColor(.white.opacity(isCurrentWeek ? 0.9 : 0.4))
              }
              RoundedRectangle(cornerRadius: 3)
                .fill(isCurrentWeek ? Color.white.opacity(0.75) : Color.white.opacity(0.25))
                .frame(height: barH)
              Text(weekLabel(weeks[idx].0))
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(isCurrentWeek ? 0.7 : 0.35))
            }
            .frame(maxWidth: .infinity)
          }
        }
        .frame(height: 80, alignment: .bottom)
      }
    }
  }

  private func last8Weeks() -> [(Date, Date)] {
    let cal = Calendar.current
    let now = Date()
    let startOfThisWeek = cal.dateInterval(of: .weekOfYear, for: now)?.start ?? now
    return (0..<8).reversed().map { i in
      let start = cal.date(byAdding: .weekOfYear, value: -i, to: startOfThisWeek)!
      let end   = cal.date(byAdding: .weekOfYear, value: 1, to: start)!
      return (start, end)
    }
  }

  private func weekLabel(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "MMM d"
    return f.string(from: date)
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
          .font(.caption).foregroundColor(.white.opacity(0.5))
          .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 8)
      } else {
        VStack(spacing: 10) {
          ForEach(sorted, id: \.key) { key, count in
            // Use stored emoji/label directly — works for both built-in and custom
            let sampleEp = recent.first { $0.triggerKey == key }
            let emoji = sampleEp?.triggerEmoji ?? "❓"
            let label = sampleEp?.triggerLabel ?? key
            TriggerBar(emoji: emoji, label: label, count: count, maxCount: maxCount)
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
            Text("\(count)").font(.caption2).foregroundColor(.white.opacity(0.7))
            RoundedRectangle(cornerRadius: 4)
              .fill(Color.white.opacity(count > 0 ? 0.5 : 0.15))
              .frame(width: 32, height: maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) * 80 + 8 : 8)
            Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.6)).multilineTextAlignment(.center)
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
            Text(ep.triggerEmoji).font(.title3)
              .frame(width: 36, height: 36)
              .background(Circle().fill(Color.white.opacity(0.1)))
            VStack(alignment: .leading, spacing: 2) {
              HStack(spacing: 6) {
                Text(ep.triggerLabel).font(.subheadline).fontWeight(.medium).foregroundColor(.white)
                if let s = ep.severity {
                  Text("\(s)/10")
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundColor(severityColor(s))
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Capsule().fill(severityColor(s).opacity(0.15)))
                }
              }
              Text(ep.formattedTime).font(.caption2).foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            Text(ep.isSuccess ? "Better" : "Needed help")
              .font(.caption2).fontWeight(.semibold)
              .foregroundColor(ep.isSuccess ? Color(hex: "#3AAA8C") : Color(hex: "#D4882A"))
              .padding(.horizontal, 8).padding(.vertical, 4)
              .background(Capsule().fill((ep.isSuccess ? Color(hex: "#3AAA8C") : Color(hex: "#D4882A")).opacity(0.15)))
          }
          if ep.id != recent.last?.id {
            Divider().background(Color.white.opacity(0.1))
          }
        }
      }
    }
  }

  private func severityColor(_ s: Int) -> Color {
    switch s {
    case 1...3: return Color(hex: "#3AAA8C")
    case 4...6: return Color(hex: "#D4882A")
    default:    return Color(hex: "#C0514F")
    }
  }

  // MARK: - Reminder Card

  private var reminderCard: some View {
    trackerCard(title: "Daily Check-In Reminder", subtitle: "Get a gentle nudge to log how you're doing") {
      VStack(spacing: 12) {
        HStack {
          Image(systemName: "bell.fill")
            .foregroundColor(reminderService.isEnabled ? Color(hex: "#3AAA8C") : .white.opacity(0.35))
          Text(reminderService.isEnabled ? "Reminder on at \(reminderService.timeDisplayString)" : "Reminders off")
            .font(.subheadline)
            .foregroundColor(reminderService.isEnabled ? .white : .white.opacity(0.5))
          Spacer()
          Toggle("", isOn: Binding(
            get: { reminderService.isEnabled },
            set: { newVal in
              if newVal {
                Task { await reminderService.requestPermissionAndEnable() }
              } else {
                reminderService.disableReminder()
              }
            }
          ))
          .tint(Color(hex: "#3AAA8C"))
          .labelsHidden()
        }

        if reminderService.isEnabled {
          Button(action: { showingReminderTimePicker.toggle() }) {
            HStack {
              Text("Change time")
                .font(.caption).foregroundColor(.white.opacity(0.6))
              Spacer()
              Text(reminderService.timeDisplayString)
                .font(.caption).fontWeight(.semibold).foregroundColor(.white.opacity(0.7))
              Image(systemName: "chevron.right")
                .font(.caption2).foregroundColor(.white.opacity(0.35))
            }
          }
          .sheet(isPresented: $showingReminderTimePicker) {
            ReminderTimePickerSheet(service: reminderService)
          }
          .transition(.move(edge: .top).combined(with: .opacity))
        }
      }
    }
  }

  // MARK: - Download Report Button

  private var downloadReportButton: some View {
    Button(action: { showingReport = true }) {
      HStack(spacing: 10) {
        Image(systemName: "doc.text.fill")
          .font(.system(size: 16))
        Text("Download Report (PDF)")
          .fontWeight(.semibold)
      }
      .foregroundColor(Color(hex: "#2D4A6B"))
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background(Color.white)
      .cornerRadius(14)
    }
  }

  // MARK: - Empty State

  private var emptyState: some View {
    VStack(spacing: 28) {
      Spacer()
      Text("📊").font(.system(size: 72))
      VStack(spacing: 10) {
        Text("No episodes yet")
          .font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(.white)
        Text("After your next emergency calm session,\nyou'll be prompted to log what triggered it.")
          .font(.body).foregroundColor(.white.opacity(0.7))
          .multilineTextAlignment(.center).padding(.horizontal, 40)
      }
      Spacer()
      VStack(spacing: 12) {
        Button(action: { dismiss() }) {
          Text("Got it")
            .font(.title3).fontWeight(.semibold)
            .foregroundColor(Color(hex: "#2D4A6B"))
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(Color.white).cornerRadius(14)
        }
        Button(action: { showingReport = true }) {
          HStack(spacing: 8) {
            Image(systemName: "doc.text.fill")
            Text("Download Report (PDF)").fontWeight(.semibold)
          }
          .foregroundColor(.white.opacity(0.6))
          .frame(maxWidth: .infinity).padding(.vertical, 14)
          .background(Color.white.opacity(0.1)).cornerRadius(14)
          .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.15), lineWidth: 1))
        }
      }
      .padding(.horizontal, 40).padding(.bottom, 50)
    }
  }

  // MARK: - Card Builder

  @ViewBuilder
  private func trackerCard<Content: View>(
    title: String, subtitle: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title).font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
        Text(subtitle).font(.caption).foregroundColor(.white.opacity(0.5))
      }
      content()
    }
    .padding(18)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 1))
    )
  }
}

// MARK: - Stat Bubble

private struct StatBubble: View {
  let value: String
  let label: String

  var body: some View {
    VStack(spacing: 4) {
      Text(value).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(.white)
      Text(label).font(.caption2).foregroundColor(.white.opacity(0.6)).multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity).padding(.vertical, 16)
    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.1)))
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
      Text(emoji).font(.body).frame(width: 24)
      Text(label).font(.caption).foregroundColor(.white.opacity(0.8))
        .frame(width: 110, alignment: .leading).lineLimit(1)
      GeometryReader { geo in
        Capsule().fill(Color.white.opacity(0.35))
          .frame(width: max(8, geo.size.width * CGFloat(count) / CGFloat(maxCount)), height: 8)
          .frame(maxHeight: .infinity)
      }
      .frame(height: 8)
      Text("\(count)").font(.caption2).foregroundColor(.white.opacity(0.6))
        .frame(width: 20, alignment: .trailing)
    }
  }
}

// MARK: - Reminder Time Picker Sheet

struct ReminderTimePickerSheet: View {
  @ObservedObject var service: CheckInReminderService
  @Environment(\.dismiss) private var dismiss
  @State private var selectedDate: Date

  init(service: CheckInReminderService) {
    self.service = service
    var dc = DateComponents()
    dc.hour = service.hour; dc.minute = service.minute
    _selectedDate = State(initialValue: Calendar.current.date(from: dc) ?? Date())
  }

  var body: some View {
    NavigationView {
      VStack(spacing: 24) {
        Text("Choose your reminder time")
          .font(.title3).fontWeight(.semibold)
          .padding(.top, 24)
        DatePicker("Reminder time", selection: $selectedDate, displayedComponents: .hourAndMinute)
          .datePickerStyle(.wheel).labelsHidden()
        Spacer()
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            let cal = Calendar.current
            let h = cal.component(.hour, from: selectedDate)
            let m = cal.component(.minute, from: selectedDate)
            service.updateTime(hour: h, minute: m)
            dismiss()
          }
          .fontWeight(.semibold)
        }
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
    }
    .presentationDetents([.medium])
  }
}

#Preview {
  TriggerTrackerView()
    .modelContainer(for: TriggerEpisode.self, inMemory: true)
}
