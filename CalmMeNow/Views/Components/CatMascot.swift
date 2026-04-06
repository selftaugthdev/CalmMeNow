import SwiftUI

/// Drop-in mascot view — now renders the bear asset with a gentle breathing pulse.
struct CatMascot: View {
  @State private var breathe = false

  var body: some View {
    Image("bear_mascot")
      .resizable()
      .scaledToFit()
      .scaleEffect(breathe ? 1.04 : 0.96)
      .animation(
        .easeInOut(duration: 3).repeatForever(autoreverses: true),
        value: breathe
      )
      .onAppear { breathe = true }
      .accessibilityHidden(true)
  }
}
