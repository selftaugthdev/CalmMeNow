import SwiftUI

struct SubscriptionSuccessView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var isAnimating = false
  @State private var showContent = false
  @State private var countdown = 5
  
  var body: some View {
    ZStack {
      // Success background gradient
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "#4CAF50"),  // Green
          Color(hex: "#8BC34A"),  // Light Green
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()
      
      VStack(spacing: 40) {
        Spacer()
        
        // Success animation
        ZStack {
          // Animated checkmark
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 120))
            .foregroundColor(.white)
            .scaleEffect(isAnimating ? 1.1 : 0.9)
            .opacity(isAnimating ? 1.0 : 0.7)
            .animation(
              Animation.easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true),
              value: isAnimating
            )
          
          // Subtle glow effect
          Circle()
            .fill(Color.white.opacity(0.3))
            .frame(width: 160, height: 160)
            .scaleEffect(isAnimating ? 1.3 : 1.0)
            .opacity(isAnimating ? 0.0 : 0.4)
            .animation(
              Animation.easeInOut(duration: 2)
                .repeatForever(autoreverses: false),
              value: isAnimating
            )
        }
        
        // Success message
        VStack(spacing: 20) {
          Text("🎉 Welcome to Premium!")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
          
          Text("You now have access to all AI-powered features:")
            .font(.title3)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
          
          VStack(spacing: 12) {
            PremiumFeatureRow(icon: "target", text: "Personalized Panic Plans")
            PremiumFeatureRow(icon: "brain.head.profile", text: "AI Daily Coach")
            PremiumFeatureRow(icon: "heart.fill", text: "Emergency AI Companion")
          }
          .padding(.top, 10)
        }
        .padding(.horizontal, 30)
        .opacity(showContent ? 1.0 : 0.0)
        .offset(y: showContent ? 0 : 20)
        .animation(.easeOut(duration: 0.8).delay(0.3), value: showContent)
        
        Spacer()
        
        // Auto-dismiss countdown
        VStack(spacing: 16) {
          Text("This screen will close automatically in \(countdown) seconds")
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
            .multilineTextAlignment(.center)
          
          Button("Continue Now") {
            dismiss()
          }
          .foregroundColor(.white)
          .padding(.vertical, 12)
          .padding(.horizontal, 24)
          .background(
            RoundedRectangle(cornerRadius: 25)
              .fill(Color.white.opacity(0.2))
              .overlay(
                RoundedRectangle(cornerRadius: 25)
                  .stroke(Color.white.opacity(0.3), lineWidth: 1)
              )
          )
        }
        .opacity(showContent ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.8).delay(0.6), value: showContent)
      }
    }
    .onAppear {
      print("🎉 SubscriptionSuccessView appeared!")
      isAnimating = true
      
      // Show content with delay
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        showContent = true
        print("🎉 SubscriptionSuccessView content shown!")
      }
      
      // Start countdown
      startCountdown()
    }
    .onDisappear {
      print("🎉 SubscriptionSuccessView disappeared!")
    }
  }
  
  private func startCountdown() {
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
      if countdown > 1 {
        countdown -= 1
      } else {
        timer.invalidate()
        dismiss()
      }
    }
  }
}

struct PremiumFeatureRow: View {
  let icon: String
  let text: String
  
  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.title3)
        .foregroundColor(.white)
        .frame(width: 24)
      
      Text(text)
        .font(.body)
        .foregroundColor(.white)
        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
      
      Spacer()
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.white.opacity(0.15))
    )
  }
}

#Preview {
  SubscriptionSuccessView()
}
