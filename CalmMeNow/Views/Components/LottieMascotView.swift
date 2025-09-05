import SwiftUI
import Lottie

struct LottieMascotView: UIViewRepresentable {
    let name: String
    var loop: LottieLoopMode = .loop
    var speed: CGFloat = 1.0

    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator {
        var animView: LottieAnimationView?
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        let animView = LottieAnimationView()
        animView.animation = LottieAnimation.named(name)
        animView.loopMode = loop
        animView.animationSpeed = speed
        animView.contentMode = .scaleAspectFit
        animView.translatesAutoresizingMaskIntoConstraints = false

        // Make the animation fit INSIDE whatever box SwiftUI gives the container.
        container.addSubview(animView)
        NSLayoutConstraint.activate([
            animView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            animView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            animView.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor),
            animView.heightAnchor.constraint(lessThanOrEqualTo: container.heightAnchor)
        ])
        // Don’t let Auto Layout stretch it larger than its box
        animView.setContentHuggingPriority(.required, for: .horizontal)
        animView.setContentHuggingPriority(.required, for: .vertical)
        animView.setContentCompressionResistancePriority(.required, for: .horizontal)
        animView.setContentCompressionResistancePriority(.required, for: .vertical)

        animView.play()
        context.coordinator.animView = animView
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) { /* no-op */ }
}