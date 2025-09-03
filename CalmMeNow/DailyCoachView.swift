import SwiftUI

struct DailyCoachView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var progressTracker = ProgressTracker.shared
  @State private var showingDailyCheckIn = false
  @State private var showingProgressReport = false
  @State private var selectedDate = Date()

  // Sample daily check-in data
  @State private var dailyCheckIns: [DailyCheckIn] = [
    DailyCheckIn(
      id: UUID().uuidString,
      date: Date(),
      mood: .good,
      stressLevel: .medium,
      notes: "Feeling more balanced today",
      completedActivities: ["breathing", "journaling"]
    )
  ]

  var body: some View {
    NavigationView {
      ZStack {
        // Background gradient
        LinearGradient(
          gradient: Gradient(colors: [
            Color(hex: "#F0F8FF"),
            Color(hex: "#E6F3FF"),
            Color(hex: "#D1ECF1"),
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        ScrollView {
          VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
              Text("📅")
                .font(.system(size: 60))

              Text("Daily Coach")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)

              Text("Track your daily progress and build healthy habits")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            }
            .padding(.top, 20)

            // Today's Check-in Status
            VStack(spacing: 16) {
              Text("Today's Check-in")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

              if let todayCheckIn = dailyCheckIns.first(where: {
                Calendar.current.isDate($0.date, inSameDayAs: Date())
              }) {
                TodayCheckInCard(checkIn: todayCheckIn)
              } else {
                Button(action: {
                  showingDailyCheckIn = true
                }) {
                  VStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                      .font(.system(size: 40))
                      .foregroundColor(.blue)

                    Text("Complete Today's Check-in")
                      .font(.headline)
                      .fontWeight(.semibold)
                      .foregroundColor(.blue)

                    Text("Take a moment to reflect on your day")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  .padding(24)
                  .background(
                    RoundedRectangle(cornerRadius: 16)
                      .fill(Color.white)
                      .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                  )
                }
                .buttonStyle(PlainButtonStyle())
              }
            }
            .padding(.horizontal, 20)

            // Progress Overview
            VStack(spacing: 16) {
              HStack {
                Text("Progress Overview")
                  .font(.title2)
                  .fontWeight(.semibold)
                  .foregroundColor(.primary)

                Spacer()

                Button("View Report") {
                  showingProgressReport = true
                }
                .font(.caption)
                .foregroundColor(.blue)
              }

              ProgressOverviewCard(progressTracker: progressTracker)
            }
            .padding(.horizontal, 20)

            // Recent Check-ins
            VStack(spacing: 16) {
              Text("Recent Check-ins")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

              LazyVStack(spacing: 12) {
                ForEach(dailyCheckIns.prefix(5)) { checkIn in
                  CheckInHistoryCard(checkIn: checkIn)
                }
              }
            }
            .padding(.horizontal, 20)

            // Daily Tips
            VStack(spacing: 16) {
              Text("Today's Tip")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

              DailyTipCard()
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 40)
          }
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarItems(
        leading: Button("Close") {
          presentationMode.wrappedValue.dismiss()
        }
        .foregroundColor(.blue)
      )
      .sheet(isPresented: $showingDailyCheckIn) {
        DailyCheckInView()
      }
      .sheet(isPresented: $showingProgressReport) {
        ProgressReportView(progressTracker: progressTracker)
      }
    }
  }
}

// MARK: - Supporting Types

struct DailyCheckIn: Identifiable, Codable {
  let id: String
  let date: Date
  let mood: Mood
  let stressLevel: StressLevel
  let notes: String
  let completedActivities: [String]

  enum Mood: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case okay = "okay"
    case bad = "bad"
    case terrible = "terrible"

    var emoji: String {
      switch self {
      case .excellent: return "😄"
      case .good: return "🙂"
      case .okay: return "😐"
      case .bad: return "😔"
      case .terrible: return "😢"
      }
    }

    var description: String {
      switch self {
      case .excellent: return "Excellent"
      case .good: return "Good"
      case .okay: return "Okay"
      case .bad: return "Bad"
      case .terrible: return "Terrible"
      }
    }
  }

  enum StressLevel: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case veryHigh = "very_high"

    var description: String {
      switch self {
      case .low: return "Low"
      case .medium: return "Medium"
      case .high: return "High"
      case .veryHigh: return "Very High"
      }
    }

    var color: Color {
      switch self {
      case .low: return .green
      case .medium: return .yellow
      case .high: return .orange
      case .veryHigh: return .red
      }
    }
  }
}

