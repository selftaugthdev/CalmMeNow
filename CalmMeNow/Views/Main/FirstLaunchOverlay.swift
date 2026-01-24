import SwiftUI

struct FirstLaunchOverlay: View {
    @Binding var isVisible: Bool

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { isVisible = false }

            VStack(spacing: 0) {
                // Top title
                Text("If you feel anxious or panicked, start here.")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 60)
                    .padding(.bottom, 32)

                Spacer()

                // Orange callout pointing to Emergency Calm Button
                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Tap this for immediate relief")
                                .font(.headline)
                                .foregroundColor(.orange)
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(12)
                            Text("Breathing + grounding guidance, right now.")
                                .font(.caption)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.trailing)
                        }
                        // Arrow pointing down to the emergency button
                        Image(systemName: "arrow.down")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.orange)
                            .offset(x: 10, y: 0)
                    }
                    .padding(.trailing, 32)
                }
                .padding(.bottom, 160)

                Spacer(minLength: 40)

                // Callout for Games and Grounding
                HStack(alignment: .top, spacing: 12) {
                    // Arrow pointing up-right to cards
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.top, 10)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Need distraction instead?")
                            .font(.headline)
                            .foregroundColor(.orange)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(12)
                        Text("Focus your attention for a moment to calm your nervous system.")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .padding(.leading, 40)

                Spacer()

                // Bottom reassurance
                Text("You can’t do this wrong. Just tap what feels easiest.")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 50)

                // Dismiss button
                Button(action: { isVisible = false }) {
                    Text("Got it!")
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(20)
                        .padding(.horizontal, 60)
                        .shadow(radius: 5)
                }
                .padding(.bottom, 40)
            }
        }
        .animation(.easeIn, value: isVisible)
        .transition(.opacity)
    }
}

#Preview {
    FirstLaunchOverlay(isVisible: .constant(true))
}
