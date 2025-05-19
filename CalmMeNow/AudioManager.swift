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

  let sounds = ["perfect-beauty-1-min"]

  override init() {
    super.init()
  }

  func playRandomSound() {
    guard let randomSound = sounds.randomElement(),
      let url = Bundle.main.url(forResource: randomSound, withExtension: "m4a")
    else {
      print("Sound not found")
      return
    }

    do {
      player = try AVAudioPlayer(contentsOf: url)
      player?.delegate = self
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
    } catch {
      print("Failed to play sound: \(error)")
    }
  }

  func stopSound() {
    player?.stop()
    timer?.invalidate()
    timer = nil
    isPlaying = false
    remainingTime = 0
  }
}

extension AudioManager: AVAudioPlayerDelegate {
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    isPlaying = false
    remainingTime = 0
    timer?.invalidate()
    timer = nil
  }
}
