//
//  PostPanicRecoveryView.swift
//  CalmMeNow
//
//  Post-panic recovery guidance and tips
//

import SwiftUI

struct RecoveryTip: Identifiable {
  let id = UUID()
  let emoji: String
  let title: String
  let description: String
  let expandedContent: String?
  let actionLabel: String?
  let action: (() -> Void)?
}

struct PostPanicRecoveryView: View {
  @Environment(\.presentationMode) var presentationMode
  @State private var expandedTipId: UUID?
  @State private var showingJournal = false
  @State private var showingCrisisResources = false
  var onReturnToHome: (() -> Void)?

  private let tips: [RecoveryTip] = [
    RecoveryTip(
      emoji: "💧",
      title: "Hydrate",
      description: "Drink some water",
      expandedContent:
        "Panic attacks can leave you feeling drained. Sipping cool water helps your body recover and signals to your nervous system that you're safe.",
      actionLabel: nil,
      action: nil
    ),
    RecoveryTip(
      emoji: "🛋️",
      title: "Rest",
      description: "Find a comfortable spot",
      expandedContent:
        "Your body just went through a lot. Find a quiet, comfortable place to sit or lie down. Give yourself permission to rest without guilt.",
      actionLabel: nil,
      action: nil
    ),
    RecoveryTip(
      emoji: "💜",
      title: "Be Gentle",
      description: "Self-compassion matters",
      expandedContent:
        "You handled something difficult. Speak to yourself like you would to a good friend. Panic attacks are not your fault, and they don't define you.",
      actionLabel: nil,
      action: nil
    ),
    RecoveryTip(
      emoji: "📝",
      title: "Journal",
      description: "Write about your experience",
      expandedContent:
        "Writing can help process what happened. Note any triggers, how you felt, and what helped. This builds self-awareness for the future.",
      actionLabel: "Open Journal",
      action: nil  // Will be set dynamically
    ),
    RecoveryTip(
      emoji: "💬",
      title: "Reach Out",
      description: "Consider texting someone",
      expandedContent:
        "You don't have to go through this alone. A simple text to a friend or family member can provide comfort and connection.",
      actionLabel: nil,
      action: nil
    ),
  ]

  var body: some View {
    ZStack {
      // Gentle recovery gradient
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "#E8F4F8"),
          Color(hex: "#D4E9F7"),
          Color(hex: "#B8D4E3"),
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      ScrollView {
        VStack(spacing: 24) {
          // Header
          VStack(spacing: 16) {
            // Gentle checkmark animation
            ZStack {
              Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 100, height: 100)

              Image(systemName: "heart.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
            }
            .padding(.top, 30)

            Text("You made it through")
              .font(.largeTitle)
              .fontWeight(.bold)
              .foregroundColor(.primary)

            Text("That took strength. Here are some gentle next steps.")
              .font(.body)
              .foregroundColor(.primary.opacity(0.7))
              .multilineTextAlignment(.center)
              .padding(.horizontal, 40)
          }

          // Recovery tips
          VStack(spacing: 12) {
            ForEach(tips) { tip in
              RecoveryTipCard(
                tip: tip,
                isExpanded: expandedTipId == tip.id,
                onTap: {
                  withAnimation(.easeInOut(duration: 0.3)) {
                    if expandedTipId == tip.id {
                      expandedTipId = nil
                    } else {
                      expandedTipId = tip.id
                    }
                  }
                },
                onAction: tip.title == "Journal"
                  ? {
                    showingJournal = true
                  } : nil
              )
            }
          }
          .padding(.horizontal, 20)

          // Crisis resources link (subtle)
          Button(action: {
            showingCrisisResources = true
          }) {
            HStack(spacing: 8) {
              Image(systemName: "phone.circle")
                .font(.subheadline)

              Text("Need more support? View crisis resources")
                .font(.subheadline)
            }
            .foregroundColor(.blue.opacity(0.8))
          }
          .padding(.top, 10)

          // Return home button
          Button(action: {
            presentationMode.wrappedValue.dismiss()
            onReturnToHome?()
          }) {
            Text("Return to Home")
              .font(.headline)
              .fontWeight(.semibold)
              .foregroundColor(.white)
              .padding(.vertical, 16)
              .padding(.horizontal, 48)
              .background(
                RoundedRectangle(cornerRadius: 30)
                  .fill(Color.blue)
              )
              .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
          }
          .padding(.top, 20)
          .padding(.bottom, 40)
        }
      }
    }
    .sheet(isPresented: $showingJournal) {
      JournalingView(emotionContext: "panic", intensityContext: "recovery")
    }
    .sheet(isPresented: $showingCrisisResources) {
      CrisisResourcesView()
    }
  }
}

// MARK: - Recovery Tip Card

struct RecoveryTipCard: View {
  let tip: RecoveryTip
  let isExpanded: Bool
  let onTap: () -> Void
  let onAction: (() -> Void)?

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Main row
      Button(action: onTap) {
        HStack(spacing: 16) {
          // Emoji
          Text(tip.emoji)
            .font(.system(size: 32))

          // Title and description
          VStack(alignment: .leading, spacing: 4) {
            Text(tip.title)
              .font(.headline)
              .foregroundColor(.primary)

            Text(tip.description)
              .font(.subheadline)
              .foregroundColor(.primary.opacity(0.6))
          }

          Spacer()

          // Expand indicator
          Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding()
      }
      .buttonStyle(PlainButtonStyle())

      // Expanded content
      if isExpanded, let content = tip.expandedContent {
        VStack(alignment: .leading, spacing: 12) {
          Divider()
            .background(Color.primary.opacity(0.1))

          Text(content)
            .font(.body)
            .foregroundColor(.primary.opacity(0.8))
            .fixedSize(horizontal: false, vertical: true)

          // Action button if available
          if let actionLabel = tip.actionLabel, let action = onAction {
            Button(action: action) {
              HStack {
                Text(actionLabel)
                  .font(.subheadline)
                  .fontWeight(.medium)

                Image(systemName: "arrow.right")
                  .font(.caption)
              }
              .foregroundColor(.blue)
              .padding(.vertical, 8)
              .padding(.horizontal, 16)
              .background(
                RoundedRectangle(cornerRadius: 20)
                  .fill(Color.blue.opacity(0.1))
              )
            }
          }
        }
        .padding(.horizontal)
        .padding(.bottom)
        .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white.opacity(0.9))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    )
  }
}

#Preview {
  PostPanicRecoveryView()
}
