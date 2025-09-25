import SwiftUI

struct PlanEditorView: View {
  @Environment(\.presentationMode) var presentationMode
  @State private var name: String = ""
  @State private var description: String = ""
  @State private var steps: [PlanStep] = []
  @State private var duration: TimeInterval = 120
  @State private var showLibrary = false
  @State private var replaceIndex: Int? = nil
  @State private var editMode: EditMode = .active

  let plan: PanicPlan?
  let onSave: (PanicPlan) -> Void

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Plan Details")) {
          TextField("Plan Name", text: $name)
          TextField("Description", text: $description, axis: .vertical)
            .lineLimit(2...4)
        }

        Section(header: Text("Steps")) {
          Text("Add short, concrete steps.").font(.caption).foregroundColor(.secondary)

          List {
            ForEach($steps) { $step in
              VStack(alignment: .leading, spacing: 8) {
                HStack {
                  Label(step.type.displayName, systemImage: step.type.icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                  Spacer()
                  Menu {
                    Button("Replace from Library") {
                      replaceIndex = steps.firstIndex(where: { $0.id == step.id })
                      showLibrary = true
                    }
                    Button("Duplicate") {
                      if let index = steps.firstIndex(where: { $0.id == step.id }) {
                        steps.insert(step, at: index + 1)
                      }
                    }
                    Divider()
                    Button(
                      role: .destructive,
                      action: {
                        steps.removeAll { $0.id == step.id }
                      }
                    ) {
                      Label("Delete", systemImage: "trash")
                    }
                  } label: {
                    Image(systemName: "ellipsis.circle")
                      .foregroundColor(.secondary)
                  }
                }

                TextField("Describe the step (e.g., Box breathing…)", text: $step.text)
                  .textFieldStyle(.roundedBorder)

                HStack {
                  StepTypePicker(selection: $step.type)
                  Spacer()
                  StepSecondsField(seconds: $step.seconds)
                }
              }
              .padding(.vertical, 4)
            }
            .onMove { from, to in
              steps.move(fromOffsets: from, toOffset: to)
            }
          }
          .environment(\.editMode, $editMode)

          Button {
            showLibrary = true
            replaceIndex = nil  // adding new
          } label: {
            Label("Add Step", systemImage: "plus.circle.fill")
          }
        }

        Section(header: Text("Duration")) {
          HStack {
            Text("Duration")
            Spacer()
            Stepper(value: $duration, in: 60...600, step: 30) {
              Text(
                "\(Int(duration / 60)) min \(Int(duration.truncatingRemainder(dividingBy: 60))) sec"
              )
            }
          }
        }
      }
      .navigationTitle("Edit Plan")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
          }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Save") {
            let newPlan = PanicPlan(
              title: name,
              description: description,
              steps: steps.filter {
                !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              },
              duration: Int(duration),
              techniques: Array(Set(steps.map { $0.type.displayName })),
              emergencyContact: nil,
              personalizedPhrase: "I am safe and I can handle this"
            )
            onSave(newPlan)
            presentationMode.wrappedValue.dismiss()
          }
          .disabled(name.isEmpty || steps.isEmpty)
        }
      }
      .sheet(isPresented: $showLibrary) {
        StepLibrarySheet { chosen in
          if let i = replaceIndex {
            steps[i] = chosen
          } else {
            steps.append(chosen)
          }
        }
      }
      .onAppear {
        if let plan = plan {
          name = plan.title
          description = plan.description
          steps = plan.steps
          duration = TimeInterval(plan.duration)
        } else {
          name = "My Panic Plan"
          description = "Personalized plan for managing panic attacks"
          steps = [
            StepLibrary.breathing[0],
            StepLibrary.grounding[0],
            StepLibrary.affirmation[1],
          ]
        }
      }
    }
  }
}

// MARK: - Step Type Picker

struct StepTypePicker: View {
  @Binding var selection: StepType

  var body: some View {
    Menu {
      ForEach(StepType.allCases) { type in
        Button {
          selection = type
        } label: {
          Label(type.displayName, systemImage: type.icon)
        }
      }
    } label: {
      Label(selection.displayName, systemImage: selection.icon)
    }
    .font(.caption)
    .foregroundColor(.blue)
  }
}

// MARK: - Step Seconds Field

struct StepSecondsField: View {
  @Binding var seconds: Int?

  var body: some View {
    Menu {
      Button("No timer") { seconds = nil }
      ForEach([15, 20, 30, 45, 60, 90, 120], id: \.self) { s in
        Button("\(s)s") { seconds = s }
      }
    } label: {
      Label(seconds.map { "\($0)s" } ?? "No timer", systemImage: "timer")
    }
    .font(.caption)
    .foregroundColor(.secondary)
  }
}

// MARK: - Step Library Sheet

struct StepLibrarySheet: View {
  var onPick: (PlanStep) -> Void
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      List {
        ForEach(StepLibrary.categories, id: \.title) { category in
          Section(category.title) {
            ForEach(category.steps) { step in
              Button {
                onPick(step)
                dismiss()
              } label: {
                VStack(alignment: .leading, spacing: 4) {
                  HStack {
                    Image(systemName: step.type.icon)
                      .foregroundColor(.blue)
                      .frame(width: 20)
                    Text(step.text)
                      .foregroundColor(.primary)
                    Spacer()
                  }

                  if let seconds = step.seconds {
                    Text("\(seconds)s • \(step.type.displayName)")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                }
                .padding(.vertical, 2)
              }
            }
          }
        }

        Section {
          Button {
            onPick(PlanStep(type: .custom, text: "", seconds: nil))
            dismiss()
          } label: {
            Label("Custom Step", systemImage: "square.and.pencil")
              .foregroundColor(.blue)
          }
        }
      }
      .navigationTitle("Add a Step")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Close") { dismiss() }
        }
      }
    }
  }
}

#Preview {
  PlanEditorView(plan: nil) { _ in }
}
