import SwiftUI

struct SuccessView: View {
  @Environment(\.presentationMode) var presentationMode
  @State private var isAnimating = false
  @State private var showOptions = false
  
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
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
          
          Text("You did it.")
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.white.opacity(0.9))
            .multilineTextAlignment(.center)
          
          Text("Come back anytime — we've got you.")
            .font(.title3)
            .foregroundColor(.white.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.2))
        )
        
        Spacer()
        
        // Action buttons
        if showOptions {
          VStack(spacing: 16) {
            Button("Return to Home") {
              presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .background(
              RoundedRectangle(cornerRadius: 25)
                .fill(Color.white.opacity(0.3))
            )
            .overlay(
              RoundedRectangle(cornerRadius: 25)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
            
            Button("Journal this moment") {
              // TODO: Implement journaling functionality
              presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .background(
              RoundedRectangle(cornerRadius: 25)
                .fill(Color.white.opacity(0.2))
            )
            .overlay(
              RoundedRectangle(cornerRadius: 25)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
          }
          .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
      }
      .padding(.bottom, 60)
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
