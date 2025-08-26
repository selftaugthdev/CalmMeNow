import SwiftUI

struct StreakHeatmapView: View {
  let activities: [DayActivity]
  let size: CGFloat = 12
  let spacing: CGFloat = 3

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Title
      Text("Your Calming Journey")
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundColor(.primary)

      // Heatmap grid
      LazyVGrid(
        columns: Array(repeating: GridItem(.fixed(size), spacing: spacing), count: 13),
        spacing: spacing
      ) {
        ForEach(Array(activities.enumerated()), id: \.offset) { index, activity in
          RoundedRectangle(cornerRadius: 2)
            .fill(getColorForActivity(activity))
            .frame(width: size, height: size)
            .overlay(
              RoundedRectangle(cornerRadius: 2)
                .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
            )
        }
      }

      // Legend
      HStack(spacing: 16) {
        HStack(spacing: 4) {
          RoundedRectangle(cornerRadius: 2)
            .fill(Color.gray.opacity(0.1))
            .frame(width: 12, height: 12)
          Text("No activity")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        HStack(spacing: 4) {
          RoundedRectangle(cornerRadius: 2)
            .fill(Color.green.opacity(0.3))
            .frame(width: 12, height: 12)
          Text("Calmed")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.white)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    )
  }

  private func getColorForActivity(_ activity: DayActivity) -> Color {
    if activity.wasActive {
      return Color.green.opacity(0.6)
    } else {
      return Color.gray.opacity(0.1)
    }
  }
}

struct StreakCardView: View {
  @ObservedObject var progressTracker: ProgressTracker

  var body: some View {
    VStack(spacing: 16) {
      // Main streak info
      VStack(spacing: 8) {
        Text(progressTracker.getStreakMessage())
          .font(.title3)
          .fontWeight(.medium)
          .multilineTextAlignment(.center)
          .foregroundColor(.primary)

        if progressTracker.currentStreak > 0 {
          Text("\(progressTracker.currentStreak)")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundColor(.green)

          Text("days")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      // Weekly progress
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(progressTracker.getWeeklyMessage())
            .font(.subheadline)
            .foregroundColor(.secondary)

          Text(progressTracker.getLongestStreakMessage())
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

        // Weekly progress circles
        HStack(spacing: 4) {
          ForEach(0..<7, id: \.self) { dayIndex in
            Circle()
              .fill(
                dayIndex < progressTracker.daysThisWeek
                  ? Color.green.opacity(0.6) : Color.gray.opacity(0.1)
              )
              .frame(width: 8, height: 8)
          }
        }
      }

      // Heatmap
      StreakHeatmapView(activities: progressTracker.last90DaysActivity)
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    )
  }
}

#Preview {
  StreakCardView(progressTracker: ProgressTracker.shared)
    .padding()
}
