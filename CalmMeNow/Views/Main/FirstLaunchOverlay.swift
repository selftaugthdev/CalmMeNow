import SwiftUI

struct FirstLaunchOverlay: View {
    @Binding var isVisible: Bool
    @State private var arrowBounce = false

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { isVisible = false }

            VStack(spacing: 0) {
                // Top section - Emergency button callout
                VStack(spacing: 8) {
                    Text("If you feel anxious or panicked, start here.")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    // Curly arrow pointing UP to emergency button
                    CurlyArrow(pointingUp: true)
                        .stroke(
                            LinearGradient(
                                colors: [Color.orange, Color(hex: "#FF6B00")],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 40, height: 50)
                        .shadow(color: .orange.opacity(0.8), radius: 8)
                        .offset(y: arrowBounce ? -5 : 5)
                        .animation(
                            .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                            value: arrowBounce
                        )

                    Text("Tap this for immediate relief")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(12)

                    Text("Breathing + grounding guidance, right now.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, 130)

                Spacer()

                // Middle section - Cards callout (moved higher)
                VStack(spacing: 8) {
                    Text("Need distraction instead?")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#32CD32"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(12)

                    Text("Focus your attention for a moment to calm your nervous system.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    // Curly arrow pointing DOWN to cards
                    CurlyArrow(pointingUp: false)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#32CD32"), Color(hex: "#00AA00")],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 40, height: 50)
                        .shadow(color: Color(hex: "#32CD32").opacity(0.8), radius: 8)
                        .offset(y: arrowBounce ? 5 : -5)
                        .animation(
                            .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                            value: arrowBounce
                        )
                }
                .padding(.bottom, 80)

                Spacer()

                // Bottom reassurance
                Text("You can't do this wrong. Just tap what feels easiest.")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)

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
        .onAppear {
            arrowBounce = true
        }
        .animation(.easeIn, value: isVisible)
        .transition(.opacity)
    }
}

// Custom curly arrow shape
struct CurlyArrow: Shape {
    let pointingUp: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()

        if pointingUp {
            // Start from bottom, curve up to top with arrowhead
            let startY = rect.maxY
            let endY = rect.minY + 10

            path.move(to: CGPoint(x: rect.midX, y: startY))

            // S-curve going up
            path.addCurve(
                to: CGPoint(x: rect.midX, y: endY),
                control1: CGPoint(x: rect.midX + 15, y: startY - rect.height * 0.3),
                control2: CGPoint(x: rect.midX - 15, y: startY - rect.height * 0.7)
            )

            // Arrowhead pointing up
            path.move(to: CGPoint(x: rect.midX - 10, y: endY + 12))
            path.addLine(to: CGPoint(x: rect.midX, y: endY))
            path.addLine(to: CGPoint(x: rect.midX + 10, y: endY + 12))
        } else {
            // Start from top, curve down to bottom with arrowhead
            let startY = rect.minY
            let endY = rect.maxY - 10

            path.move(to: CGPoint(x: rect.midX, y: startY))

            // S-curve going down
            path.addCurve(
                to: CGPoint(x: rect.midX, y: endY),
                control1: CGPoint(x: rect.midX - 15, y: startY + rect.height * 0.3),
                control2: CGPoint(x: rect.midX + 15, y: startY + rect.height * 0.7)
            )

            // Arrowhead pointing down
            path.move(to: CGPoint(x: rect.midX - 10, y: endY - 12))
            path.addLine(to: CGPoint(x: rect.midX, y: endY))
            path.addLine(to: CGPoint(x: rect.midX + 10, y: endY - 12))
        }

        return path
    }
}

#Preview {
    FirstLaunchOverlay(isVisible: .constant(true))
}
