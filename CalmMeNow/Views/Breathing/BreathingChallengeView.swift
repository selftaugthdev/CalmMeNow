import SwiftUI

struct BreathingChallengeView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var service = BreathingChallengeService.shared

  @State private var showingPlayer = false
  @State private var programForSession: BreathingProgram?
  @State private var showingAbandonAlert = false
  @State private var showingLengthPicker = false

  var body: some View {
    NavigationView {
      ZStack {
        LinearGradient(
          gradient: Gradient(colors: [
            Color(hex: "#A0C4FF"),
            Color(hex: "#98D8C8"),
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        if !service.isActive {
          startScreen
        } else if service.isCompleted {
          completedScreen
        } else {
          activeChallenge
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Close") { dismiss() }
            .foregroundColor(.black.opacity(0.7))
        }
        if service.isActive && !service.isCompleted {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Quit") { showingAbandonAlert = true }
              .foregroundColor(.red.opacity(0.7))
              .font(.subheadline)
          }
        }
      }
      .alert("Quit Challenge?", isPresented: $showingAbandonAlert) {
        Button("Quit", role: .destructive) { service.abandonChallenge() }
        Button("Keep Going", role: .cancel) {}
      } message: {
        Text("Your progress will be lost.")
      }
    }
    .navigationViewStyle(.stack)
    .sheet(isPresented: $showingPlayer) {
      if let program = programForSession {
        BreathingProgramPlayerView(program: program)
          .onDisappear {
            // After returning from session, mark today complete if not already
            if !service.isTodayComplete {
              service.markDayComplete(service.currentDayNumber)
            }
          }
      }
    }
  }

  // MARK: - Start Screen

  private var startScreen: some View {
    ScrollView {
      VStack(spacing: 28) {
        VStack(spacing: 8) {
          Text("🌬️")
            .font(.system(size: 64))
          Text("Breathing Challenge")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.black)
          Text("Build a daily breathing habit")
            .font(.subheadline)
            .foregroundColor(.black.opacity(0.6))
        }
        .padding(.top, 16)

        // Benefits card
        VStack(alignment: .leading, spacing: 14) {
          Text("What you'll get")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.black)

          VStack(spacing: 10) {
            ChallengeBenefitRow(icon: "lungs.fill", text: "Guided daily breathing sessions")
            ChallengeBenefitRow(icon: "heart.fill", text: "Lower resting heart rate over time")
            ChallengeBenefitRow(icon: "brain.head.profile", text: "Reduced anxiety & panic episodes")
            ChallengeBenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Track your streak & progress")
          }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
        )

        // Length options
        VStack(spacing: 12) {
          ChallengeLengthCard(
            days: 7,
            title: "7-Day Starter",
            subtitle: "Perfect for building the habit",
            color: Color(hex: "#A0C4FF")
          ) {
            service.startChallenge(length: 7)
          }

          ChallengeLengthCard(
            days: 21,
            title: "21-Day Transformation",
            subtitle: "Research-backed habit formation",
            color: Color(hex: "#C9B8E8")
          ) {
            service.startChallenge(length: 21)
          }
        }
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 40)
    }
  }

  // MARK: - Active Challenge

  private var activeChallenge: some View {
    ScrollView {
      VStack(spacing: 20) {

        // Header + progress
        VStack(spacing: 8) {
          Text("Day \(service.currentDayNumber) of \(service.challengeLength)")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.black)

          Text(service.dayTheme(service.currentDayNumber))
            .font(.subheadline)
            .foregroundColor(.black.opacity(0.6))

          // Progress bar
          GeometryReader { geo in
            ZStack(alignment: .leading) {
              RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.4))
                .frame(height: 10)
              RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .frame(width: geo.size.width * service.progressFraction, height: 10)
                .animation(.easeInOut(duration: 0.4), value: service.progressFraction)
            }
          }
          .frame(height: 10)
          .padding(.top, 4)

          Text("\(service.completedDays.count)/\(service.challengeLength) days complete")
            .font(.caption)
            .foregroundColor(.black.opacity(0.5))
        }
        .padding(.top, 8)

        // Today's session card
        VStack(alignment: .leading, spacing: 14) {
          Text("Today's Session")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.black)

          let todayProgram = service.programForDay(service.currentDayNumber)

          HStack(spacing: 16) {
            Text(programEmoji(todayProgram))
              .font(.system(size: 40))

            VStack(alignment: .leading, spacing: 4) {
              Text(todayProgram.name)
                .font(.headline)
                .foregroundColor(.black)
              Text(todayProgram.description)
                .font(.caption)
                .foregroundColor(.black.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
              Text("\(todayProgram.duration / 60) min")
                .font(.caption)
                .foregroundColor(.black.opacity(0.5))
                .fontWeight(.medium)
            }

            Spacer()
          }
          .padding(.vertical, 4)

          if service.isTodayComplete {
            HStack(spacing: 8) {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
              Text("Session complete! See you tomorrow.")
                .font(.subheadline)
                .foregroundColor(.black.opacity(0.7))
            }
            .padding(.top, 4)
          } else {
            Button {
              programForSession = todayProgram
              showingPlayer = true
            } label: {
              HStack {
                Image(systemName: "play.fill")
                Text("Start Session")
                  .fontWeight(.semibold)
              }
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 14)
              .background(
                RoundedRectangle(cornerRadius: 14)
                  .fill(Color(hex: "#5B8FCC"))
              )
            }
            .padding(.top, 4)
          }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
        )

        // Calendar grid
        calendarGrid

      }
      .padding(.horizontal, 20)
      .padding(.bottom, 40)
    }
  }

  private var calendarGrid: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Your Journey")
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundColor(.black)

      let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
      LazyVGrid(columns: columns, spacing: 8) {
        ForEach(1...service.challengeLength, id: \.self) { day in
          let isComplete = service.completedDays.contains(day)
          let isCurrent = day == service.currentDayNumber
          let isFuture = day > service.currentDayNumber

          ZStack {
            RoundedRectangle(cornerRadius: 8)
              .fill(
                isComplete ? Color(hex: "#5B8FCC") :
                isCurrent ? Color.white.opacity(0.6) :
                Color.white.opacity(0.2)
              )
              .frame(height: 36)
              .overlay(
                RoundedRectangle(cornerRadius: 8)
                  .stroke(isCurrent ? Color.white : Color.clear, lineWidth: 2)
              )

            if isComplete {
              Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
            } else {
              Text("\(day)")
                .font(.system(size: 12, weight: isCurrent ? .bold : .regular))
                .foregroundColor(isFuture ? .white.opacity(0.4) : .black.opacity(0.7))
            }
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
  }

  // MARK: - Completed Screen

  private var completedScreen: some View {
    ScrollView {
      VStack(spacing: 28) {
        VStack(spacing: 12) {
          Text("🏆")
            .font(.system(size: 80))
          Text("Challenge Complete!")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.black)
          Text("You completed the \(service.challengeLength)-day breathing challenge.")
            .font(.body)
            .foregroundColor(.black.opacity(0.7))
            .multilineTextAlignment(.center)
        }
        .padding(.top, 24)

        VStack(spacing: 8) {
          Text("\(service.challengeLength)")
            .font(.system(size: 72, weight: .bold, design: .rounded))
            .foregroundColor(.black)
          Text("days of daily breathing")
            .font(.subheadline)
            .foregroundColor(.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
        )

        VStack(spacing: 12) {
          Button {
            service.startChallenge(length: service.challengeLength == 7 ? 21 : 7)
          } label: {
            Text(service.challengeLength == 7 ? "Try the 21-Day Challenge" : "Restart 21-Day Challenge")
              .fontWeight(.semibold)
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 16)
              .background(
                RoundedRectangle(cornerRadius: 16)
                  .fill(Color(hex: "#5B8FCC"))
              )
          }

          Button {
            service.abandonChallenge()
          } label: {
            Text("Start Fresh")
              .font(.subheadline)
              .foregroundColor(.black.opacity(0.5))
          }
        }
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 40)
    }
  }

  // MARK: - Helpers

  private func programEmoji(_ program: BreathingProgram) -> String {
    switch program.style {
    case .physiologicalSigh: return "😮‍💨"
    case .box: return "⬜"
    case .orb: return "🌊"
    }
  }
}

// MARK: - Sub-components

struct ChallengeBenefitRow: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.body)
        .foregroundColor(Color(hex: "#5B8FCC"))
        .frame(width: 24)
      Text(text)
        .font(.subheadline)
        .foregroundColor(.black.opacity(0.8))
      Spacer()
    }
  }
}

struct ChallengeLengthCard: View {
  let days: Int
  let title: String
  let subtitle: String
  let color: Color
  let onStart: () -> Void

  var body: some View {
    Button(action: onStart) {
      HStack(spacing: 16) {
        VStack(
          alignment: .leading, spacing: 4
        ) {
          Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.black)
          Text(subtitle)
            .font(.caption)
            .foregroundColor(.black.opacity(0.6))
        }
        Spacer()
        Text("\(days)\ndays")
          .font(.system(size: 22, weight: .bold, design: .rounded))
          .multilineTextAlignment(.center)
          .foregroundColor(.black.opacity(0.8))
      }
      .padding(16)
      .frame(maxWidth: .infinity)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(color.opacity(0.3))
          .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
      )
    }
    .buttonStyle(.plain)
  }
}
