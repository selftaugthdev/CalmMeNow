import AVFoundation
import SwiftUI
import UIKit

/// Helper utilities for TTS voice management and settings
final class TTSVoiceHelper {

  // MARK: - Voice Quality Detection

  /// Checks if the user has any Enhanced voices available
  static func hasEnhancedVoices() -> Bool {
    let voices = AVSpeechSynthesisVoice.speechVoices()
    return voices.contains { $0.quality == .enhanced }
  }

  /// Checks if the current best voice for user's locale is Enhanced
  static func hasEnhancedVoiceForCurrentLocale() -> Bool {
    return bestVoiceForCurrentLocale()?.quality == .enhanced
  }

  /// Returns the best voice for the user's current locale, favoring Enhanced voices
  static func bestVoiceForCurrentLocale() -> AVSpeechSynthesisVoice? {
    let lang = Locale.current.identifier  // e.g. "en_BE" → iOS maps sensibly

    // 1) Get voices that match the user's language
    let matches = AVSpeechSynthesisVoice.speechVoices().filter {
      $0.language.hasPrefix(String(lang.prefix(2)))
    }

    // 2) Prefer Enhanced, else default
    return matches.first(where: { $0.quality == .enhanced })
      ?? matches.first
      ?? AVSpeechSynthesisVoice(language: "en-GB")  // good fallback near "Daniel"
  }

  /// Returns the current voice being used by the app
  static func getCurrentVoice() -> AVSpeechSynthesisVoice? {
    return bestVoiceForCurrentLocale()
  }

  /// Returns all available voices
  static func getAvailableVoices() -> [AVSpeechSynthesisVoice] {
    return AVSpeechSynthesisVoice.speechVoices()
  }

  // MARK: - Settings Deep Link

  /// Opens iOS Settings to Spoken Content where users can download Enhanced voices
  static func openSpokenContentSettings() {
    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
      print("Could not create settings URL")
      return
    }

    if UIApplication.shared.canOpenURL(settingsUrl) {
      UIApplication.shared.open(settingsUrl) { success in
        if success {
          print("Opened iOS Settings")
        } else {
          print("Failed to open iOS Settings")
        }
      }
    }
  }

  /// Shows an alert with instructions for downloading Enhanced voices
  static func showEnhancedVoiceInstructions() {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
      let window = windowScene.windows.first,
      let rootViewController = window.rootViewController
    else {
      return
    }

    let alert = UIAlertController(
      title: "Improve Voice Quality",
      message:
        "For the best listening experience, download Enhanced voices in Settings → Accessibility → Spoken Content → Voices. Enhanced voices sound much more natural and calming.",
      preferredStyle: .alert
    )

    alert.addAction(
      UIAlertAction(title: "Open Settings", style: .default) { _ in
        openSpokenContentSettings()
      })

    alert.addAction(UIAlertAction(title: "Maybe Later", style: .cancel))

    rootViewController.present(alert, animated: true)
  }

  // MARK: - Voice Information

  /// Returns a user-friendly description of the current voice quality
  static func getCurrentVoiceDescription() -> String {
    guard let voice = getCurrentVoice() else {
      return "Default Voice"
    }

    switch voice.quality {
    case .enhanced:
      return "\(voice.name) (Enhanced)"
    case .premium:
      return "\(voice.name) (Premium)"
    case .default:
      return "\(voice.name) (Standard)"
    @unknown default:
      return voice.name
    }
  }

  /// Returns a localized message about voice quality
  static func getVoiceQualityMessage() -> String {
    if hasEnhancedVoiceForCurrentLocale() {
      return "Using high-quality voice for better experience"
    } else {
      return "Download Enhanced voices in Settings for better quality"
    }
  }
}
