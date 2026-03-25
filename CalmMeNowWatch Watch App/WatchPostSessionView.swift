import SwiftUI
import WatchKit

struct WatchPostSessionView: View {
  let duration: Int
  let onDone: () -> Void

  @State private var appeared = false

  var body: some View {
    ZStack {
      Color(hex: "#0A1628").ignoresSafeArea()

      VStack(spacing: 10) {
        Image(systemName: "heart.fill")
          .font(.system(size: 32))
          .foregroundColor(Color(hex: "#6AB0FF"))
          .scaleEffect(appeared ? 1.0 : 0.5)
          .opacity(appeared ? 1 : 0)
          .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: appeared)

        Text("You got through it.")
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(.white)
          .multilineTextAlignment(.center)
          .opacity(appeared ? 1 : 0)
          .animation(.easeIn(duration: 0.4).delay(0.3), value: appeared)

        if duration > 0 {
          Text(duration < 60 ? "\(duration)s" : "\(duration / 60)m \(duration % 60)s")
            .font(.system(size: 11, design: .rounded))
            .foregroundColor(.white.opacity(0.45))
            .opacity(appeared ? 1 : 0)
            .animation(.easeIn(duration: 0.4).delay(0.5), value: appeared)
        }

        Button("Done") { onDone() }
          .font(.system(size: 13, weight: .semibold))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)))
          .buttonStyle(.plain)
          .opacity(appeared ? 1 : 0)
          .animation(.easeIn(duration: 0.4).delay(0.6), value: appeared)
      }
      .padding(.horizontal, 12)
    }
    .onAppear {
      appeared = true
      WKInterfaceDevice.current().play(.success)
    }
  }
}
