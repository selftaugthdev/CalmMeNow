import SwiftUI

/// A banner that encourages users to download Enhanced voices for better TTS quality
struct EnhancedVoiceBanner: View {
  @State private var showInstructions = false

  var body: some View {
    if !TTSVoiceHelper.hasEnhancedVoiceForCurrentLocale() {
      VStack(spacing: 0) {
        HStack {
          Image(systemName: "speaker.wave.2.fill")
            .foregroundColor(.blue)
            .font(.title2)

          VStack(alignment: .leading, spacing: 4) {
            Text("Improve Voice Quality")
              .font(.headline)
              .foregroundColor(.primary)

            Text("Download Enhanced voices for a more natural, calming experience")
              .font(.caption)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.leading)
          }

          Spacer()

          Button("Upgrade") {
            showInstructions = true
          }
          .font(.caption)
          .foregroundColor(.blue)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Color.blue.opacity(0.1))
          .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)

        // Subtle separator
        Rectangle()
          .fill(Color(.systemGray5))
          .frame(height: 1)
          .padding(.horizontal)
      }
      .alert("Download Enhanced Voices", isPresented: $showInstructions) {
        Button("Open Settings") {
          TTSVoiceHelper.openSpokenContentSettings()
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text(
          "Go to Settings → Accessibility → Spoken Content → Voices to download Enhanced voices. They sound much more natural and provide a better calming experience."
        )
      }
    }
  }
}

/// A compact version of the banner for smaller spaces
struct CompactEnhancedVoiceBanner: View {
  @State private var showInstructions = false

  var body: some View {
    if !TTSVoiceHelper.hasEnhancedVoiceForCurrentLocale() {
      HStack {
        Image(systemName: "speaker.wave.2")
          .foregroundColor(.orange)
          .font(.caption)

        Text("Voice quality can be improved")
          .font(.caption)
          .foregroundColor(.secondary)

        Spacer()

        Button("Upgrade") {
          showInstructions = true
        }
        .font(.caption2)
        .foregroundColor(.blue)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color.orange.opacity(0.1))
      .cornerRadius(8)
      .alert("Download Enhanced Voices", isPresented: $showInstructions) {
        Button("Open Settings") {
          TTSVoiceHelper.openSpokenContentSettings()
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text(
          "Go to Settings → Accessibility → Spoken Content → Voices to download Enhanced voices for better quality."
        )
      }
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    EnhancedVoiceBanner()
    CompactEnhancedVoiceBanner()
  }
  .padding()
}
