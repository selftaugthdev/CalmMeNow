import SwiftUI

struct LotusMascot: View {
  @State private var expand = false

  var body: some View {
    ZStack {
      ForEach(0..<6) { i in
        Ellipse()
          .stroke(Color.pink.opacity(0.7), lineWidth: 4)
          .frame(width: 60, height: 20)
          .rotationEffect(.degrees(Double(i) * 60))
          .scaleEffect(expand ? 1.1 : 0.9)
          .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: expand)
      }
    }
    .onAppear { expand = true }
  }
}