// MARK: - Today Check-in Card

struct TodayCheckInCard: View {
  let checkIn: DailyCheckIn

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text(checkIn.mood.emoji)
          .font(.title)

        VStack(alignment: .leading, spacing: 4) {
          Text("Mood: \(checkIn.mood.description)")
            .font(.headline)
            .foregroundColor(.primary)

          Text("Stress: \(checkIn.stressLevel.description)")
            .font(.subheadline)
            .foregroundColor(checkIn.stressLevel.color)
        }

        Spacer()

        Text("✓")
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.green)
      }

      if !checkIn.notes.isEmpty {
        Text(checkIn.notes)
          .font(.body)
          .foregroundColor(.secondary)
      }

      if !checkIn.completedActivities.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          Text("Activities Completed:")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.secondary)

          HStack {
            ForEach(checkIn.completedActivities, id: \.self) { activity in
              Text(activity.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                  RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                )
                .foregroundColor(.blue)
            }
          }
        }
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    )
  }
}

// MARK: - Progress Overview Card

struct ProgressOverviewCard: View {
  let progressTracker: ProgressTracker

  var body: some View {
    VStack(spacing: 16) {
      HStack {
        StatCard(
          title: "Current Streak",
          value: "\(progressTracker.currentStreak)",
          subtitle: "days",
          color: .blue
        )

        StatCard(
          title: "This Week",
          value: "\(progressTracker.weeklyUsage)",
          subtitle: "sessions",
          color: .green
        )

        StatCard(
          title: "Total Usage",
          value: "\(progressTracker.totalUsage)",
          subtitle: "times",
          color: .purple
        )
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    )
  }
}

struct StatCard: View {
  let title: String
  let value: String
  let subtitle: String
  let color: Color

  var body: some View {
    VStack(spacing: 4) {
      Text(value)
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(color)

      Text(subtitle)
        .font(.caption)
        .foregroundColor(.secondary)

      Text(title)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(.primary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
  }
}

// MARK: - Check-in History Card

struct CheckInHistoryCard: View {
  let checkIn: DailyCheckIn

  var body: some View {
    HStack(spacing: 12) {
      Text(checkIn.mood.emoji)
        .font(.title2)

      VStack(alignment: .leading, spacing: 4) {
        Text(formatDate(checkIn.date))
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundColor(.primary)

        Text("Mood: \(checkIn.mood.description) • Stress: \(checkIn.stressLevel.description)")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      Circle()
        .fill(checkIn.stressLevel.color)
        .frame(width: 8, height: 8)
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.white.opacity(0.8))
    )
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
  }
}

// MARK: - Daily Tip Card

struct DailyTipCard: View {
  private let tips = [
    "Take 3 deep breaths when you feel overwhelmed",
    "Practice gratitude by listing 3 things you're thankful for",
    "Go for a 10-minute walk to clear your mind",
    "Try the 5-4-3-2-1 grounding technique",
    "Write down your thoughts to process them better",
    "Listen to calming music for 5 minutes",
    "Stretch your body to release tension",
    "Call a friend or family member for support",
  ]

  private var randomTip: String {
    tips.randomElement() ?? tips[0]
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "lightbulb.fill")
          .foregroundColor(.yellow)

        Text("Daily Wellness Tip")
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(.primary)

        Spacer()
      }

      Text(randomTip)
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.leading)
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    )
  }
}

// MARK: - Daily Check-in Form

struct DailyCheckInFormView: View {
  @Environment(\.presentationMode) var presentationMode
  let onSave: (DailyCheckIn) -> Void

