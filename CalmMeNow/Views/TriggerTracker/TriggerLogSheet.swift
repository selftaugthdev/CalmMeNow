import SwiftData
import SwiftUI

// MARK: - Custom Trigger Store

final class CustomTriggerStore: ObservableObject {
  static let shared = CustomTriggerStore()
  @Published var triggers: [TriggerEpisode.TriggerCategory] = []
  private let udKey = "customTriggers"

  init() { load() }

  func add(label: String, emoji: String) {
    let key = "custom_\(UUID().uuidString.prefix(8).lowercased())"
    triggers.append(TriggerEpisode.TriggerCategory(key: key, label: label, emoji: emoji))
    save()
  }

  func remove(withKey key: String) {
    triggers.removeAll { $0.key == key }
    save()
  }

  private func save() {
    let raw = triggers.map { ["key": $0.key, "label": $0.label, "emoji": $0.emoji] }
    UserDefaults.standard.set(raw, forKey: udKey)
  }

  private func load() {
    guard let raw = UserDefaults.standard.array(forKey: udKey) as? [[String: String]] else { return }
    triggers = raw.compactMap { d in
      guard let k = d["key"], let l = d["label"], let e = d["emoji"] else { return nil }
      return TriggerEpisode.TriggerCategory(key: k, label: l, emoji: e)
    }
  }
}

// MARK: - Trigger Log Sheet

