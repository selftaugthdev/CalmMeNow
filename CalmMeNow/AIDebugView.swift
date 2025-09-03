import FirebaseFunctions
import SwiftUI

struct AIDebugView: View {
  @State private var planText = "—"
  @State private var coachText = "—"
  @State private var isLoadingPlan = false
  @State private var isLoadingCoach = false
  @State private var errorText: String?

  var body: some View {
    NavigationView {
      List {
        Section("Personalized Panic Plan") {
          Button(action: {
            Task {
              isLoadingPlan = true
              defer { isLoadingPlan = false }
              do {
                let intake: [String: Any] = [
                  "triggers": ["crowded places"],
                  "symptoms": ["racing heart", "dizzy"],
                  "preferences": ["breathing", "grounding"],
                  "duration": 120,
                  "phrase": "This will pass; I'm safe.",
                ]
                let plan = try await AiService.shared.generatePanicPlan(intake: intake)
                planText = pretty(plan)
              } catch {
                errorText = describe(error)
                print("Callable error:", describe(error))
              }
            }
          }) {
            HStack {
              Text("Generate Plan")
              if isLoadingPlan { ProgressView().padding(.leading, 8) }
            }
          }
          Text(planText).font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
        }

        Section("Daily Check-in Coach") {
          Button(action: {
            Task {
              isLoadingCoach = true
              defer { isLoadingCoach = false }
              do {
                let checkin: [String: Any] = [
                  "mood": 3,  // 0–5 your scale
                  "tags": ["poor-sleep", "work-stress"],
                  "note": "Heart feels jumpy before meetings.",
                ]
                let coach = try await AiService.shared.dailyCheckIn(checkin: checkin)
                coachText = pretty(coach)
              } catch {
                errorText = describe(error)
                print("Callable error:", describe(error))
              }
            }
          }) {
            HStack {
              Text("Run Check-in")
              if isLoadingCoach { ProgressView().padding(.leading, 8) }
            }
          }
          Text(coachText).font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
        }

        if let e = errorText {
          Section("Error") { Text(e).foregroundColor(.red) }
        }
      }
      .navigationTitle("AI Debug")
      .onAppear {
        // Log our region and function names once
        print("Using Functions region:", Functions.functions(region: "europe-west1"))
      }
    }
  }

  // Helper function to get better error descriptions
  private func describe(_ error: Error) -> String {
    let ns = error as NSError
    if ns.domain == FunctionsErrorDomain {
      let code = FunctionsErrorCode(rawValue: ns.code) ?? .unknown
      let details = ns.userInfo[FunctionsErrorDetailsKey] as? String
      return "Functions error (\(code.rawValue)): \(details ?? ns.localizedDescription)"
    }
    return ns.localizedDescription
  }

  private func pretty(_ dict: [String: Any]) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted]),
      let s = String(data: data, encoding: .utf8)
    else { return "\(dict)" }
    return s
  }
}
