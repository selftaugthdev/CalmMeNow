import AVFoundation
import Foundation

class SpeechService: NSObject, ObservableObject {
  @Published var isSpeaking = false

  // ElevenLabs pre-recorded voice files
  private var voicePlayer: AVAudioPlayer?

  // Fallback synthesizer for any phrase not covered by a file
  private let synthesizer = AVSpeechSynthesizer()

  // Maps normalized phrase text → bundled audio filename (without extension)
  private let voiceFileMap: [String: String] = [
    // Breathing cues
    "inhale":                        "voice_inhale",
    "inhale slowly…":                "voice_inhale_slow",
    "inhale slowly":                 "voice_inhale_slow",
    "hold":                          "voice_hold",
    "exhale":                        "voice_exhale",
    "long exhale":                   "voice_exhale_long",
    "long exhale…":                  "voice_exhale_long",
    "top off inhale":                "voice_top_off",
    "top off your inhale":           "voice_top_off",
    "well done":                     "voice_well_done",
    "relax":                         "voice_relax",
    "now relax.":                    "voice_now_relax",

    // Breathing program openers
    "starting physiological sigh. follow the visual guide.":      "voice_starting_sigh",
    "starting box breathing. follow the visual guide.":           "voice_starting_box",
    "starting resonance breathing. follow the visual guide.":     "voice_starting_resonance",
    "starting coherence breathing. follow the visual guide.":     "voice_starting_resonance",
    "starting 4-7-8 breathing. follow the visual guide.":         "voice_starting_478",
    "starting 4-7-8 technique. follow the visual guide.":         "voice_starting_478",
    "starting wim hof style. follow the visual guide.":           "voice_starting_wim",
    "starting wim hof style breathing. follow the visual guide.": "voice_starting_wim",

    // Grounding (5-4-3-2-1)
    "let's ground yourself using your five senses. take your time with each step.": "voice_grounding_intro",
    "look around you. name 5 things you can see.":              "voice_grounding_see",
    "feel 4 things you can physically touch right now.":        "voice_grounding_touch",
    "listen carefully. name 3 things you can hear.":            "voice_grounding_hear",
    "notice 2 things you can smell around you.":                "voice_grounding_smell",
    "notice 1 thing you can taste right now.":                  "voice_grounding_taste",
    "well done. you are here. you are grounded.":               "voice_grounding_complete",

    // PMR intro & outro
    "progressive muscle relaxation. we'll tense and relax each muscle group. let's begin.": "voice_pmr_intro",
    "wonderful. you've completed the full body relaxation. notice how calm and relaxed you feel.": "voice_pmr_complete",

    // PMR tense
    "hands & forearms. make tight fists and tense your forearms":  "voice_pmr_tense_hands",
    "upper arms. bend your elbows and flex your biceps":            "voice_pmr_tense_arms",
    "forehead. raise your eyebrows as high as you can":             "voice_pmr_tense_forehead",
    "eyes & cheeks. squeeze your eyes shut tightly":                "voice_pmr_tense_eyes",
    "mouth & jaw. clench your jaw and press your lips together":    "voice_pmr_tense_jaw",
    "neck. gently press your head back":                            "voice_pmr_tense_neck",
    "shoulders. raise your shoulders up toward your ears":          "voice_pmr_tense_shoulders",
    "chest. take a deep breath and hold it":                        "voice_pmr_tense_chest",
    "stomach. tighten your stomach muscles":                        "voice_pmr_tense_stomach",
    "legs & feet. point your toes and tense your legs":             "voice_pmr_tense_legs",

    // PMR relax
    "now relax. release and let your hands go limp":         "voice_pmr_relax_hands",
    "now relax. let your arms fall heavy and relaxed":       "voice_pmr_relax_arms",
    "now relax. let your forehead smooth out completely":    "voice_pmr_relax_forehead",
    "now relax. let your eyes relax and soften":             "voice_pmr_relax_eyes",
    "now relax. let your jaw drop slightly open":            "voice_pmr_relax_jaw",
    "now relax. let your neck relax and feel heavy":         "voice_pmr_relax_neck",
    "now relax. drop your shoulders down and relax":         "voice_pmr_relax_shoulders",
    "now relax. exhale slowly and let your chest relax":     "voice_pmr_relax_chest",
    "now relax. release and let your belly soften":          "voice_pmr_relax_stomach",
    "now relax. let your legs go completely limp":           "voice_pmr_relax_legs",

    // Night Protocol
    "you're safe. you're home. take a breath.":  "voice_night_safe",
    "breathe in… hold… let it all go.":          "voice_night_breathe",
  ]

  override init() {
    super.init()
    synthesizer.delegate = self
  }

  // MARK: - Public

  func speak(_ text: String, rate: Float = 0.5, pitch: Float = 1.0) {
    let key = text.lowercased().trimmingCharacters(in: .whitespaces)

    if let filename = voiceFileMap[key] {
      playVoiceFile(filename)
    } else {
      speakWithSynthesizer(text, rate: rate, pitch: pitch)
    }
  }

  func stop() {
    voicePlayer?.stop()
    voicePlayer = nil
    synthesizer.stopSpeaking(at: .immediate)
    isSpeaking = false
  }

  func stopAll() {
    stop()
    deactivateAudioSession()
  }

  func pause() {
    voicePlayer?.pause()
    synthesizer.pauseSpeaking(at: .immediate)
  }

  func continueSpeaking() {
    voicePlayer?.play()
    synthesizer.continueSpeaking()
  }

  // MARK: - Private

  private func playVoiceFile(_ filename: String) {
    guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
      #if DEBUG
        print("SpeechService: Missing voice file '\(filename).mp3', falling back to synthesizer")
      #endif
      speakWithSynthesizer(filename.replacingOccurrences(of: "_", with: " "))
      return
    }

    configureAudioSession()

    do {
      voicePlayer?.stop()
      voicePlayer = try AVAudioPlayer(contentsOf: url)
      voicePlayer?.delegate = self
      voicePlayer?.volume = 1.0
      voicePlayer?.play()
      isSpeaking = true
    } catch {
      #if DEBUG
        print("SpeechService: Failed to play voice file \(filename): \(error)")
      #endif
    }
  }

  private func speakWithSynthesizer(_ text: String, rate: Float = 0.5, pitch: Float = 1.0) {
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = bestAvailableVoice()
    utterance.rate = min(max(rate, 0.45), 0.55)
    utterance.pitchMultiplier = 1.0
    utterance.volume = 0.9

    configureAudioSession()
    isSpeaking = true
    synthesizer.speak(utterance)
  }

  private func configureAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
      try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      #if DEBUG
        print("SpeechService: Audio session error: \(error)")
      #endif
    }
  }

  private func deactivateAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    } catch {}
  }

  private func bestAvailableVoice() -> AVSpeechSynthesisVoice? {
    let all = AVSpeechSynthesisVoice.speechVoices()
    return all.first(where: { $0.name.lowercased().contains("daniel") })
      ?? all.first(where: { $0.name.lowercased().contains("alex") })
      ?? all.first(where: { $0.quality == .enhanced })
      ?? AVSpeechSynthesisVoice(language: "en-GB")
  }
}

// MARK: - AVAudioPlayerDelegate

extension SpeechService: AVAudioPlayerDelegate {
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    DispatchQueue.main.async { self.isSpeaking = false }
  }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechService: AVSpeechSynthesizerDelegate {
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    DispatchQueue.main.async { self.isSpeaking = false }
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    DispatchQueue.main.async { self.isSpeaking = false }
  }
}
