import SwiftUI

private struct CalmBreathingOrb: View {
  @State private var scale: CGFloat = 0.9
  var body: some View {
    Circle()
      .fill(Color.white.opacity(0.15))
      .frame(width: 320, height: 320)
      .scaleEffect(scale)
      .blur(radius: 30)
      .onAppear {
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
          scale = 1.05
        }
      }
  }
}

struct PositiveQuotesView: View {
  @Environment(\.presentationMode) var presentationMode
  @State private var quote: PositiveQuote = PositiveQuotesService.shared.randomQuote()
  @State private var isFading = false

  var body: some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "#D3C3FC"),
          Color(hex: "#6A92C8"),
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      CalmBreathingOrb()

      VStack(spacing: 20) {
        HStack {
          Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.white)
          }
          Spacer()
          Button(action: shuffleQuote) {
            Image(systemName: "arrow.clockwise.circle.fill").font(.title2).foregroundColor(.white)
          }
        }
        .padding(.horizontal)
        .padding(.top, 8)

        Spacer(minLength: 0)

        Text("Positive Boost 💫")
          .font(.title)
          .fontWeight(.bold)
          .foregroundColor(.white)

        VStack(alignment: .leading, spacing: 16) {
          Text("“\(quote.text)”")
            .font(.system(size: 26, weight: .semibold, design: .serif))
            .foregroundColor(.black)
            .multilineTextAlignment(.leading)
            .transition(.opacity)

          Divider()

          Text(quote.reflection)
            .font(.body)
            .foregroundColor(.black.opacity(0.8))
            .transition(.opacity)

          HStack {
            Button(action: toggleFavorite) {
              Label(
                PositiveQuotesService.shared.isFavorite(quote) ? "Favorited" : "Favorite",
                systemImage: PositiveQuotesService.shared.isFavorite(quote) ? "heart.fill" : "heart"
              )
              .foregroundColor(.red)
            }
            Spacer()
            Button(action: shuffleQuote) {
              Label("New Quote", systemImage: "arrow.clockwise")
            }
          }
          .padding(.top, 8)
        }
        .padding(20)
        .background(
          RoundedRectangle(cornerRadius: 22)
            .fill(Color.white.opacity(0.96))
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 8)
        )
        .padding(.horizontal, 24)
        .opacity(isFading ? 0.0 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isFading)

        Spacer(minLength: 0)
      }
    }
  }

  private func shuffleQuote() {
    isFading = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      quote = PositiveQuotesService.shared.randomQuote()
      isFading = false
    }
  }

  private func toggleFavorite() {
    PositiveQuotesService.shared.toggleFavorite(quote)
  }
}
