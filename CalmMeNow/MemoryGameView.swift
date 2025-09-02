import SwiftUI

struct MemoryCard: Identifiable, Equatable {
  let id = UUID()
  let symbol: String
  let color: Color
  var isFlipped = false
  var isMatched = false
}

struct MemoryGameView: View {
  @Environment(\.presentationMode) var presentationMode
  @State private var cards: [MemoryCard] = []
  @State private var flippedCards: [MemoryCard] = []
  @State private var score = 0
  @State private var moves = 0
  @State private var gameTimer: Timer?
  @State private var timeElapsed = 0
  @State private var isGameActive = false
  @State private var showingWinAlert = false

  // Calming symbols and colors for the memory game
  private let symbols = ["🌸", "🌿", "🌊", "☁️", "🕊️", "🍃", "🌙", "⭐"]
  private let cardColors: [Color] = [
    Color.blue.opacity(0.8),
    Color.purple.opacity(0.8),
    Color.mint.opacity(0.8),
    Color.pink.opacity(0.8),
    Color.indigo.opacity(0.8),
    Color.teal.opacity(0.8),
    Color.orange.opacity(0.8),
    Color.green.opacity(0.8),
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
            Text("Memory Game")
              .font(.title2)
              .fontWeight(.semibold)
              .foregroundColor(.primary)

            Text("Focus on matching, let anxiety fade away")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Spacer()

          // Timer
          Text(timeString)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.blue)
            .frame(width: 80)
        }
        .padding()

        // Game stats
        HStack(spacing: 20) {
          VStack {
            Text("Score")
              .font(.caption)
              .foregroundColor(.secondary)
            Text("\(score)")
              .font(.title3)
              .fontWeight(.bold)
              .foregroundColor(.primary)
          }

          VStack {
            Text("Moves")
              .font(.caption)
              .foregroundColor(.secondary)
            Text("\(moves)")
              .font(.title3)
              .fontWeight(.bold)
              .foregroundColor(.primary)
          }

          VStack {
            Text("Pairs")
              .font(.caption)
              .foregroundColor(.secondary)
            Text("\(cards.filter { $0.isMatched }.count / 2)")
              .font(.title3)
              .fontWeight(.bold)
              .foregroundColor(.primary)
          }
        }
        .padding(.horizontal)

        Spacer()

        // Game grid
        LazyVGrid(
          columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8
        ) {
          ForEach(cards) { card in
            MemoryCardView(card: card) {
              flipCard(card)
            }
          }
        }
        .padding(.horizontal, 20)

        Spacer()

        // Controls
        VStack(spacing: 16) {
          if !isGameActive {
            Button(action: startNewGame) {
              Text("Start New Game")
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
      setupGame()
    }
    .onDisappear {
      stopGame()
    }
    .alert("Congratulations! 🎉", isPresented: $showingWinAlert) {
      Button("Play Again") {
        startNewGame()
      }
      Button("Done") {
        presentationMode.wrappedValue.dismiss()
      }
    } message: {
      Text("You completed the memory game in \(timeString) with \(moves) moves!")
    }
  }

  private var timeString: String {
    let minutes = timeElapsed / 60
    let seconds = timeElapsed % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }

  private func setupGame() {
    createCards()
    shuffleCards()
  }

  private func createCards() {
    cards = []
    for (index, symbol) in symbols.enumerated() {
      // Each pair gets a unique color for the card face
      let color = cardColors[index % cardColors.count]
      // Create two cards for each symbol
      cards.append(MemoryCard(symbol: symbol, color: color))
      cards.append(MemoryCard(symbol: symbol, color: color))
    }
  }

  private func shuffleCards() {
    cards.shuffle()
  }

  private func flipCard(_ card: MemoryCard) {
    guard !card.isMatched else { return }

    guard let cardIndex = cards.firstIndex(where: { $0.id == card.id }) else { return }

    // prevent 3rd selection
    if flippedCards.count >= 2 { return }

    // if tapping an already face-up card, allow it to be the second selection
    if cards[cardIndex].isFlipped {
      flippedCards.append(cards[cardIndex])
      if flippedCards.count == 2 {
        moves += 1
        checkForMatch()
      }
      return
    }

    withAnimation(.easeInOut(duration: 0.3)) {
      cards[cardIndex].isFlipped = true
    }
    flippedCards.append(cards[cardIndex])

    if flippedCards.count == 2 {
      moves += 1
      checkForMatch()
    }
  }

  private func checkForMatch() {
    let card1 = flippedCards[0]
    let card2 = flippedCards[1]

    if card1.symbol == card2.symbol {
      // Match found!
      score += 10

      // Mark cards as matched
      if let index1 = cards.firstIndex(where: { $0.id == card1.id }),
        let index2 = cards.firstIndex(where: { $0.id == card2.id })
      {
        withAnimation(.easeInOut(duration: 0.5)) {
          cards[index1].isMatched = true
          cards[index2].isMatched = true
        }
      }

      // Clear flipped cards
      flippedCards.removeAll()

      // Check if game is won
      if cards.allSatisfy({ $0.isMatched }) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          showingWinAlert = true
          stopGame()
        }
      }
    } else {
      // No match, flip cards back
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        if let index1 = cards.firstIndex(where: { $0.id == card1.id }),
          let index2 = cards.firstIndex(where: { $0.id == card2.id })
        {
          withAnimation(.easeInOut(duration: 0.3)) {
            cards[index1].isFlipped = false
            cards[index2].isFlipped = false
          }
        }
        flippedCards.removeAll()
      }
    }
  }

  private func startNewGame() {
    stopGame()
    score = 0
    moves = 0
    timeElapsed = 0
    flippedCards.removeAll()
    setupGame()
    startGame()
  }

  private func startGame() {
    isGameActive = true

    // Start timer
    gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      timeElapsed += 1
    }
  }

  private func stopGame() {
    isGameActive = false
    gameTimer?.invalidate()
    gameTimer = nil
  }
}

struct MemoryCardView: View {
  let card: MemoryCard
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      ZStack {
        RoundedRectangle(cornerRadius: 12)
          .fill(card.isFlipped ? card.color : Color.white.opacity(0.9))
          .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

        if card.isFlipped {
          Text(card.symbol)
            .font(.system(size: 24))
            .foregroundColor(.white)
            .scaleEffect(card.isFlipped ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: card.isFlipped)
        } else {
          // No colored border - just a subtle drop shadow for depth
          RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.9))
            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
        }
      }
    }
    .frame(height: 80)
    .disabled(card.isMatched)
    .scaleEffect(card.isMatched ? 0.9 : 1.0)
    .opacity(card.isMatched ? 0.7 : 1.0)
    .animation(.easeInOut(duration: 0.3), value: card.isMatched)
  }
}

#Preview {
  MemoryGameView()
}
