//
//  AudioManager.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import AVFoundation
import SwiftUI

class AudioManager: NSObject, ObservableObject {
  static let shared = AudioManager()
  private var player: AVAudioPlayer?

  @Published var isPlaying = false
  @Published var remainingTime: TimeInterval = 0
  private var timer: Timer?
  private var fadeOutTimer: Timer?
  private var isFadingOut = false
  private var isAboutToComplete = false

  let sounds = [
    "perfect-beauty-1-min", "mixkit-jazz-sad", "mixkit-serene-anxious", "mixkit-just-chill-angry",
  ]

  override init() {
    super.init()
  }

  func playSound(_ soundName: String, loop: Bool = false) {
    print("Attempting to play sound: \(soundName), loop: \(loop)")

    // Try .mp3 first
    if let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") {
      print("Found .mp3 file: \(url)")
      playAudioFromURL(url, loop: loop)
      return
    }

    // Try .m4a if .mp3 not found
    if let url = Bundle.main.url(forResource: soundName, withExtension: "m4a") {
      print("Found .m4a file: \(url)")
      playAudioFromURL(url, loop: loop)
      return
    }

    print("Sound not found: \(soundName)")
  }

  private func playAudioFromURL(_ url: URL, loop: Bool = false) {
    do {
      player = try AVAudioPlayer(contentsOf: url)
      player?.delegate = self
      player?.numberOfLoops = loop ? -1 : 0  // -1 means infinite loop
      player?.volume = 0.0  // Start at 0 volume for fade in
      player?.play()
      isPlaying = true
      remainingTime = player?.duration ?? 0

      // Start the timer
      timer?.invalidate()
      timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
        guard let self = self else { return }
        if self.remainingTime > 0 {
          self.remainingTime -= 1
        }
      }

      // Fade in the audio
      fadeInAudio(duration: 1.5)

      // Schedule automatic fade-out 2 seconds before the audio ends
      if let duration = player?.duration, duration > 2.0 {
        let fadeOutStartTime = duration - 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutStartTime) { [weak self] in
          guard let self = self, self.isPlaying else { return }
          self.fadeOutAndStop()
        }
      }
    } catch {
      print("Failed to play sound: \(error)")
    }
  }

  private func fadeInAudio(duration: TimeInterval = 1.5) {
    guard let player = player else { return }

    let fadeInSteps = 15
    let stepDuration = duration / TimeInterval(fadeInSteps)
    let volumeStep = 1.0 / Float(fadeInSteps)

    // Start fade in timer
    Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
      guard let self = self, let currentPlayer = self.player else {
        timer.invalidate()
        return
      }

      if currentPlayer.volume < 1.0 - volumeStep {
        currentPlayer.volume += volumeStep
      } else {
        // Fade in complete, set to full volume
        currentPlayer.volume = 1.0
        timer.invalidate()
      }
    }
  }

  func playRandomSound() {
    guard let randomSound = sounds.randomElement() else { return }
    playSound(randomSound)
  }

  func stopSound() {
    if !isFadingOut {
      fadeOutAndStop()
    }
  }

  func setAboutToComplete() {
    isAboutToComplete = true
  }

  func stopSoundImmediately() {
    fadeOutTimer?.invalidate()
    fadeOutTimer = nil
    isFadingOut = false
    isAboutToComplete = false
    player?.stop()
    timer?.invalidate()
    timer = nil
    isPlaying = false
    remainingTime = 0
  }

  private func fadeOutAndStop(duration: TimeInterval = 2.0) {
    // Prevent multiple fade-outs
    if isFadingOut {
      return
    }

    isFadingOut = true

    // Cancel any existing fade out
    fadeOutTimer?.invalidate()
    fadeOutTimer = nil

    // Check if we have a player and it's either playing or we're about to complete
    guard let player = player, player.isPlaying || isPlaying || isAboutToComplete else {
      isFadingOut = false
      stopSoundImmediately()
      return
    }

    let fadeOutDuration = duration
    let fadeOutSteps = 20
    let stepDuration = fadeOutDuration / TimeInterval(fadeOutSteps)
    let volumeStep = player.volume / Float(fadeOutSteps)

    // Start fade out timer
    fadeOutTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) {
      [weak self] timer in
      guard let self = self, let currentPlayer = self.player else {
        timer.invalidate()
        self?.isFadingOut = false
        return
      }

      if currentPlayer.volume > volumeStep {
        currentPlayer.volume -= volumeStep
      } else {
        // Fade out complete, stop the audio
        timer.invalidate()
        self.fadeOutTimer = nil
        self.isFadingOut = false
        self.stopSoundImmediately()
      }
    }
  }
}

extension AudioManager: AVAudioPlayerDelegate {
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    // Don't reset state if we're in the middle of a fade-out or about to complete
    if !isFadingOut && !isAboutToComplete {
      isPlaying = false
      remainingTime = 0
      timer?.invalidate()
      timer = nil
    }
  }
}
