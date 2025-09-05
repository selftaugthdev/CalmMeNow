import AVFoundation
import SwiftUI

struct EmergencyCompanionAIView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var speechService = SpeechService()
  private let hapticManager = HapticManager.shared

  @State private var script: [String: Any] = [:]
  @State private var isLoading = false
  @State private var error: String?
  @State private var showingStepRunner = false

  var body: some View {
    NavigationView {
      ZStack {
        // Background gradient
        LinearGradient(
          gradient: Gradient(colors: [
            Color(hex: "#FFF5F5"),
            Color(hex: "#FEF2F2"),
            Color(hex: "#FEE2E2"),
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 24) {
          // Header
          VStack(spacing: 16) {
            Text("🚨")
              .font(.system(size: 60))

            Text("Emergency Companion")
              .font(.largeTitle)
              .fontWeight(.bold)
              .foregroundColor(.primary)

            Text("AI-powered emergency support for severe moments")
              .font(.body)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 20)
          }
          .padding(.top, 20)

          Spacer()

          if isLoading {
            VStack(spacing: 16) {
              ProgressView()
                .scaleEffect(1.5)

              Text("Preparing your emergency plan...")
                .font(.headline)
                .foregroundColor(.primary)

              Text("This will take just a moment")
                .font(.body)
                .foregroundColor(.secondary)
            }
          } else if !script.isEmpty {
            VStack(spacing: 20) {
              Text("✅ Emergency Plan Ready")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)

              Text("Your personalized emergency plan is ready to guide you through this moment.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

              Button(action: {
                showingStepRunner = true
              }) {
                HStack(spacing: 12) {
                  Image(systemName: "play.circle.fill")
                    .font(.title2)
                  Text("Start Emergency Plan")
                    .font(.headline)
                    .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(
                  RoundedRectangle(cornerRadius: 25)
                    .fill(Color.red)
                )
              }
            }
          } else {
            VStack(spacing: 20) {
              Text("Need immediate help?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

              Text(
                "I'll create a personalized emergency plan designed for severe moments, with step-by-step guidance, voice instructions, and calming techniques."
              )
              .font(.body)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 20)

              Button(action: fetchEmergencyPlan) {
                HStack(spacing: 12) {
                  Image(systemName: "bolt.fill")
                    .font(.title2)
                  Text("Start Emergency Companion")
                    .font(.headline)
                    .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(
                  RoundedRectangle(cornerRadius: 25)
                    .fill(Color.red)
                )
              }
            }
          }

          if let error = error {
            VStack(spacing: 12) {
              Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundColor(.red)

              Text("Something went wrong")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

              Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            }
            .padding(20)
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
          }

          Spacer()
        }
        .padding(.horizontal, 20)
      }
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarItems(
        leading: Button("Close") {
          presentationMode.wrappedValue.dismiss()
        }
        .foregroundColor(.blue)
      )
      .sheet(isPresented: $showingStepRunner) {
        EmergencyStepRunnerView(script: script)
      }
    }
  }

  private func fetchEmergencyPlan() {
    isLoading = true
    error = nil
    script = [:]

    let intake: [String: Any] = [
      "context": "emergency",
      "severity": "severe",
      "pref_breath": "478",
      "duration": "short",
    ]

    Task {
      do {
        let result = try await AiService.shared.generatePanicPlan(intake: intake)
        await MainActor.run {
          script = result
          isLoading = false
        }
      } catch {
        await MainActor.run {
          self.error = error.localizedDescription
          isLoading = false
        }
      }
    }
  }
}

#Preview {
  EmergencyCompanionAIView()
}
