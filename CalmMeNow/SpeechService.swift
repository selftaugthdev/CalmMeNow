import AVFoundation
import Foundation

class SpeechService: NSObject, ObservableObject {
  private let synthesizer = AVSpeechSynthesizer()
  @Published var isSpeaking = false

  override init() {
    super.init()
    synthesizer.delegate = self

    // Log available voices for debugging
    logAvailableVoices()
  }

  // MARK: - Voice Selection

  func getAvailableVoices() -> [AVSpeechSynthesisVoice] {
    return AVSpeechSynthesisVoice.speechVoices()
  }

  func getBestVoice() -> AVSpeechSynthesisVoice? {
    // Get all available voices
    let allVoices = AVSpeechSynthesisVoice.speechVoices()

    // First, try to find any enhanced or premium quality voice that's already installed
    if let enhancedVoice = allVoices.first(where: { voice in
      voice.quality == .enhanced || voice.quality == .premium
    }) {
      return enhancedVoice
    }

    // If no enhanced voices are available, try to find the best compact voice
    // Look for voices that might sound more natural even in compact form
    let preferredCompactVoices = [
      "com.apple.ttsbundle.siri_female_en-US_compact",
      "com.apple.ttsbundle.siri_male_en-US_compact",
      "com.apple.ttsbundle.samantha-compact",
      "com.apple.ttsbundle.alex-compact",
    ]

    for identifier in preferredCompactVoices {
      if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
        return voice
      }
    }

    // Final fallback to default system voice
    return AVSpeechSynthesisVoice(language: "en-US")
  }

  // Helper function to check what voices are available (for debugging)
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

  func speak(_ text: String, rate: Float = 0.4, pitch: Float = 0.9) {
    let utterance = AVSpeechUtterance(string: text)

    // Use the best available voice
    utterance.voice = getBestVoice()

    // Optimized settings for more natural sound
    utterance.rate = rate  // Slower rate (0.4-0.5) sounds less robotic
    utterance.pitchMultiplier = pitch  // Slightly lower pitch (0.9) sounds more natural/soothing
    utterance.volume = 0.9  // Keep under full to soften the sound

    isSpeaking = true
    synthesizer.speak(utterance)
  }

  func stop() {
    synthesizer.stopSpeaking(at: .immediate)
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
