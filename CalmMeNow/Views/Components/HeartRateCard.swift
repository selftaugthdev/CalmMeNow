import SwiftUI

struct HeartRateCard: View {
  @StateObject private var healthKit = HealthKitManager.shared
  var onSuggestionTap: (String) -> Void  // passes suggested program name

  var body: some View {
    switch healthKit.authStatus {
    case .notDetermined:
      connectCard
    case .authorized:
      dataCard
    case .denied:
      deniedCard
    case .unavailable:
      EmptyView()
    }
  }

  // MARK: - Connect Card

  private var connectCard: some View {
    Button {
      Task { await healthKit.requestAuthorization() }
    } label: {
      HStack(spacing: 16) {
        ZStack {
          Circle()
            .fill(Color.pink.opacity(0.15))
            .frame(width: 48, height: 48)
          Image(systemName: "heart.fill")
            .font(.title2)
            .foregroundColor(.pink)
        }

        VStack(alignment: .leading, spacing: 4) {
          Text("Connect Apple Health")
            .font(.headline)
            .foregroundColor(.primary)
          Text("Get exercise suggestions based on your heart rate")
            .font(.caption)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .foregroundColor(.secondary)
          .font(.caption)
      }
      .padding(16)
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(Color.white.opacity(0.85))
          .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
      )
    }
    .buttonStyle(PlainButtonStyle())
  }

  // MARK: - Data Card

  private var dataCard: some View {
    VStack(spacing: 12) {
      HStack(spacing: 16) {
        // Heart rate display
        ZStack {
          Circle()
            .fill(healthKit.stressLevel.color.opacity(0.15))
            .frame(width: 56, height: 56)
          VStack(spacing: 0) {
            Image(systemName: "heart.fill")
              .font(.system(size: 10))
              .foregroundColor(healthKit.stressLevel.color)
            if let hr = healthKit.heartRate {
              Text("\(Int(hr))")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(healthKit.stressLevel.color)
            } else {
              Text("--")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
            }
            Text("BPM")
              .font(.system(size: 8, weight: .medium))
              .foregroundColor(.secondary)
          }
        }

        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            Circle()
              .fill(healthKit.stressLevel.color)
              .frame(width: 8, height: 8)
            Text(healthKit.isFetching ? "Updating…" : healthKit.stressLevel.label)
              .font(.subheadline.weight(.semibold))
              .foregroundColor(.primary)
          }

          if let hrv = healthKit.hrv {
            Text("HRV \(Int(hrv)) ms")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }

        Spacer()

        // Refresh button
        Button {
          Task { await healthKit.fetchLatestData() }
        } label: {
          Image(systemName: "arrow.clockwise")
            .font(.caption)
            .foregroundColor(.secondary)
            .rotationEffect(.degrees(healthKit.isFetching ? 360 : 0))
            .animation(
              healthKit.isFetching
                ? .linear(duration: 1).repeatForever(autoreverses: false)
                : .default,
              value: healthKit.isFetching
            )
        }
      }

      // No data state
      if healthKit.heartRate == nil && !healthKit.isFetching {
        Text("No recent heart rate data found. Make sure your Apple Watch is syncing with Health.")
          .font(.caption)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }

      // Suggestion banner
      if let suggestion = healthKit.stressLevel.suggestion,
        let programName = healthKit.stressLevel.suggestedProgramName,
        healthKit.heartRate != nil
      {
        Divider()

        Button {
          onSuggestionTap(programName)
        } label: {
          HStack(spacing: 10) {
            Image(systemName: "wind")
              .foregroundColor(healthKit.stressLevel.color)
            Text(suggestion)
              .font(.subheadline)
              .foregroundColor(.primary)
              .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Text("Start")
              .font(.subheadline.weight(.semibold))
              .foregroundColor(.white)
              .padding(.horizontal, 14)
              .padding(.vertical, 6)
              .background(
                Capsule()
                  .fill(healthKit.stressLevel.color)
              )
          }
        }
        .buttonStyle(PlainButtonStyle())
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(Color.white.opacity(0.85))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    )
  }

  // MARK: - Denied Card

  private var deniedCard: some View {
    HStack(spacing: 12) {
      Image(systemName: "heart.slash")
        .foregroundColor(.secondary)
      Text("Health access denied. Enable it in Settings → Privacy → Health → CalmMeNow.")
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white.opacity(0.6))
    )
  }
}
