import Lottie
import SwiftUI

struct LottieMascotView: UIViewRepresentable {
  let name: String
  var loop: LottieLoopMode = .loop
  var speed: CGFloat = 1.0

  func makeUIView(context: Context) -> UIView {
    let container = UIView()
    container.clipsToBounds = false

    let animView = LottieAnimationView(name: name)
    animView.loopMode = loop
    animView.animationSpeed = speed
    animView.contentMode = .scaleAspectFit  // <- respects the box you give it
    animView.translatesAutoresizingMaskIntoConstraints = false

    container.addSubview(animView)
    NSLayoutConstraint.activate([
      animView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      animView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      animView.topAnchor.constraint(equalTo: container.topAnchor),
      animView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])

    animView.play()
    return container
  }

  func updateUIView(_ uiView: UIView, context: Context) { /* nothing */  }
}
