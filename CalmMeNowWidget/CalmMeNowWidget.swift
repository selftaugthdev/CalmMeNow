import SwiftUI
import WidgetKit

// MARK: - Widget Entry
struct PanicButtonEntry: TimelineEntry {
  let date: Date
}

// MARK: - Widget Provider
struct PanicButtonProvider: TimelineProvider {
  func placeholder(in context: Context) -> PanicButtonEntry {
    PanicButtonEntry(date: Date())
  }

  func getSnapshot(in context: Context, completion: @escaping (PanicButtonEntry) -> Void) {
    completion(PanicButtonEntry(date: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PanicButtonEntry>) -> Void) {
    let entry = PanicButtonEntry(date: Date())
    // Widget doesn't need frequent updates - it's just a button
    let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
    completion(timeline)
  }
}

// MARK: - Widget View
struct PanicButtonWidgetView: View {
  @Environment(\.widgetFamily) var widgetFamily
  var entry: PanicButtonEntry

  var body: some View {
    switch widgetFamily {
    case .systemSmall:
      SmallWidgetView()
    case .systemMedium:
      MediumWidgetView()
    case .systemLarge:
      LargeWidgetView()
    default:
      SmallWidgetView()
    }
  }
}

// MARK: - Small Widget (2x2)
struct SmallWidgetView: View {
  var body: some View {
    ZStack {
      // Urgent gradient background
      LinearGradient(
        gradient: Gradient(colors: [
          Color(red: 0.9, green: 0.3, blue: 0.2),
          Color(red: 1.0, green: 0.5, blue: 0.3)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      VStack(spacing: 8) {
        Text("🕊️")
          .font(.system(size: 36))

        Text("CALM ME")
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(.white)

        Text("NOW")
          .font(.system(size: 18, weight: .heavy))
          .foregroundColor(.white)
      }
    }
    .widgetURL(URL(string: "calmmenow://emergency"))
  }
}

// MARK: - Medium Widget (4x2)
struct MediumWidgetView: View {
  var body: some View {
    ZStack {
      // Urgent gradient background
      LinearGradient(
        gradient: Gradient(colors: [
          Color(red: 0.9, green: 0.3, blue: 0.2),
          Color(red: 1.0, green: 0.5, blue: 0.3)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      HStack(spacing: 20) {
        Text("🕊️")
          .font(.system(size: 50))

        VStack(alignment: .leading, spacing: 4) {
          Text("CALM ME DOWN")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)

          Text("NOW")
            .font(.system(size: 28, weight: .heavy))
            .foregroundColor(.white)

          Text("Tap for instant relief")
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.9))
        }

        Spacer()
      }
      .padding(.horizontal, 20)
    }
    .widgetURL(URL(string: "calmmenow://emergency"))
  }
}

// MARK: - Large Widget (4x4)
struct LargeWidgetView: View {
  var body: some View {
    ZStack {
      // Urgent gradient background
      LinearGradient(
        gradient: Gradient(colors: [
          Color(red: 0.9, green: 0.3, blue: 0.2),
          Color(red: 1.0, green: 0.5, blue: 0.3)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      VStack(spacing: 16) {
        Spacer()

        Text("🕊️")
          .font(.system(size: 70))

        Text("CALM ME DOWN NOW")
          .font(.system(size: 24, weight: .heavy))
          .foregroundColor(.white)
          .multilineTextAlignment(.center)

        Text("Tap anywhere for instant relief")
          .font(.system(size: 14))
          .foregroundColor(.white.opacity(0.9))

        Spacer()

        // Breathing reminder
        VStack(spacing: 4) {
          Text("Remember: You are safe")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white.opacity(0.95))

          Text("Breathe in... and out...")
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.8))
        }
        .padding(.bottom, 16)
      }
    }
    .widgetURL(URL(string: "calmmenow://emergency"))
  }
}

// MARK: - Widget Configuration
struct CalmMeNowWidget: Widget {
  let kind: String = "CalmMeNowWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PanicButtonProvider()) { entry in
      PanicButtonWidgetView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Panic Button")
    .description("Instant access to Emergency Calm when you need it most.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
  CalmMeNowWidget()
} timeline: {
  PanicButtonEntry(date: Date())
}

#Preview(as: .systemMedium) {
  CalmMeNowWidget()
} timeline: {
  PanicButtonEntry(date: Date())
}

#Preview(as: .systemLarge) {
  CalmMeNowWidget()
} timeline: {
  PanicButtonEntry(date: Date())
}
