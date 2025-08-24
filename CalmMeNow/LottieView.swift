import Lottie
import SwiftUI

struct LottieView: UIViewRepresentable {
  let name: String
  let loopMode: LottieLoopMode
  let speed: CGFloat

  func makeUIView(context: Context) -> LottieAnimationView {
    let v = LottieAnimationView(name: name)
    v.loopMode = loopMode
    v.animationSpeed = speed
    v.play()
    return v
  }

  func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}
