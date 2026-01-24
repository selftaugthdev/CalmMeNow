//
//  PatternAnalyticsView.swift
//  CalmMeNow
//
//  Display pattern analytics insights (Premium)
//

import SwiftData
import SwiftUI

struct PatternAnalyticsView: View {
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.modelContext) private var modelContext
  @StateObject private var analysisService = PatternAnalysisService.shared
  @StateObject private var paywallManager = PaywallManager.shared
  @Query(sort: \JournalEntry.timestamp, order: .reverse) private var journalEntries: [JournalEntry]

  var body: some View {
    NavigationView {
      ZStack {
        // Background gradient
        LinearGradient(
          gradient: Gradient(colors: [
            Color(hex: "#A0C4FF"),
            Color(hex: "#98D8C8"),
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        ScrollView {
          VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
              ZStack {
                Circle()
                  .fill(Color.purple.opacity(0.2))
                  .frame(width: 80, height: 80)

                Image(systemName: "chart.bar.doc.horizontal")
                  .font(.system(size: 40))
                  .foregroundColor(.purple)
              }

              Text("Pattern Insights")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)

              Text("Discover patterns in your mental health journey")
                .font(.subheadline)
                .foregroundColor(.primary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            }
            .padding(.top, 20)

            // Content based on data availability
            if analysisService.isAnalyzing {
              loadingView
            } else if !analysisService.hasEnoughData {
              notEnoughDataView
            } else if analysisService.insights.isEmpty {
              noInsightsView
            } else {
              insightsListView
            }

            Spacer(minLength: 40)
          }
        }
      }
      .navigationBarHidden(true)
      .overlay(
        // Close button
        VStack {
          HStack {
            Spacer()
            Button(action: {
              presentationMode.wrappedValue.dismiss()
            }) {
              Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(.gray)
                .padding()
            }
          }
          Spacer()
        }
      )
      .onAppear {
        checkPremiumAndAnalyze()
      }
    }
  }

  // MARK: - Loading View

  private var loadingView: some View {
    VStack(spacing: 20) {
      ProgressView()
        .scaleEffect(1.5)

      Text("Analyzing your patterns...")
        .font(.headline)
        .foregroundColor(.primary.opacity(0.7))
    }
    .padding(.top, 60)
  }

  // MARK: - Not Enough Data View

  private var notEnoughDataView: some View {
    VStack(spacing: 20) {
      ZStack {
        Circle()
          .fill(Color.orange.opacity(0.2))
          .frame(width: 100, height: 100)

        Image(systemName: "doc.text.magnifyingglass")
          .font(.system(size: 50))
          .foregroundColor(.orange)
      }

      Text("Not Enough Data Yet")
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundColor(.primary)

      Text(
        "You need at least \(analysisService.getEntriesNeeded()) journal entries to see pattern insights."
      )
      .font(.body)
      .foregroundColor(.primary.opacity(0.7))
      .multilineTextAlignment(.center)
      .padding(.horizontal, 40)

      Text("Current entries: \(journalEntries.count)")
        .font(.caption)
        .foregroundColor(.primary.opacity(0.5))

      // Progress indicator
      ProgressView(
        value: Double(min(journalEntries.count, analysisService.getEntriesNeeded())),
        total: Double(analysisService.getEntriesNeeded())
      )
      .progressViewStyle(LinearProgressViewStyle(tint: .blue))
      .padding(.horizontal, 60)
      .padding(.top, 10)

      Text(
        "\(max(0, analysisService.getEntriesNeeded() - journalEntries.count)) more entries needed"
      )
      .font(.caption)
      .foregroundColor(.blue)
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white.opacity(0.9))
    )
    .padding(.horizontal, 20)
  }

  // MARK: - No Insights View

  private var noInsightsView: some View {
    VStack(spacing: 20) {
      Image(systemName: "sparkles")
        .font(.system(size: 50))
        .foregroundColor(.gray)

      Text("No Clear Patterns Yet")
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundColor(.primary)

      Text(
        "Keep journaling! As you add more entries, we'll find patterns to help you understand your mental health better."
      )
      .font(.body)
      .foregroundColor(.primary.opacity(0.7))
      .multilineTextAlignment(.center)
      .padding(.horizontal, 40)
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white.opacity(0.9))
    )
    .padding(.horizontal, 20)
  }

  // MARK: - Insights List View

  private var insightsListView: some View {
    VStack(spacing: 16) {
      // Summary card
      VStack(spacing: 8) {
        Text("Based on \(journalEntries.count) journal entries")
          .font(.caption)
          .foregroundColor(.primary.opacity(0.6))

        Text("\(analysisService.insights.count) patterns found")
          .font(.headline)
          .foregroundColor(.primary)
      }
      .padding()
      .frame(maxWidth: .infinity)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.white.opacity(0.9))
      )
      .padding(.horizontal, 20)

      // Insight cards
      ForEach(analysisService.insights) { insight in
        InsightCard(insight: insight)
      }
    }
  }

  // MARK: - Helper Methods

  private func checkPremiumAndAnalyze() {
    Task {
      let hasAccess = await paywallManager.requestAIAccess()
      if hasAccess {
        // Analyze entries
        analysisService.analyzeEntries(journalEntries)
      } else {
        // User doesn't have premium
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          if !paywallManager.shouldShowPaywall {
            presentationMode.wrappedValue.dismiss()
          }
        }
      }
    }
  }
}

// MARK: - Insight Card

struct InsightCard: View {
  let insight: AnalyticsInsight

  var body: some View {
    HStack(spacing: 16) {
      // Icon
      ZStack {
        Circle()
          .fill(Color(hex: insight.color).opacity(0.2))
          .frame(width: 50, height: 50)

        Image(systemName: insight.icon)
          .font(.title2)
          .foregroundColor(Color(hex: insight.color))
      }

      // Content
      VStack(alignment: .leading, spacing: 6) {
        HStack {
          Text(insight.title)
            .font(.headline)
            .foregroundColor(.primary)

          Spacer()

          // Confidence indicator
          ConfidenceBadge(confidence: insight.confidence)
        }

        Text(insight.description)
          .font(.subheadline)
          .foregroundColor(.primary.opacity(0.7))
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white.opacity(0.9))
    )
    .padding(.horizontal, 20)
  }
}

// MARK: - Confidence Badge

struct ConfidenceBadge: View {
  let confidence: Double

  private var label: String {
    if confidence > 0.8 {
      return "High"
    } else if confidence > 0.6 {
      return "Medium"
    } else {
      return "Low"
    }
  }

  private var color: Color {
    if confidence > 0.8 {
      return .green
    } else if confidence > 0.6 {
      return .orange
    } else {
      return .gray
    }
  }

  var body: some View {
    Text(label)
      .font(.caption2)
      .fontWeight(.medium)
      .foregroundColor(color)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(
        Capsule()
          .fill(color.opacity(0.2))
      )
  }
}

#Preview {
  PatternAnalyticsView()
}
