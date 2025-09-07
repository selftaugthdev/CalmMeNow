import AVFoundation
import Foundation

/// Production-ready TTS service with proper cleanup and safe voice selection
final class SessionTTS: NSObject, ObservableObject {
  private let synthesizer = AVSpeechSynthesizer()
  @Published var isSpeaking = false

  override init() {
    super.init()
    synthesizer.delegate = self
  }

  deinit {
    stopAll()
  }

  // MARK: - Safe Voice Selection

  /// Returns the most natural-sounding voice available for the user's locale
  private func defaultCalmVoice() -> AVSpeechSynthesisVoice {
    let allVoices = AVSpeechSynthesisVoice.speechVoices()

    // First, try to find enhanced/premium voices for user's locale
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

  // MARK: - Speech Control

  func speak(_ text: String, rate: Float = AVSpeechUtteranceDefaultSpeechRate) {
    let utterance = AVSpeechUtterance(string: text)

    // Use the most natural voice available
    let selectedVoice = defaultCalmVoice()
    utterance.voice = selectedVoice

    #if DEBUG
      print("🎤 Using voice: \(selectedVoice.name) (\(selectedVoice.quality.rawValue))")
    #endif
    utterance.rate = min(max(rate, 0.45), 0.55)  // calm pace
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
