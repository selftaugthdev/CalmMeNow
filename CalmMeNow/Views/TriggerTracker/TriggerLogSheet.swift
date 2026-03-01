import SwiftData
import SwiftUI

struct TriggerLogSheet: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  let outcome: String

  @State private var selectedCategory: TriggerEpisode.TriggerCategory? = nil
  @State private var noteText = ""
  @State private var showNoteField = false

  private let columns = [GridItem(.flexible()), GridItem(.flexible())]

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color(hex: "#1B3D5E"), Color(hex: "#2D6B8C")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 0) {
        // Header
        VStack(spacing: 8) {
          Text("💭")
            .font(.system(size: 48))
            .padding(.top, 40)

          Text("What set this off?")
            .font(.system(size: 26, weight: .bold, design: .rounded))
            .foregroundColor(.white)

          Text("Logging triggers helps you spot patterns over time.")
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.7))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
        }
        .padding(.bottom, 24)

        // Trigger grid + note
        ScrollView {
          LazyVGrid(columns: columns, spacing: 12) {
            ForEach(TriggerEpisode.categories, id: \.key) { category in
              TriggerCategoryChip(
                category: category,
                isSelected: selectedCategory?.key == category.key,
                onTap: {
                  withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    if selectedCategory?.key == category.key {
                      selectedCategory = nil
                    } else {
                      selectedCategory = category
                    }
                  }
                  HapticManager.shared.lightImpact()
                }
              )
            }
          }
          .padding(.horizontal, 24)

          VStack(spacing: 12) {
            if showNoteField {
              TextField("What happened? (optional)", text: $noteText, axis: .vertical)
                .lineLimit(3...5)
                .padding(12)
                .background(Color.white.opacity(0.12))
                .foregroundColor(.white)
                .cornerRadius(12)
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .tint(.white)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Button(showNoteField ? "Remove note" : "+ Add a note") {
              withAnimation(.easeInOut(duration: 0.25)) {
                showNoteField.toggle()
                if !showNoteField { noteText = "" }
              }
            }
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.6))
          }
          .padding(.horizontal, 24)
          .padding(.top, 16)
          .padding(.bottom, 8)
        }

        // Action buttons
        VStack(spacing: 12) {
          Button(action: logEpisode) {
            Text("Log it")
              .font(.title3)
              .fontWeight(.semibold)
              .foregroundColor(Color(hex: "#1B3D5E"))
              .frame(maxWidth: .infinity)
              .padding(.vertical, 16)
              .background(selectedCategory != nil ? Color.white : Color.white.opacity(0.3))
              .cornerRadius(14)
          }
          .disabled(selectedCategory == nil)
          .animation(.easeInOut(duration: 0.2), value: selectedCategory?.key)
          .padding(.horizontal, 24)

          Button("Skip for now") {
            dismiss()
          }
          .font(.subheadline)
          .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 24)
      }
    }
  }

  private func logEpisode() {
    guard let cat = selectedCategory else { return }
    let episode = TriggerEpisode(
      triggerKey: cat.key,
      triggerLabel: cat.label,
      triggerEmoji: cat.emoji,
      note: noteText.isEmpty ? nil : noteText,
      outcome: outcome
    )
    modelContext.insert(episode)
    HapticManager.shared.success()
    dismiss()
  }
}

// MARK: - Trigger Category Chip

private struct TriggerCategoryChip: View {
  let category: TriggerEpisode.TriggerCategory
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 10) {
        Text(category.emoji)
          .font(.title3)
        Text(category.label)
          .font(.subheadline)
          .fontWeight(isSelected ? .semibold : .regular)
          .foregroundColor(isSelected ? Color(hex: "#1B3D5E") : .white)
          .lineLimit(1)
          .minimumScaleFactor(0.85)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(isSelected ? Color.white : Color.white.opacity(0.12))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(isSelected ? Color.white : Color.white.opacity(0.2), lineWidth: 1)
      )
    }
    .buttonStyle(PlainButtonStyle())
    .scaleEffect(isSelected ? 1.03 : 1.0)
  }
}

#Preview {
  TriggerLogSheet(outcome: "better_now")
    .modelContainer(for: TriggerEpisode.self, inMemory: true)
}
