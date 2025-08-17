import SwiftUI

struct Bubble: Identifiable {
  let id = UUID()
  var position: CGPoint
  var size: CGFloat
  var color: Color
  var isPopped = false
  var scale: CGFloat = 1.0
  var opacity: Double = 1.0
}

struct BubbleGameView: View {
  @Environment(\.presentationMode) var presentationMode
  @State private var bubbles: [Bubble] = []
  @State private var score = 0
  @State private var gameTimer: Timer?
  @State private var timeRemaining = 60  // 60 seconds
  @State private var isGameActive = false

  // Calming colors for bubbles
  private let bubbleColors: [Color] = [
    Color.blue.opacity(0.6),
    Color.purple.opacity(0.6),
    Color.pink.opacity(0.6),
    Color.cyan.opacity(0.6),
    Color.mint.opacity(0.6),
    Color.indigo.opacity(0.6),
  ]

  var body: some View {
    ZStack {
      // Calming gradient background
      LinearGradient(
        gradient: Gradient(colors: [
          Color.purple.opacity(0.1),
          Color.blue.opacity(0.1),
          Color.mint.opacity(0.1),
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack {
        // Header
        HStack {
          Button(action: {
            stopGame()
            presentationMode.wrappedValue.dismiss()
          }) {
            Image(systemName: "xmark.circle.fill")
              .font(.title2)
              .foregroundColor(.gray)
          }

          Spacer()

          VStack(spacing: 4) {
            Text("Pop Bubbles")
              .font(.title2)
              .fontWeight(.semibold)
              .foregroundColor(.primary)

            Text("Release tension, one bubble at a time")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Spacer()

          // Timer
          Text("\(timeRemaining)")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.blue)
            .frame(width: 50)
        }
        .padding()

        Spacer()

        // Game area
        ZStack {
          // Bubbles
          ForEach(bubbles) { bubble in
            if !bubble.isPopped {
              Circle()
                .fill(bubble.color)
                .frame(width: bubble.size, height: bubble.size)
                .position(bubble.position)
                .scaleEffect(bubble.scale)
                .opacity(bubble.opacity)
                .onTapGesture {
                  popBubble(bubble)
                }
                .animation(.easeInOut(duration: 0.3), value: bubble.scale)
            }
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()

        Spacer()

        // Score and controls
        VStack(spacing: 16) {
          Text("Score: \(score)")
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundColor(.primary)

          if !isGameActive {
            Button(action: startGame) {
              Text("Start Game")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(
                  RoundedRectangle(cornerRadius: 25)
                    .fill(Color.blue)
                )
            }
          }
        }
        .padding(.bottom, 40)
      }
    }
    .onAppear {
      generateInitialBubbles()
    }
    .onDisappear {
      stopGame()
    }
  }

  private func generateInitialBubbles() {
    bubbles = []
    for _ in 0..<15 {
      addRandomBubble()
    }
  }

  private func addRandomBubble() {
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height - 200  // Account for header and footer

    let randomX = CGFloat.random(in: 50...(screenWidth - 50))
    let randomY = CGFloat.random(in: 100...(screenHeight - 100))
    let randomSize = CGFloat.random(in: 30...80)
    let randomColor = bubbleColors.randomElement() ?? Color.blue.opacity(0.6)

    let newBubble = Bubble(
      position: CGPoint(x: randomX, y: randomY),
      size: randomSize,
      color: randomColor
    )

    bubbles.append(newBubble)
  }

  private func popBubble(_ bubble: Bubble) {
    guard let index = bubbles.firstIndex(where: { $0.id == bubble.id }) else { return }

    // Animate pop effect
    withAnimation(.easeInOut(duration: 0.3)) {
      bubbles[index].scale = 1.5
      bubbles[index].opacity = 0
    }

    // Add score
    score += 1

    // Remove bubble after animation
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      bubbles.removeAll { $0.id == bubble.id }

      // Add new bubble to maintain game flow
      if isGameActive {
        addRandomBubble()
      }
    }
  }

  private func startGame() {
    isGameActive = true
    score = 0
    timeRemaining = 60

    // Start timer
    gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      if timeRemaining > 0 {
        timeRemaining -= 1
      } else {
        stopGame()
      }
    }

    // Add bubbles periodically
    Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
      if isGameActive && bubbles.count < 20 {
        addRandomBubble()
      } else if !isGameActive {
        timer.invalidate()
      }
    }
  }

  private func stopGame() {
    isGameActive = false
    gameTimer?.invalidate()
    gameTimer = nil
  }
}

#Preview {
  BubbleGameView()
}
