import SwiftUI

struct SuccessView: View {
  @Environment(\.presentationMode) var presentationMode
  @State private var isAnimating = false
  @State private var showOptions = false
  @State private var showJournaling = false
  var onReturnToHome: (() -> Void)?
  let emotionContext: String?
  let intensityContext: String?

  init(
    onReturnToHome: (() -> Void)? = nil, emotionContext: String? = nil,
    intensityContext: String? = nil
  ) {
    self.onReturnToHome = onReturnToHome
    self.emotionContext = emotionContext
    self.intensityContext = intensityContext
  }

  var body: some View {
    ZStack {
      // Success background gradient
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "#A0C4FF"),  // Teal
          Color(hex: "#D0BFFF"),  // Soft Purple
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 40) {
        Spacer()

        // Success animation
        ZStack {
          // Animated sun/checkmark
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 120))
            .foregroundColor(.white)
            .scaleEffect(isAnimating ? 1.2 : 0.8)
            .opacity(isAnimating ? 1.0 : 0.6)
            .animation(
              Animation.easeInOut(duration: 2)
                .repeatForever(autoreverses: true),
              value: isAnimating
            )

          // Subtle glow effect
          Circle()
            .fill(Color.white.opacity(0.3))
            .frame(width: 160, height: 160)
            .scaleEffect(isAnimating ? 1.4 : 1.0)
            .opacity(isAnimating ? 0.0 : 0.5)
            .animation(
              Animation.easeInOut(duration: 3)
                .repeatForever(autoreverses: false),
              value: isAnimating
            )
        }

        // Success message
        VStack(spacing: 16) {
          Text("🎉 That's great to hear!")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .minimumScaleFactor(0.8)
            .shadow(color: .white, radius: 2, x: 0, y: 1)

          Text("You did it.")
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .shadow(color: .white, radius: 2, x: 0, y: 1)

          Text("Come back anytime — we've got you.")
            .font(.title3)
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .minimumScaleFactor(0.8)
            .shadow(color: .white, radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(maxWidth: 320, minHeight: 120)  // Constrain width instead of stretching to infinity
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.9))
        )

        Spacer()

        // Action buttons
        if showOptions {
          VStack(spacing: 16) {
            Button("Return to Home") {
              presentationMode.wrappedValue.dismiss()
              onReturnToHome?()
            }
            .foregroundColor(.black)
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .background(
              RoundedRectangle(cornerRadius: 25)
                .fill(Color.white.opacity(0.9))
            )
            .overlay(
              RoundedRectangle(cornerRadius: 25)
                .stroke(Color.black.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            Button("Journal this moment") {
              showJournaling = true
            }
            .foregroundColor(.black)
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .background(
              RoundedRectangle(cornerRadius: 25)
                .fill(Color.white.opacity(0.8))
            )
            .overlay(
              RoundedRectangle(cornerRadius: 25)
                .stroke(Color.black.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
          }
          .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
      }
      .padding(.bottom, 60)
    }
    .sheet(isPresented: $showJournaling) {
      JournalingView(emotionContext: emotionContext, intensityContext: intensityContext)
    }
    .onAppear {
      isAnimating = true

      // Show options after a brief delay
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
        withAnimation(.easeInOut(duration: 0.8)) {
          showOptions = true
        }
      }
    }
  }
}

#Preview {
  SuccessView()
}
