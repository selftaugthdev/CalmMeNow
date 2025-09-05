import SwiftUI

struct GameSelectionView: View {
  @Environment(\.presentationMode) var presentationMode
  @Binding var showingBubbleGame: Bool
  @Binding var showingMemoryGame: Bool
  @Binding var showingColoringGame: Bool

  var body: some View {
    NavigationView {
      ZStack {
        // Calming gradient background
        LinearGradient(
          gradient: Gradient(colors: [
            Color(hex: "#98D8C8").opacity(0.1),
            Color.blue.opacity(0.1),
            Color.mint.opacity(0.1),
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 30) {
          // Header
          VStack(spacing: 12) {
            Text("🎮 Choose Your Game")
              .font(.title)
              .fontWeight(.bold)
              .foregroundColor(Color(.label))

            Text("Pick a calming activity to distract and relax")
              .font(.body)
              .foregroundColor(Color(.secondaryLabel))
              .multilineTextAlignment(.center)
          }
          .padding(.top, 20)

          // Game options
          VStack(spacing: 20) {
            // Bubble Pop Game
            GameOptionCard(
              emoji: "🫧",
              title: "Bubble Pop",
              description: "Pop floating bubbles to release tension",
              color: .blue
            ) {
              presentationMode.wrappedValue.dismiss()
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingBubbleGame = true
              }
            }

            // Memory Game
            GameOptionCard(
              emoji: "🧠",
              title: "Memory Match",
              description: "Find matching pairs to focus your mind",
              color: Color(hex: "#98D8C8")
            ) {
              presentationMode.wrappedValue.dismiss()
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingMemoryGame = true
              }
            }

            // Calm Coloring
            GameOptionCard(
              emoji: "🎨",
              title: "Calm Coloring",
              description: "Fill shapes with soothing colors",
              color: .mint
            ) {
              presentationMode.wrappedValue.dismiss()
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingColoringGame = true
              }
            }
          }
          .padding(.horizontal, 20)

          Spacer()

          // Close button
          Button(action: {
            presentationMode.wrappedValue.dismiss()
          }) {
            Text("Close")
              .font(.headline)
              .fontWeight(.semibold)
              .foregroundColor(Color(.label))
              .padding(.horizontal, 40)
              .padding(.vertical, 12)
              .background(
                RoundedRectangle(cornerRadius: 25)
                  .fill(Color(.systemBackground))
              )
          }
          .padding(.bottom, 30)
        }
      }
      .navigationBarHidden(true)
    }
  }
}

struct GameOptionCard: View {
  let emoji: String
  let title: String
  let description: String
  let color: Color
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 20) {
        // Emoji
        Text(emoji)
          .font(.system(size: 40))
          .frame(width: 60, height: 60)
          .background(
            Circle()
              .fill(color.opacity(0.2))
          )

        // Text content
        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundColor(Color(.label))

          Text(description)
            .font(.body)
            .foregroundColor(Color(.secondaryLabel))
            .multilineTextAlignment(.leading)
        }

        Spacer()

        // Arrow indicator
        Image(systemName: "chevron.right")
          .font(.title3)
          .foregroundColor(.gray)
      }
      .padding(20)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(.systemBackground))
          .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

#Preview {
  GameSelectionView(
    showingBubbleGame: .constant(false),
    showingMemoryGame: .constant(false),
    showingColoringGame: .constant(false)
  )
}
