//
//  AudioManager.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import AVFoundation

class AudioManager {
  static let shared = AudioManager()
  private var player: AVAudioPlayer?

  let sounds = ["perfect-beauty-1-min"]

  func playRandomSound() {
    guard let randomSound = sounds.randomElement(),
      let url = Bundle.main.url(forResource: randomSound, withExtension: "m4a")
    else {
      print("Sound not found")
      return
    }

    do {
      player = try AVAudioPlayer(contentsOf: url)
      player?.play()
    } catch {
      print("Failed to play sound: \(error)")
    }
  }
}
