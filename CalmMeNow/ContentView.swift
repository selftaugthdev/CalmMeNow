//
//  ContentView.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var audioManager = AudioManager.shared

  var body: some View {
    NavigationView {
      ZStack {
        // Background gradient
        LinearGradient(
          gradient: Gradient(colors: [
            Color(red: 0.85, green: 0.85, blue: 0.95),  // Deeper lavender
            Color(red: 0.80, green: 0.90, blue: 0.95),  // Richer blue
            Color(red: 0.85, green: 0.95, blue: 0.85),  // Deeper mint
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        // Add a subtle overlay to soften the gradient
        Color.white.opacity(0.1)
          .ignoresSafeArea()

        VStack {
          Spacer()

          // Logo
          Image("CalmMeNow Logo Homepage")
            .resizable()
            .scaledToFit()
            .frame(height: 120)
            .padding(.bottom, 40)

          Text("How are you feeling?")
            .font(.title2)
            .padding(.bottom, 20)

          Text("Select your emotion to find calm")
            .font(.body)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
            .foregroundColor(.secondary)

          if audioManager.isPlaying {
            Text(timeString(from: audioManager.remainingTime))
              .font(.title)
              .foregroundColor(.blue)
              .padding(.bottom, 20)
          }

          // Emotion Buttons Grid
          VStack(spacing: 15) {
            ForEach(CooldownModel.cooldowns, id: \.id) { cooldown in
              NavigationLink(destination: CooldownView(model: cooldown)) {
                Text("\(cooldown.emoji) I Feel \(cooldown.emotion)")
                  .font(.title3)
                  .padding()
                  .frame(maxWidth: .infinity)
                  .background(Color.blue.opacity(0.8))
                  .foregroundColor(.white)
                  .cornerRadius(16)
              }
            }
          }
          .padding(.horizontal, 40)

          Spacer()
        }
      }
      .navigationBarHidden(true)
    }
  }

  private func timeString(from timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }
}
