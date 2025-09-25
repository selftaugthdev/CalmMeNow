import AVFoundation
import Foundation

/// Production-ready TTS service with proper cleanup and safe voice selection
final class SessionTTS: NSObject, ObservableObject {
  private let synthesizer = AVSpeechSynthesizer()
  @Published var isSpeaking = false

  override init() {
    super.init()
    synthesizer.delegate = self

    #if DEBUG
      // Log available voices on initialization to help debug voice selection
      logAvailableVoices()
    #endif
  }

  deinit {
    stopAll()
  }

  // MARK: - Debug Methods

  #if DEBUG
    func logAvailableVoices() {
      let voices = AVSpeechSynthesisVoice.speechVoices()
      print("=== Available Voices for SessionTTS ===")
      for voice in voices {
        print("Name: \(voice.name)")
        print("  Identifier: \(voice.identifier)")
        print("  Quality: \(voice.quality.rawValue)")
        print("  Language: \(voice.language)")
        print("---")
      }
    }
  #endif

  // MARK: - Enhanced Voice Selection

  /// Returns the best voice for the user's current locale, favoring Enhanced voices
  private func bestVoiceForCurrentLocale() -> AVSpeechSynthesisVoice? {
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

  /// Returns the most natural-sounding voice available for the user's locale
  private func defaultCalmVoice() -> AVSpeechSynthesisVoice {
    // First, try to get Alex or Daniel specifically (the most natural, less robotic voices)
    if let alexVoice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.alex-compact") {
      #if DEBUG
        print("🎤 Found Alex voice: \(alexVoice.name)")
      #endif
      return alexVoice
    }

    if let danielVoice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.daniel-compact") {
      #if DEBUG
        print("🎤 Found Daniel voice: \(danielVoice.name)")
      #endif
      return danielVoice
    }

    // Try enhanced versions
    if let alexEnhanced = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.alex-premium") {
      #if DEBUG
        print("🎤 Found Alex Enhanced voice: \(alexEnhanced.name)")
      #endif
      return alexEnhanced
    }

    if let danielEnhanced = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.daniel-premium")
    {
      #if DEBUG
        print("🎤 Found Daniel Enhanced voice: \(danielEnhanced.name)")
      #endif
      return danielEnhanced
    }

    // First try to get the best voice for current locale
    if let bestVoice = bestVoiceForCurrentLocale() {
      return bestVoice
    }

    // Fallback to enhanced voices in any language
    let allVoices = AVSpeechSynthesisVoice.speechVoices()
    if let enhancedVoice = allVoices.first(where: { voice in
      voice.quality == .enhanced || voice.quality == .premium
    }) {
      return enhancedVoice
    }

    // Look for the most natural-sounding voices (prioritizing deeper, less robotic voices)
    let naturalVoiceIdentifiers = [
      // Alex and Daniel (most natural, deeper voices)
      "com.apple.ttsbundle.alex-compact",
      "com.apple.ttsbundle.daniel-compact",
      // Enhanced versions if available
      "com.apple.ttsbundle.alex-premium",
      "com.apple.ttsbundle.daniel-premium",
      // Other natural-sounding voices
      "com.apple.ttsbundle.samantha-compact",
      "com.apple.ttsbundle.karen-compact",
      "com.apple.ttsbundle.moira-compact",
      // Siri voices (more natural but higher pitched)
      "com.apple.ttsbundle.siri_male_en-US_compact",
      "com.apple.ttsbundle.siri_female_en-US_compact",
      // Other voices
      "com.apple.ttsbundle.veena-compact",
    ]

    for identifier in naturalVoiceIdentifiers {
      if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
        return voice
      }
    }

    // Fallback to any compact voice that's not novelty
    for voice in allVoices {
      if voice.quality == .default && !voice.name.lowercased().contains("bells")
        && !voice.name.lowercased().contains("organ")
        && !voice.name.lowercased().contains("trinoids")
        && !voice.name.lowercased().contains("zarvox")
      {
        return voice
      }
    }

    // Final fallback to system default
    return AVSpeechSynthesisVoice(language: "en-US") ?? allVoices.first!
  }

  // MARK: - Speech Control

  func speak(_ text: String, rate: Float = 0.5) {
    let utterance = AVSpeechUtterance(string: text)

    // Use the most natural voice available
    let selectedVoice = defaultCalmVoice()
    utterance.voice = selectedVoice

    #if DEBUG
      print(
        "🎤 SessionTTS Using voice: \(selectedVoice.name) (\(selectedVoice.quality.rawValue)) - \(selectedVoice.identifier)"
      )
    #endif
    utterance.rate = min(max(rate, 0.45), 0.55)  // calmer cadence (0.45–0.55 feels natural)
    utterance.pitchMultiplier = 1.0
    utterance.preUtteranceDelay = 0.0
    utterance.postUtteranceDelay = 0.0

    // Configure audio session for playback
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
      try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      print("Failed to configure audio session: \(error)")
    }

    isSpeaking = true
    synthesizer.speak(utterance)
  }

  func stopAll() {
    if synthesizer.isSpeaking {
      synthesizer.stopSpeaking(at: .immediate)
    }

    do {
      try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    } catch {
      print("Failed to deactivate audio session: \(error)")
    }

    isSpeaking = false
  }

  func pause() {
    synthesizer.pauseSpeaking(at: .immediate)
  }

  func continueSpeaking() {
    synthesizer.continueSpeaking()
  }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SessionTTS: AVSpeechSynthesizerDelegate {
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance)
  {
    DispatchQueue.main.async {
      self.isSpeaking = false
    }
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance)
  {
    DispatchQueue.main.async {
      self.isSpeaking = false
    }
  }
}
