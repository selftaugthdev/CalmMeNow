import SwiftUI

struct WatchHomeView: View {
  @State private var showingBreathing = false
  @State private var showingMood = false
  @State private var bearScale: CGFloat = 0.96
  @State private var bearGlow: CGFloat = 8

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color(hex: "#0A1628"), Color(hex: "#1A3560")],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack(spacing: 10) {
        // Bear
        ZStack {
          Circle()
            .fill(Color(hex: "#6AB0FF").opacity(0.10))
            .frame(width: 70, height: 70)
            .blur(radius: bearGlow)
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: bearGlow)

          Image("bear_mascot")
            .resizable()
            .scaledToFit()
            .frame(width: 64, height: 64)
            .scaleEffect(bearScale)
            .blendMode(.screen)
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: bearScale)
        }
        .onAppear {
          withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            bearScale = 1.04
            bearGlow = 16
          }
        }

        // Panic button
        Button {
          showingBreathing = true
        } label: {
          Text("I need help now")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#3A6ED4"))
            )
        }
        .buttonStyle(.plain)

        // Secondary row
        HStack(spacing: 8) {
          Button {
            showingMood = true
          } label: {
            Text("Mood")
              .font(.system(size: 12))
              .foregroundColor(.white.opacity(0.7))
              .frame(maxWidth: .infinity)
              .padding(.vertical, 7)
              .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
          }
          .buttonStyle(.plain)

          Button {
            WCSessionDelegateHelper.shared.sendNightProtocol()
          } label: {
            Label("Night", systemImage: "moon.fill")
              .font(.system(size: 11))
              .foregroundColor(.white.opacity(0.5))
              .frame(maxWidth: .infinity)
              .padding(.vertical, 7)
              .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 8)
    }
    .fullScreenCover(isPresented: $showingBreathing) {
      WatchBreathingView()
    }
    .sheet(isPresented: $showingMood) {
      WatchMoodView()
    }
  }
}

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3:
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
    }
    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}
