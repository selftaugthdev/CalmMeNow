//
//  CalmMeNowWidget.swift
//  CalmMeNowWidget
//
//  Created by Thierry De Belder on 25/01/2026.
//

import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date())
  }

  func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
    let entry = SimpleEntry(date: Date())
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    let entry = SimpleEntry(date: Date())
    let timeline = Timeline(entries: [entry], policy: .never)
    completion(timeline)
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
}

// MARK: - Small Widget

struct SmallPanicButtonView: View {
  let entry: SimpleEntry

  var body: some View {
    VStack(spacing: 6) {
      ZStack {
        Circle()
          .fill(.white.opacity(0.9))
          .frame(width: 50, height: 50)

        Image(systemName: "heart.fill")
          .font(.system(size: 24))
          .foregroundStyle(Color(red: 0.42, green: 0.57, blue: 0.78))
      }

      Text("Calm Me")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.8)

      Text("Tap for help")
        .font(.system(size: 10))
        .foregroundStyle(.white.opacity(0.9))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(8)
  }
}

// MARK: - Medium Widget

struct MediumPanicButtonView: View {
  let entry: SimpleEntry

  var body: some View {
    HStack(spacing: 20) {
      ZStack {
        Circle()
          .fill(.white.opacity(0.9))
          .frame(width: 70, height: 70)

        Image(systemName: "heart.fill")
          .font(.system(size: 35))
          .foregroundStyle(Color(red: 0.42, green: 0.57, blue: 0.78))
      }

      VStack(alignment: .leading, spacing: 4) {
        Text("Need to calm down?")
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(.white)

        Text("Tap here for instant relief")
          .font(.system(size: 14))
          .foregroundStyle(.white.opacity(0.9))

        Text("Breathing exercises & support")
          .font(.system(size: 12))
          .foregroundStyle(.white.opacity(0.8))
      }

      Spacer()
    }
    .padding(.leading, 4)
  }
}

// MARK: - Lock Screen Widgets

struct CircularPanicButton: View {
  var body: some View {
    ZStack {
      AccessoryWidgetBackground()

      Image(systemName: "heart.fill")
        .font(.system(size: 24))
    }
  }
}

struct RectangularPanicButton: View {
  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "heart.fill")
        .font(.system(size: 20))

      VStack(alignment: .leading, spacing: 2) {
        Text("Calm Me")
          .font(.system(size: 14, weight: .semibold))
        Text("Tap for help")
          .font(.system(size: 11))
          .foregroundStyle(.secondary)
      }
    }
  }
}

// MARK: - Widget Configuration

struct CalmMeNowWidget: Widget {
  let kind: String = "CalmMeNowWidget"

  private var gradient: some View {
    LinearGradient(
      colors: [
        Color(red: 0.74, green: 0.89, blue: 0.98),
        Color(red: 0.42, green: 0.57, blue: 0.78),
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      SmallPanicButtonView(entry: entry)
        .widgetURL(URL(string: "calmmenow://emergency"))
        .containerBackground(for: .widget) {
          LinearGradient(
            colors: [
              Color(red: 0.74, green: 0.89, blue: 0.98),
              Color(red: 0.42, green: 0.57, blue: 0.78),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        }
    }
    .configurationDisplayName("Panic Button")
    .description("Quick access to emergency calm when you need it most.")
    .supportedFamilies([.systemSmall])
  }
}

struct CalmMeNowMediumWidget: Widget {
  let kind: String = "CalmMeNowMediumWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      MediumPanicButtonView(entry: entry)
        .widgetURL(URL(string: "calmmenow://emergency"))
        .containerBackground(for: .widget) {
          LinearGradient(
            colors: [
              Color(red: 0.74, green: 0.89, blue: 0.98),
              Color(red: 0.42, green: 0.57, blue: 0.78),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        }
    }
    .configurationDisplayName("Panic Button")
    .description("Quick access to emergency calm when you need it most.")
    .supportedFamilies([.systemMedium])
  }
}

struct CalmMeNowLockScreenWidget: Widget {
  let kind: String = "CalmMeNowLockScreenWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      CircularPanicButton()
        .widgetURL(URL(string: "calmmenow://emergency"))
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Panic Button")
    .description("Quick access from your lock screen.")
    .supportedFamilies([.accessoryCircular, .accessoryRectangular])
  }
}

#Preview(as: .systemSmall) {
  CalmMeNowWidget()
} timeline: {
  SimpleEntry(date: .now)
}

#Preview(as: .systemMedium) {
  CalmMeNowMediumWidget()
} timeline: {
  SimpleEntry(date: .now)
}