struct TriggerLogSheet: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @StateObject private var customStore = CustomTriggerStore.shared

  let outcome: String

  @State private var selectedCategory: TriggerEpisode.TriggerCategory? = nil
  @State private var severity: Int? = nil
  @State private var noteText = ""
  @State private var showNoteField = false
  @State private var showCustomForm = false
  @State private var customEmoji = "⚡️"
  @State private var customLabel = ""

  private let columns = [GridItem(.flexible()), GridItem(.flexible())]

  private let emojiOptions = ["⚡️","😤","😰","🌧️","🔥","🧊","🌀","💥","🪫","😵","🤯","😓","💢","🫨","🪤","🎭","🌊","🏃","🔔","🛑"]

  private var allCategories: [TriggerEpisode.TriggerCategory] {
    TriggerEpisode.categories + customStore.triggers
  }

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
        .padding(.bottom, 20)

        ScrollView {
          VStack(spacing: 20) {
            // Trigger grid
            LazyVGrid(columns: columns, spacing: 12) {
              ForEach(allCategories, id: \.key) { cat in
                TriggerCategoryChip(
                  category: cat,
                  isSelected: selectedCategory?.key == cat.key,
                  isCustom: cat.key.hasPrefix("custom_"),
                  onTap: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                      selectedCategory = selectedCategory?.key == cat.key ? nil : cat
                    }
                    HapticManager.shared.lightImpact()
                  },
                  onDelete: cat.key.hasPrefix("custom_") ? {
                    customStore.remove(withKey: cat.key)
                    if selectedCategory?.key == cat.key { selectedCategory = nil }
                  } : nil
                )
              }

              // + Custom chip
              Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) { showCustomForm.toggle() }
                HapticManager.shared.lightImpact()
              }) {
                HStack(spacing: 8) {
                  Image(systemName: showCustomForm ? "minus" : "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                  Text("Custom trigger")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1))
                )
              }
              .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)

            // Custom trigger form
            if showCustomForm {
              customTriggerForm
                .padding(.horizontal, 24)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Severity picker
            severityPicker
              .padding(.horizontal, 24)

            // Note
            VStack(spacing: 12) {
              if showNoteField {
                TextField("What happened? (optional)", text: $noteText, axis: .vertical)
                  .lineLimit(3...5)
                  .padding(12)
                  .background(Color.white.opacity(0.12))
                  .foregroundColor(.white)
                  .cornerRadius(12)
                  .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
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
            .padding(.bottom, 8)
          }
        }

        // Action buttons
        VStack(spacing: 12) {
          Button(action: logEpisode) {
            Text("Log it")
              .font(.title3).fontWeight(.semibold)
              .foregroundColor(Color(hex: "#1B3D5E"))
              .frame(maxWidth: .infinity)
              .padding(.vertical, 16)
              .background(selectedCategory != nil ? Color.white : Color.white.opacity(0.3))
              .cornerRadius(14)
          }
          .disabled(selectedCategory == nil)
          .animation(.easeInOut(duration: 0.2), value: selectedCategory?.key)
          .padding(.horizontal, 24)

          Button("Skip for now") { dismiss() }
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 24)
      }
    }
  }

  // MARK: - Severity Picker

  private var severityPicker: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("How intense was it?")
          .font(.subheadline).fontWeight(.medium)
          .foregroundColor(.white.opacity(0.85))
        Spacer()
        if let s = severity {
          Text(severityLabel(s))
            .font(.caption).fontWeight(.semibold)
            .foregroundColor(severityColor(s))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(severityColor(s).opacity(0.15)))
        } else {
          Text("Optional")
            .font(.caption)
            .foregroundColor(.white.opacity(0.35))
        }
      }
      HStack(spacing: 6) {
        ForEach(1...10, id: \.self) { i in
          Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
              severity = severity == i ? nil : i
            }
            HapticManager.shared.lightImpact()
          }) {
            Text("\(i)")
              .font(.system(size: 12, weight: severity == i ? .bold : .regular))
              .foregroundColor(severity == i ? Color(hex: "#1B3D5E") : .white.opacity(0.7))
              .frame(width: 30, height: 30)
              .background(
                Circle().fill(severity == i ? Color.white : Color.white.opacity(0.12))
              )
          }
          .buttonStyle(PlainButtonStyle())
          .scaleEffect(severity == i ? 1.12 : 1.0)
        }
      }
      HStack {
        Text("Mild").font(.caption2).foregroundColor(.white.opacity(0.35))
        Spacer()
        Text("Severe").font(.caption2).foregroundColor(.white.opacity(0.35))
      }
    }
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.white.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1))
    )
  }

  private func severityLabel(_ s: Int) -> String {
    switch s {
    case 1...3: return "Mild"
    case 4...6: return "Moderate"
    case 7...8: return "High"
    default:    return "Severe"
    }
  }

  private func severityColor(_ s: Int) -> Color {
    switch s {
    case 1...3: return Color(hex: "#3AAA8C")
    case 4...6: return Color(hex: "#D4882A")
    default:    return Color(hex: "#C0514F")
    }
  }

  // MARK: - Custom Trigger Form

  private var customTriggerForm: some View {
    VStack(spacing: 12) {
      // Emoji picker row
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(emojiOptions, id: \.self) { emoji in
            Button(action: { customEmoji = emoji }) {
              Text(emoji)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(
                  Circle().fill(customEmoji == emoji ? Color.white : Color.white.opacity(0.12))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(customEmoji == emoji ? 1.15 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: customEmoji)
          }
        }
        .padding(.horizontal, 2)
      }

      // Label field
      TextField("Name it (e.g. Traffic jam)", text: $customLabel)
        .padding(10)
        .background(Color.white.opacity(0.12))
        .foregroundColor(.white)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .tint(.white)

      // Add button
      Button(action: addCustomTrigger) {
        Text("Add trigger")
          .font(.subheadline).fontWeight(.semibold)
          .foregroundColor(customLabel.trimmingCharacters(in: .whitespaces).isEmpty ? .white.opacity(0.3) : Color(hex: "#1B3D5E"))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 10)
          .background(customLabel.trimmingCharacters(in: .whitespaces).isEmpty ? Color.white.opacity(0.15) : Color.white)
          .cornerRadius(10)
      }
      .disabled(customLabel.trimmingCharacters(in: .whitespaces).isEmpty)
    }
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.white.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1))
    )
  }

  // MARK: - Actions

  private func addCustomTrigger() {
    let label = customLabel.trimmingCharacters(in: .whitespaces)
    guard !label.isEmpty else { return }
    customStore.add(label: label, emoji: customEmoji)
    HapticManager.shared.success()
    customLabel = ""
    withAnimation { showCustomForm = false }
  }

  private func logEpisode() {
    guard let cat = selectedCategory else { return }
    let episode = TriggerEpisode(
      triggerKey: cat.key,
      triggerLabel: cat.label,
      triggerEmoji: cat.emoji,
      note: noteText.isEmpty ? nil : noteText,
      outcome: outcome,
      severity: severity
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
  let isCustom: Bool
  let onTap: () -> Void
  let onDelete: (() -> Void)?

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 10) {
        Text(category.emoji).font(.title3)
        Text(category.label)
          .font(.subheadline)
          .fontWeight(isSelected ? .semibold : .regular)
          .foregroundColor(isSelected ? Color(hex: "#1B3D5E") : .white)
          .lineLimit(1)
          .minimumScaleFactor(0.85)
        Spacer()
        if isCustom, let onDelete {
          Button(action: onDelete) {
            Image(systemName: "xmark")
              .font(.system(size: 9, weight: .bold))
              .foregroundColor(isSelected ? Color(hex: "#1B3D5E").opacity(0.5) : .white.opacity(0.35))
          }
          .buttonStyle(PlainButtonStyle())
        }
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
