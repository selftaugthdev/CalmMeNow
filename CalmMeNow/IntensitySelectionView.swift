import SwiftUI

struct IntensitySelectionView: View {
  let emotion: String
  let emoji: String
  @Binding var isPresented: Bool
  @State private var selectedIntensity: IntensityLevel?
  var onIntensitySelected: ((IntensityLevel) -> Void)?

  var body: some View {
    NavigationView {
      ZStack {
        // Background gradient
        LinearGradient(
          gradient: Gradient(colors: [
            Color(red: 0.85, green: 0.85, blue: 0.95),
            Color(red: 0.80, green: 0.90, blue: 0.95),
            Color(red: 0.85, green: 0.95, blue: 0.85),
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 40) {
          Spacer()

          // Emotion display
          VStack(spacing: 16) {
            Text(emoji)
              .font(.system(size: 60))

            Text(emotion)
              .font(.largeTitle)
              .fontWeight(.bold)
              .foregroundColor(.black)
          }

          // Question text
          Text(intensityQuestion)
            .font(.title2)
            .fontWeight(.medium)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .foregroundColor(.black)

          // Intensity buttons
          VStack(spacing: 20) {
            // Mild button
            Button(action: {
              HapticManager.shared.intensitySelection()
              selectedIntensity = .mild

              // Track intensity selection
              FirebaseAnalyticsService.shared.trackIntensitySelected(
                emotion: emotion, intensity: "mild")
            }) {
              HStack {
                Text("🟦")
                  .font(.title2)
                Text(mildButtonText)
                  .font(.title3)
                  .fontWeight(.semibold)
              }
              .frame(maxWidth: .infinity)
              .padding(.vertical, 20)
              .background(
                RoundedRectangle(cornerRadius: 16)
                  .fill(Color.blue.opacity(0.1))
                  .overlay(
                    RoundedRectangle(cornerRadius: 16)
                      .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                  )
              )
              .foregroundColor(.blue)
            }
            .scaleEffect(selectedIntensity == .mild ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: selectedIntensity)

            // Severe button
            Button(action: {
              HapticManager.shared.intensitySelection()
              selectedIntensity = .severe

              // Track intensity selection
              FirebaseAnalyticsService.shared.trackIntensitySelected(
                emotion: emotion, intensity: "severe")
            }) {
              HStack {
                Text("🟥")
                  .font(.title2)
                Text(severeButtonText)
                  .font(.title3)
                  .fontWeight(.semibold)
              }
              .frame(maxWidth: .infinity)
              .padding(.vertical, 20)
              .background(
                RoundedRectangle(cornerRadius: 16)
                  .fill(Color.red.opacity(0.1))
                  .overlay(
                    RoundedRectangle(cornerRadius: 16)
                      .stroke(Color.red.opacity(0.3), lineWidth: 2)
                  )
              )
              .foregroundColor(.red)
            }
            .scaleEffect(selectedIntensity == .severe ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: selectedIntensity)
          }
          .padding(.horizontal, 40)

          // Continue button
          if selectedIntensity != nil {
            Button(action: {
              HapticManager.shared.continueButtonTap()
              if let intensity = selectedIntensity {
                onIntensitySelected?(intensity)
                isPresented = false
              }
            }) {
              Text("Continue")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                  RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue)
                )
            }
            .padding(.horizontal, 40)
            .transition(.opacity.combined(with: .scale))
          }

          Spacer()
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarItems(
        leading: Button("Cancel") {
          HapticManager.shared.cancelButtonTap()
          isPresented = false
        }
        .foregroundColor(.blue)
      )
    }
  }

  // MARK: - Computed Properties

  private var intensityQuestion: String {
    switch emotion.lowercased() {
    case "anxious":
      return "Are you feeling a little nervous or in full panic?"
    case "angry":
      return "Are you a little annoyed or in full-on rage?"
    case "sad":
      return "Are you feeling a bit down or completely crushed?"
    case "frustrated":
      return "Are you slightly frustrated or completely overwhelmed?"
    default:
      return "How intense is this feeling right now?"
    }
  }

  private var mildButtonText: String {
    switch emotion.lowercased() {
    case "anxious":
      return "A Little Anxious"
    case "angry":
      return "A Little Angry"
    case "sad":
      return "A Bit Sad"
    case "frustrated":
      return "Slightly Frustrated"
    default:
      return "Mild"
    }
  }

  private var severeButtonText: String {
    switch emotion.lowercased() {
    case "anxious":
      return "Full Panic Mode"
    case "angry":
      return "Full Rage Mode"
    case "sad":
      return "Completely Devastated"
    case "frustrated":
      return "Completely Overwhelmed"
    default:
      return "Severe"
    }
  }
}
