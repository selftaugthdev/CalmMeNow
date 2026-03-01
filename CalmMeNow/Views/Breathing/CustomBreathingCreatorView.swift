import SwiftUI

struct CustomBreathingCreatorView: View {
  @Environment(\.dismiss) private var dismiss
  @ObservedObject private var service = BreathingProgramService.shared

  @State private var name = ""
  @State private var selectedEmoji = "🌬️"
  @State private var inhale: Double = 4.0
  @State private var holdAfterInhale: Double = 0.0
  @State private var exhale: Double = 6.0
  @State private var holdAfterExhale: Double = 0.0
  @State private var durationMinutes = 2

  private let emojiOptions = ["🌬️", "🫧", "⭕", "🔵", "💙", "✨", "🌿", "🔄"]
  private let durationOptions = [1, 2, 5, 10]

  private var cycleDuration: Double { inhale + holdAfterInhale + exhale + holdAfterExhale }

  private var ratioLabel: String {
    [inhale, holdAfterInhale, exhale, holdAfterExhale].map { v in
      v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(v)
    }.joined(separator: " · ")
  }

  var body: some View {
    NavigationView {
      Form {
        // MARK: Name & Icon
        Section(header: Text("Name & Icon")) {
          TextField("Program name", text: $name)

          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
              ForEach(emojiOptions, id: \.self) { emoji in
                Button(action: { selectedEmoji = emoji }) {
                  Text(emoji)
                    .font(.title2)
                    .padding(10)
                    .background(
                      RoundedRectangle(cornerRadius: 10)
                        .fill(
                          selectedEmoji == emoji
                            ? Color.blue.opacity(0.2) : Color(.systemGray6))
                    )
                    .overlay(
                      RoundedRectangle(cornerRadius: 10)
                        .stroke(
                          selectedEmoji == emoji ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
              }
            }
            .padding(.vertical, 4)
          }
        }

        // MARK: Breathing Ratio
        Section(header: Text("Breathing Ratio")) {
          PhaseSlider(label: "Inhale", value: $inhale, range: 0.5...10, step: 0.5)
          PhaseSlider(label: "Hold", value: $holdAfterInhale, range: 0...10, step: 0.5)
          PhaseSlider(label: "Exhale", value: $exhale, range: 0.5...10, step: 0.5)
          PhaseSlider(label: "Pause", value: $holdAfterExhale, range: 0...10, step: 0.5)

          HStack {
            Text("Ratio:")
              .foregroundColor(.secondary)
            Text(ratioLabel)
              .fontWeight(.semibold)
            Spacer()
            Text("Cycle: \(Int(cycleDuration))s")
              .foregroundColor(.secondary)
              .font(.caption)
          }
          .padding(.vertical, 4)
        }

        // MARK: Duration
        Section(header: Text("Duration")) {
          Picker("Duration", selection: $durationMinutes) {
            ForEach(durationOptions, id: \.self) { mins in
              Text("\(mins) min").tag(mins)
            }
          }
          .pickerStyle(SegmentedPickerStyle())
        }

        // MARK: Save
        Section {
          Button(action: save) {
            HStack {
              Spacer()
              Text("Save Program")
                .fontWeight(.semibold)
              Spacer()
            }
          }
          .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
      }
      .navigationTitle("Create Program")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
    }
  }

  private func save() {
    let program = BreathingProgram(
      name: name.trimmingCharacters(in: .whitespaces),
      emoji: selectedEmoji,
      description: "Custom \(ratioLabel) breathing program.",
      inhale: inhale,
      holdAfterInhale: holdAfterInhale,
      exhale: exhale,
      holdAfterExhale: holdAfterExhale,
      duration: durationMinutes * 60,
      category: .stress,
      style: .orb,
      isFree: true,
      isBuiltIn: false
    )
    service.saveCustom(program)
    HapticManager.shared.success()
    dismiss()
  }
}

// MARK: - Phase Slider Component

private struct PhaseSlider: View {
  let label: String
  @Binding var value: Double
  let range: ClosedRange<Double>
  let step: Double

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(label)
          .font(.subheadline)
          .foregroundColor(.primary)
        Spacer()
        Text(value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value)) s" : "\(value) s")
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundColor(.blue)
          .frame(width: 48, alignment: .trailing)
      }
      Slider(value: $value, in: range, step: step)
        .tint(.blue)
    }
    .padding(.vertical, 2)
  }
}

#Preview {
  CustomBreathingCreatorView()
}
