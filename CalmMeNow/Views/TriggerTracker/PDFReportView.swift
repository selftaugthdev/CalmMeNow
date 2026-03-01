import SwiftData
import SwiftUI

struct PDFReportView: View {
  @Environment(\.dismiss) private var dismiss
  @Query(sort: \TriggerEpisode.timestamp, order: .reverse) private var episodes: [TriggerEpisode]
  @Query private var journal: [JournalEntry]
  @ObservedObject private var revenueCat = RevenueCatService.shared

  @State private var isGenerating = false
  @State private var reportURL: URL?
  @State private var showShareSheet = false
  @State private var showingPaywall = false

  private var isPremium: Bool { revenueCat.isSubscribed }

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color(hex: "#2D4A6B"), Color(hex: "#1A2E4A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 0) {
        header

        ScrollView {
          VStack(spacing: 20) {
            tierCards
            includedFeatures
            dataSnapshot
            if episodes.isEmpty {
              emptyHint
            }
          }
          .padding(.horizontal, 24)
          .padding(.top, 24)
          .padding(.bottom, 120)
        }

        generateButton
      }
    }
    .sheet(isPresented: $showShareSheet) {
      if let url = reportURL {
        ShareSheet(url: url)
      }
    }
    .sheet(isPresented: $showingPaywall) {
      PaywallKitView()
    }
  }

  // MARK: - Header

  private var header: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("📄 Doctor's Report")
          .font(.system(size: 24, weight: .bold, design: .rounded))
          .foregroundColor(.white)
        Text("Export your panic data for your therapist or doctor")
          .font(.caption)
          .foregroundColor(.white.opacity(0.6))
      }
      Spacer()
      Button(action: { dismiss() }) {
        Image(systemName: "xmark")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.white.opacity(0.7))
          .padding(10)
          .background(Circle().fill(Color.white.opacity(0.15)))
      }
    }
    .padding(.horizontal, 24)
    .padding(.top, 56)
    .padding(.bottom, 24)
  }

  // MARK: - Tier Cards

  private var tierCards: some View {
    HStack(spacing: 14) {
      ReportTierCard(
        icon: "doc.text",
        title: "Basic",
        description: "1-page summary with stats, top triggers & recent episodes",
        badge: "Free",
        badgeColor: Color(hex: "#3AAA8C"),
        isActive: !isPremium
      )
      ReportTierCard(
        icon: "doc.richtext",
        title: "Full Report",
        description: "Multi-page with charts, full log, time patterns & journal",
        badge: "Premium",
        badgeColor: Color(hex: "#D4882A"),
        isActive: isPremium
      )
    }
  }

  // MARK: - Included Features

  private var includedFeatures: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("What's included")
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.white)
        .padding(.bottom, 14)

      ForEach(reportFeatures, id: \.title) { feature in
        HStack(spacing: 12) {
          let unlocked = feature.free || isPremium
          Image(systemName: unlocked ? "checkmark.circle.fill" : "lock.circle.fill")
            .font(.system(size: 16))
            .foregroundColor(unlocked ? Color(hex: "#3AAA8C") : .white.opacity(0.25))

          VStack(alignment: .leading, spacing: 2) {
            Text(feature.title)
              .font(.subheadline)
              .fontWeight(unlocked ? .medium : .regular)
              .foregroundColor(unlocked ? .white : .white.opacity(0.4))
            if !feature.subtitle.isEmpty {
              Text(feature.subtitle)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.35))
            }
          }
          Spacer()
          if !feature.free {
            Text("Premium")
              .font(.caption2)
              .fontWeight(.semibold)
              .foregroundColor(Color(hex: "#D4882A"))
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Capsule().fill(Color(hex: "#D4882A").opacity(0.15)))
          }
        }
        .padding(.vertical, 9)
        Divider().background(Color.white.opacity(0.07))
      }
    }
    .padding(18)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 1))
    )
  }

  // MARK: - Data Snapshot

  private var dataSnapshot: some View {
    HStack(spacing: 12) {
      dataChip("\(episodes.count)", label: "Episodes logged")
      dataChip("\(journal.filter { !$0.isLocked }.count)", label: "Journal entries")
    }
  }

  private func dataChip(_ value: String, label: String) -> some View {
    VStack(spacing: 4) {
      Text(value)
        .font(.system(size: 26, weight: .bold, design: .rounded))
        .foregroundColor(.white)
      Text(label)
        .font(.caption2)
        .foregroundColor(.white.opacity(0.6))
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
  }

  // MARK: - Empty Hint

  private var emptyHint: some View {
    Text(
      "You don't have any episodes logged yet. Use Emergency Calm and log your triggers — your report will fill in automatically."
    )
    .font(.caption)
    .foregroundColor(.white.opacity(0.45))
    .multilineTextAlignment(.center)
    .padding(.horizontal, 16)
  }

  // MARK: - Generate Button

  private var generateButton: some View {
    VStack(spacing: 10) {
      Button(action: generateAndShare) {
        HStack(spacing: 10) {
          if isGenerating {
            ProgressView().tint(Color(hex: "#2D4A6B"))
          } else {
            Image(systemName: "square.and.arrow.up")
          }
          Text(isGenerating ? "Generating…" : "Generate & Share PDF")
            .fontWeight(.semibold)
        }
        .foregroundColor(Color(hex: "#2D4A6B"))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(14)
      }
      .disabled(isGenerating || episodes.isEmpty)
      .opacity(episodes.isEmpty ? 0.4 : 1)

      if !isPremium {
        Button(action: { showingPaywall = true }) {
          HStack(spacing: 4) {
            Image(systemName: "lock.open.fill")
              .font(.caption)
            Text("Upgrade to Premium for the full clinical report")
              .font(.caption)
              .underline()
          }
          .foregroundColor(Color(hex: "#D4882A"))
        }
      }
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 40)
    .padding(.top, 14)
    .background(
      LinearGradient(
        colors: [Color(hex: "#1A2E4A").opacity(0), Color(hex: "#1A2E4A")],
        startPoint: .top, endPoint: .bottom
      )
      .ignoresSafeArea()
    )
  }

  // MARK: - Action

  private func generateAndShare() {
    isGenerating = true
    HapticManager.shared.mediumImpact()
    let epsCopy      = Array(episodes)
    let journalCopy  = Array(journal)
    let premium      = isPremium
    let tracker      = ProgressTracker.shared

    DispatchQueue.global(qos: .userInitiated).async {
      let url = PDFReportService.shared.generate(
        episodes: epsCopy,
        tracker: tracker,
        journal: journalCopy,
        isPremium: premium
      )
      DispatchQueue.main.async {
        isGenerating = false
        reportURL    = url
        showShareSheet = url != nil
        if url != nil { HapticManager.shared.success() }
      }
    }
  }

  // MARK: - Feature List

  private struct ReportFeature { let title: String; let subtitle: String; let free: Bool }

  private let reportFeatures: [ReportFeature] = [
    ReportFeature(title: "Summary stats",              subtitle: "Episodes, streak, % felt better",          free: true),
    ReportFeature(title: "Top 3 triggers",             subtitle: "Most common panic triggers",               free: true),
    ReportFeature(title: "Recent episodes (last 5)",   subtitle: "",                                          free: true),
    ReportFeature(title: "Full episode log with notes",subtitle: "Every episode with date, trigger, outcome", free: false),
    ReportFeature(title: "Trigger frequency charts",   subtitle: "Visual bar charts for all triggers",        free: false),
    ReportFeature(title: "Time-of-day analysis",       subtitle: "When episodes tend to occur",               free: false),
    ReportFeature(title: "Outcome per trigger",        subtitle: "Which situations you recover from fastest", free: false),
    ReportFeature(title: "Journal themes & emotions",  subtitle: "Mood patterns from your journal",           free: false),
  ]
}

