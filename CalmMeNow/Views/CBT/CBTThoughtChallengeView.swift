import SwiftUI

struct CBTThoughtChallengeView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var service = ThoughtRecordService.shared

  @State private var step = 0
  @State private var record = ThoughtRecord()

  // Evidence entry
  @State private var newEvidenceFor = ""
  @State private var newEvidenceAgainst = ""

  // Completion
  @State private var intensityAfter: Double = 50
  @State private var isComplete = false

  private let totalSteps = 7

  var body: some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "#C9B8E8"),
          Color(hex: "#E8D5F5"),
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      if isComplete {
        completionView
      } else {
        VStack(spacing: 0) {
          // Header
          HStack {
            Button(action: { dismiss() }) {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(.black.opacity(0.4))
                .font(.title3)
            }
            Spacer()
            Text("Thought Challenge")
              .font(.headline)
              .fontWeight(.semibold)
              .foregroundColor(.black.opacity(0.7))
            Spacer()
            // Balance xmark
            Color.clear.frame(width: 28, height: 28)
          }
          .padding(.horizontal, 20)
          .padding(.top, 16)
          .padding(.bottom, 12)

          // Progress bar
          GeometryReader { geo in
            ZStack(alignment: .leading) {
              Capsule()
                .fill(Color.white.opacity(0.4))
                .frame(height: 4)
              Capsule()
                .fill(Color(hex: "#7B5EA7"))
                .frame(width: geo.size.width * CGFloat(step + 1) / CGFloat(totalSteps), height: 4)
                .animation(.easeInOut(duration: 0.3), value: step)
            }
          }
          .frame(height: 4)
          .padding(.horizontal, 20)
          .padding(.bottom, 24)

          // Step content
          ScrollView {
            VStack(spacing: 0) {
              stepView
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
          }

          // Navigation
          navigationBar
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .padding(.top, 12)
        }
      }
    }
  }

  // MARK: - Steps

  @ViewBuilder
  private var stepView: some View {
    switch step {
    case 0: situationStep
    case 1: thoughtStep
    case 2: emotionStep
    case 3: evidenceForStep
    case 4: evidenceAgainstStep
    case 5: balancedThoughtStep
    case 6: rerateStep
    default: EmptyView()
    }
  }

  // Step 0: Situation
  private var situationStep: some View {
    stepCard(
      icon: "📍",
      title: "What happened?",
      subtitle: "Briefly describe the situation or trigger."
    ) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Situation")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundColor(.secondary)
        TextEditor(text: $record.situation)
          .frame(minHeight: 100)
          .padding(10)
          .background(Color(.systemBackground))
          .cornerRadius(12)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color.black.opacity(0.08), lineWidth: 1)
          )
          .overlay(
            Group {
              if record.situation.isEmpty {
                Text("e.g. \"I made a mistake at work and my manager noticed\"")
                  .foregroundColor(.secondary.opacity(0.6))
                  .font(.body)
                  .padding(14)
                  .allowsHitTesting(false)
                  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
              }
            }
          )
      }
    }
  }

  // Step 1: Automatic thought
  private var thoughtStep: some View {
    stepCard(
      icon: "💭",
      title: "What's the thought?",
      subtitle: "Write down the exact thought that's worrying you — don't filter it."
    ) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Automatic thought")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundColor(.secondary)
        TextEditor(text: $record.automaticThought)
          .frame(minHeight: 100)
          .padding(10)
          .background(Color(.systemBackground))
          .cornerRadius(12)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color.black.opacity(0.08), lineWidth: 1)
          )
          .overlay(
            Group {
              if record.automaticThought.isEmpty {
                Text("e.g. \"Everyone thinks I'm incompetent\"")
                  .foregroundColor(.secondary.opacity(0.6))
                  .font(.body)
                  .padding(14)
                  .allowsHitTesting(false)
                  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
              }
            }
          )
      }
    }
  }

  // Step 2: Emotion + intensity
  private var emotionStep: some View {
    stepCard(
      icon: "😰",
      title: "How does it make you feel?",
      subtitle: "Name the emotion and rate how intense it feels right now."
    ) {
      VStack(spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Emotion")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
          TextField("e.g. Anxiety, Fear, Shame", text: $record.emotion)
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
        }

        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Intensity")
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundColor(.secondary)
            Spacer()
            Text("\(record.intensityBefore)%")
              .font(.caption)
              .fontWeight(.bold)
              .foregroundColor(intensityColor(record.intensityBefore))
          }
          Slider(
            value: Binding(
              get: { Double(record.intensityBefore) },
              set: { record.intensityBefore = Int($0) }
            ),
            in: 0...100,
            step: 1
          )
          .accentColor(intensityColor(record.intensityBefore))
          HStack {
            Text("Mild")
              .font(.caption2)
              .foregroundColor(.secondary)
            Spacer()
            Text("Overwhelming")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
      }
    }
  }

  // Step 3: Evidence FOR
  private var evidenceForStep: some View {
    stepCard(
      icon: "⚖️",
      title: "Evidence FOR this thought",
      subtitle: "What actual facts support this thought? Be specific — not feelings, just facts."
    ) {
      VStack(spacing: 12) {
        evidenceList(items: $record.evidenceFor, newText: $newEvidenceFor, placeholder: "Add a fact that supports it...")

        if record.evidenceFor.isEmpty {
          hintBanner("It's okay if you can't think of many. That itself is useful information.")
        }
      }
    }
  }

  // Step 4: Evidence AGAINST
  private var evidenceAgainstStep: some View {
    stepCard(
      icon: "🔍",
      title: "Evidence AGAINST this thought",
      subtitle: "What facts challenge or contradict it? Think about past experiences too."
    ) {
      VStack(spacing: 12) {
        evidenceList(items: $record.evidenceAgainst, newText: $newEvidenceAgainst, placeholder: "Add a fact that challenges it...")

        hintBanner("Ask yourself: Would a friend see it this way? Has this fear come true before?")
      }
    }
  }

  // Step 5: Balanced thought
  private var balancedThoughtStep: some View {
    stepCard(
      icon: "🌱",
      title: "A more balanced thought",
      subtitle: "Considering all the evidence, write a more realistic version of the thought."
    ) {
      VStack(alignment: .leading, spacing: 8) {
        if !record.automaticThought.isEmpty {
          Text("Original: \"\(record.automaticThought)\"")
            .font(.caption)
            .foregroundColor(.secondary)
            .italic()
            .padding(10)
            .background(Color.black.opacity(0.04))
            .cornerRadius(8)
        }
        Text("Balanced thought")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundColor(.secondary)
        TextEditor(text: $record.balancedThought)
          .frame(minHeight: 100)
          .padding(10)
          .background(Color(.systemBackground))
          .cornerRadius(12)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color.black.opacity(0.08), lineWidth: 1)
          )
          .overlay(
            Group {
              if record.balancedThought.isEmpty {
                Text("e.g. \"I made one mistake, but my overall performance has been good\"")
                  .foregroundColor(.secondary.opacity(0.6))
                  .font(.body)
                  .padding(14)
                  .allowsHitTesting(false)
                  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
              }
            }
          )
      }
    }
  }

  // Step 6: Re-rate
  private var rerateStep: some View {
    stepCard(
      icon: "📊",
      title: "How do you feel now?",
      subtitle: "Re-rate the intensity of \(record.emotion.isEmpty ? "your emotion" : record.emotion.lowercased()) after going through the evidence."
    ) {
      VStack(spacing: 16) {
        HStack {
          Text("Intensity now")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
          Spacer()
          Text("\(Int(intensityAfter))%")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(intensityColor(Int(intensityAfter)))
        }
        Slider(value: $intensityAfter, in: 0...100, step: 1)
          .accentColor(intensityColor(Int(intensityAfter)))
        HStack {
          Text("Mild")
            .font(.caption2)
            .foregroundColor(.secondary)
          Spacer()
          Text("Overwhelming")
            .font(.caption2)
            .foregroundColor(.secondary)
        }

        let before = record.intensityBefore
        let after = Int(intensityAfter)
        if after < before {
          let drop = before - after
          HStack(spacing: 8) {
            Image(systemName: "arrow.down.circle.fill")
              .foregroundColor(.green)
            Text("Down \(drop) points — that's real progress.")
              .font(.subheadline)
              .foregroundColor(.primary)
          }
          .padding(12)
          .background(Color.green.opacity(0.1))
          .cornerRadius(12)
          .transition(.opacity)
        }
      }
    }
  }

  // MARK: - Completion

  private var completionView: some View {
    VStack(spacing: 32) {
      Spacer()

      VStack(spacing: 16) {
        Text("🎉")
          .font(.system(size: 64))
        Text("Thought challenged")
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.black.opacity(0.8))
        Text("You examined the evidence and found a more balanced perspective. That's exactly what CBT is.")
          .font(.subheadline)
          .foregroundColor(.black.opacity(0.6))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 24)
      }

      // Before / After
      VStack(spacing: 12) {
        HStack(spacing: 0) {
          VStack(spacing: 4) {
            Text("Before")
              .font(.caption)
              .foregroundColor(.secondary)
            Text("\(record.intensityBefore)%")
              .font(.title3)
              .fontWeight(.bold)
              .foregroundColor(intensityColor(record.intensityBefore))
          }
          .frame(maxWidth: .infinity)

          Rectangle()
            .fill(Color.black.opacity(0.1))
            .frame(width: 1, height: 40)

          VStack(spacing: 4) {
            Text("After")
              .font(.caption)
              .foregroundColor(.secondary)
            Text("\(Int(intensityAfter))%")
              .font(.title3)
              .fontWeight(.bold)
              .foregroundColor(intensityColor(Int(intensityAfter)))
          }
          .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.85))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 40)

        if !record.balancedThought.isEmpty {
          VStack(alignment: .leading, spacing: 6) {
            Text("Your balanced thought")
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundColor(.secondary)
            Text("\"\(record.balancedThought)\"")
              .font(.subheadline)
              .foregroundColor(.primary)
              .italic()
          }
          .padding(16)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(Color.white.opacity(0.85))
              .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
          )
          .padding(.horizontal, 40)
        }
      }

      Spacer()

      Button(action: { dismiss() }) {
        Text("Done")
          .font(.headline)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(
            LinearGradient(
              gradient: Gradient(colors: [Color(hex: "#7B5EA7"), Color(hex: "#9B79C7")]),
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .cornerRadius(16)
          .shadow(color: Color(hex: "#7B5EA7").opacity(0.4), radius: 8, x: 0, y: 4)
      }
      .padding(.horizontal, 40)
      .padding(.bottom, 48)
    }
  }

  // MARK: - Navigation Bar

  private var navigationBar: some View {
    HStack(spacing: 12) {
      if step > 0 {
        Button(action: { withAnimation { step -= 1 } }) {
          HStack(spacing: 6) {
            Image(systemName: "chevron.left")
            Text("Back")
          }
          .font(.subheadline)
          .foregroundColor(.black.opacity(0.6))
          .padding(.vertical, 14)
          .padding(.horizontal, 20)
          .background(
            RoundedRectangle(cornerRadius: 14)
              .fill(Color.white.opacity(0.6))
          )
        }
      }

      Button(action: { advance() }) {
        Text(step == totalSteps - 1 ? "Finish" : "Next")
          .font(.headline)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
          .background(
            canAdvance
              ? LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#7B5EA7"), Color(hex: "#9B79C7")]),
                startPoint: .leading,
                endPoint: .trailing
              )
              : LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.4)]),
                startPoint: .leading,
                endPoint: .trailing
              )
          )
          .cornerRadius(14)
          .shadow(
            color: canAdvance ? Color(hex: "#7B5EA7").opacity(0.35) : .clear,
            radius: 8, x: 0, y: 4
          )
      }
      .disabled(!canAdvance)
    }
  }

  // MARK: - Helpers

  private var canAdvance: Bool {
    switch step {
    case 0: return !record.situation.trimmingCharacters(in: .whitespaces).isEmpty
    case 1: return !record.automaticThought.trimmingCharacters(in: .whitespaces).isEmpty
    case 2: return !record.emotion.trimmingCharacters(in: .whitespaces).isEmpty
    case 3, 4: return true   // evidence lists are optional
    case 5: return !record.balancedThought.trimmingCharacters(in: .whitespaces).isEmpty
    case 6: return true
    default: return true
    }
  }

  private func advance() {
    HapticManager.shared.lightImpact()
    if step < totalSteps - 1 {
      withAnimation { step += 1 }
    } else {
      record.intensityAfter = Int(intensityAfter)
      service.save(record)
      withAnimation { isComplete = true }
    }
  }

  private func intensityColor(_ value: Int) -> Color {
    switch value {
    case 0..<35:  return Color(red: 0.2, green: 0.75, blue: 0.45)
    case 35..<65: return Color(red: 0.95, green: 0.65, blue: 0.1)
    default:      return Color(red: 0.9, green: 0.3, blue: 0.3)
    }
  }

  @ViewBuilder
  private func stepCard<Content: View>(
    icon: String,
    title: String,
    subtitle: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 20) {
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 8) {
          Text(icon)
            .font(.title2)
          Text(title)
            .font(.title3)
            .fontWeight(.bold)
            .foregroundColor(.black.opacity(0.85))
        }
        Text(subtitle)
          .font(.subheadline)
          .foregroundColor(.black.opacity(0.55))
          .fixedSize(horizontal: false, vertical: true)
      }

      content()
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(Color.white.opacity(0.85))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    )
  }

  @ViewBuilder
  private func evidenceList(items: Binding<[String]>, newText: Binding<String>, placeholder: String) -> some View {
    VStack(spacing: 8) {
      ForEach(items.wrappedValue.indices, id: \.self) { idx in
        HStack(spacing: 8) {
          Image(systemName: "circle.fill")
            .font(.system(size: 6))
            .foregroundColor(.secondary)
          Text(items.wrappedValue[idx])
            .font(.subheadline)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
          Button(action: { items.wrappedValue.remove(at: idx) }) {
            Image(systemName: "xmark")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
      }

      HStack(spacing: 8) {
        TextField(placeholder, text: newText)
          .font(.subheadline)
          .submitLabel(.done)
          .onSubmit { addEvidence(to: items, newText: newText) }
        Button(action: { addEvidence(to: items, newText: newText) }) {
          Image(systemName: "plus.circle.fill")
            .foregroundColor(Color(hex: "#7B5EA7"))
            .font(.title3)
        }
        .disabled(newText.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color(.systemBackground))
      .cornerRadius(10)
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .stroke(Color.black.opacity(0.08), lineWidth: 1)
      )
    }
  }

  private func addEvidence(to items: Binding<[String]>, newText: Binding<String>) {
    let trimmed = newText.wrappedValue.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return }
    items.wrappedValue.append(trimmed)
    newText.wrappedValue = ""
    HapticManager.shared.lightImpact()
  }

  @ViewBuilder
  private func hintBanner(_ text: String) -> some View {
    HStack(spacing: 8) {
      Image(systemName: "lightbulb")
        .foregroundColor(.orange)
        .font(.caption)
      Text(text)
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(12)
    .background(Color.orange.opacity(0.08))
    .cornerRadius(10)
  }
}

#Preview {
  CBTThoughtChallengeView()
}
