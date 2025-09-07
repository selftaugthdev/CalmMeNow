import AVFoundation
import Foundation

class SpeechService: NSObject, ObservableObject {
  private let synthesizer = AVSpeechSynthesizer()
  @Published var isSpeaking = false

  override init() {
    super.init()
    synthesizer.delegate = self

    // Only log voices in debug builds with special flag
    #if DEBUG && DEBUG_TTS_DIAG
      logAvailableVoices()
    #endif
  }

  // MARK: - Enhanced Voice Selection

  func getAvailableVoices() -> [AVSpeechSynthesisVoice] {
    return AVSpeechSynthesisVoice.speechVoices()
  }

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

    // Look for the most natural-sounding compact voices
    let naturalVoiceIdentifiers = [
      // Siri voices (most natural)
      "com.apple.ttsbundle.siri_female_en-US_compact",
      "com.apple.ttsbundle.siri_male_en-US_compact",
      // Samantha and Alex (classic natural voices)
      "com.apple.ttsbundle.samantha-compact",
      "com.apple.ttsbundle.alex-compact",
      // Other natural-sounding voices
      "com.apple.ttsbundle.veena-compact",
      "com.apple.ttsbundle.daniel-compact",
      "com.apple.ttsbundle.karen-compact",
      "com.apple.ttsbundle.moira-compact",
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

  // Helper function to check what voices are available (for debugging only)
  #if DEBUG && DEBUG_TTS_DIAG
    func logAvailableVoices() {
      let voices = AVSpeechSynthesisVoice.speechVoices()
      print("=== Available Voices ===")
      for voice in voices {
        print("Name: \(voice.name)")
        print("  Identifier: \(voice.identifier)")
        print("  Quality: \(voice.quality.rawValue)")
        print("  Language: \(voice.language)")
        print("---")
      }
    }
  #endif

  func speak(_ text: String, rate: Float = 0.5, pitch: Float = 1.0) {
    let utterance = AVSpeechUtterance(string: text)

    // Use the most natural voice available
    let selectedVoice = defaultCalmVoice()
    utterance.voice = selectedVoice

    #if DEBUG
      print("🎤 Using voice: \(selectedVoice.name) (\(selectedVoice.quality.rawValue))")
    #endif

    // Optimized settings for calm, natural sound
    utterance.rate = min(max(rate, 0.45), 0.55)  // Calm pace
    utterance.pitchMultiplier = 1.0  // Natural pitch
    utterance.volume = 0.9  // Keep under full to soften the sound
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

  func stop() {
    synthesizer.stopSpeaking(at: .immediate)
    isSpeaking = false
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

extension SpeechService: AVSpeechSynthesizerDelegate {
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