// MARK: - Report Tier Card

private struct ReportTierCard: View {
  let icon: String
  let title: String
  let description: String
  let badge: String
  let badgeColor: Color
  let isActive: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Image(systemName: icon)
          .font(.system(size: 20))
          .foregroundColor(isActive ? Color(hex: "#3AAA8C") : .white.opacity(0.4))
        Spacer()
        Text(badge)
          .font(.caption2).fontWeight(.semibold)
          .foregroundColor(badgeColor)
          .padding(.horizontal, 7).padding(.vertical, 3)
          .background(Capsule().fill(badgeColor.opacity(0.15)))
      }
      Text(title)
        .font(.subheadline).fontWeight(.semibold)
        .foregroundColor(isActive ? .white : .white.opacity(0.5))
      Text(description)
        .font(.caption)
        .foregroundColor(.white.opacity(0.45))
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 14)
        .fill(isActive ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
        .overlay(
          RoundedRectangle(cornerRadius: 14)
            .stroke(isActive ? Color(hex: "#3AAA8C").opacity(0.6) : Color.white.opacity(0.08),
                    lineWidth: isActive ? 1.5 : 1)
        )
    )
  }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
  let url: URL

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: [url], applicationActivities: nil)
  }
  func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}

#Preview {
  PDFReportView()
    .modelContainer(for: [TriggerEpisode.self, JournalEntry.self], inMemory: true)
}