  @State private var selectedMood: DailyCheckIn.Mood = .good
  @State private var selectedStressLevel: DailyCheckIn.StressLevel = .medium
  @State private var notes = ""
  @State private var selectedActivities: Set<String> = []

  private let availableActivities = [
    "breathing", "journaling", "meditation", "exercise",
    "social_connection", "nature_walk", "music", "reading",
  ]

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("How are you feeling today?")) {
          Picker("Mood", selection: $selectedMood) {
            ForEach(DailyCheckIn.Mood.allCases, id: \.self) { mood in
              HStack {
                Text(mood.emoji)
                Text(mood.description)
              }
              .tag(mood)
            }
          }
          .pickerStyle(WheelPickerStyle())

          Picker("Stress Level", selection: $selectedStressLevel) {
            ForEach(DailyCheckIn.StressLevel.allCases, id: \.self) { level in
              HStack {
                Circle()
                  .fill(level.color)
                  .frame(width: 12, height: 12)
                Text(level.description)
              }
              .tag(level)
            }
          }
          .pickerStyle(WheelPickerStyle())
        }

        Section(header: Text("Notes (Optional)")) {
          TextField("How was your day?", text: $notes, axis: .vertical)
            .lineLimit(3...6)
        }

        Section(header: Text("Activities Completed Today")) {
          ForEach(availableActivities, id: \.self) { activity in
            HStack {
              Text(activity.replacingOccurrences(of: "_", with: " ").capitalized)
              Spacer()
              if selectedActivities.contains(activity) {
                Image(systemName: "checkmark.circle.fill")
                  .foregroundColor(.blue)
              }
            }
            .contentShape(Rectangle())
            .onTapGesture {
              if selectedActivities.contains(activity) {
                selectedActivities.remove(activity)
              } else {
                selectedActivities.insert(activity)
              }
            }
          }
        }
      }
      .navigationTitle("Daily Check-in")
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarItems(
        leading: Button("Cancel") {
          presentationMode.wrappedValue.dismiss()
        },
        trailing: Button("Save") {
          let checkIn = DailyCheckIn(
            id: UUID().uuidString,
            date: Date(),
            mood: selectedMood,
            stressLevel: selectedStressLevel,
            notes: notes,
            completedActivities: Array(selectedActivities)
          )
          onSave(checkIn)
        }
      )
    }
  }
}

// MARK: - Progress Report View

struct ProgressReportView: View {
  @Environment(\.presentationMode) var presentationMode
  let progressTracker: ProgressTracker

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          // Header
          VStack(spacing: 12) {
            Text("📊")
              .font(.system(size: 50))

            Text("Progress Report")
              .font(.title)
              .fontWeight(.bold)
              .foregroundColor(.primary)
          }
          .padding(.top, 20)

          // Stats Grid
          LazyVGrid(
            columns: [
              GridItem(.flexible()),
              GridItem(.flexible()),
            ], spacing: 16
          ) {
            StatCard(
              title: "Current Streak",
              value: "\(progressTracker.currentStreak)",
              subtitle: "days",
              color: .blue
            )

            StatCard(
              title: "Longest Streak",
              value: "\(progressTracker.longestStreak)",
              subtitle: "days",
              color: .green
            )

            StatCard(
              title: "This Week",
              value: "\(progressTracker.weeklyUsage)",
              subtitle: "sessions",
              color: .orange
            )

            StatCard(
              title: "This Month",
              value: "\(progressTracker.daysThisWeek)",
              subtitle: "days",
              color: .purple
            )
          }
          .padding(.horizontal, 20)

          // Heatmap
          VStack(spacing: 16) {
            Text("Activity Heatmap")
              .font(.title2)
              .fontWeight(.semibold)
              .foregroundColor(.primary)

            StreakHeatmapView(activities: progressTracker.last90DaysActivity)
              .frame(height: 200)
          }
          .padding(.horizontal, 20)

          Spacer(minLength: 40)
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarItems(
        trailing: Button("Done") {
          presentationMode.wrappedValue.dismiss()
        }
        .foregroundColor(.blue)
      )
    }
  }
}

#Preview {
  DailyCoachView()
}
