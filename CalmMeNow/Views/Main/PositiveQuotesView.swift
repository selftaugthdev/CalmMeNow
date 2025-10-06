import AVFoundation
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
  @StateObject private var store = QuoteStore()
  @State private var quote: PositiveQuote = PositiveQuotesService.shared.randomQuote()
  @State private var isFading = false
  @State private var isSpeaking = false
  @State private var isFavorite = false
  @State private var showingMyBoosts = false
  @State private var speechSynthesizer = AVSpeechSynthesizer()
  @State private var speechDelegate: SpeechDelegateWrapper? = nil

  var body: some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "#0E2D6C"),
          Color(hex: "#6A92C8"),
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      CalmBreathingOrb()
        .allowsHitTesting(false)

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

        Text("Take one slow breath while you read.")
          .font(.subheadline)
          .foregroundColor(.white.opacity(0.9))

        VStack(alignment: .leading, spacing: 16) {
          Text("\"\(quote.text)\"")
            .font(.system(size: 26, weight: .semibold, design: .serif))
            .foregroundColor(.black)
            .multilineTextAlignment(.leading)
            .transition(.opacity)

          Divider()

          Text(quote.reflection)
            .font(.body)
            .foregroundColor(.black.opacity(0.8))
            .transition(.opacity)
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

        // Action buttons card
        VStack(spacing: 12) {
          HStack(spacing: 20) {
            Button(action: toggleFavorite) {
              VStack(spacing: 4) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                  .font(.title2)
                  .foregroundColor(.red)
                Text(isFavorite ? "Saved" : "Favorite")
                  .font(.caption)
                  .foregroundColor(.red)
              }
            }

            Button(action: shuffleQuote) {
              VStack(spacing: 4) {
                Image(systemName: "arrow.clockwise")
                  .font(.title2)
                  .foregroundColor(.blue)
                Text("New Quote")
                  .font(.caption)
                  .foregroundColor(.blue)
              }
            }

            Button(action: speakQuote) {
              VStack(spacing: 4) {
                Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                  .font(.title2)
                  .foregroundColor(.blue)
                Text(isSpeaking ? "Reading" : "Read Aloud")
                  .font(.caption)
                  .foregroundColor(.blue)
              }
            }

            Button(action: { showingMyBoosts = true }) {
              VStack(spacing: 4) {
                Image(systemName: "heart.text.square")
                  .font(.title2)
                  .foregroundColor(.blue)
                Text("Saved Quotes")
                  .font(.caption)
                  .foregroundColor(.blue)
              }
            }
          }
        }
        .padding(16)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.9))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 24)

        Spacer(minLength: 0)
      }
      .onAppear {
        store.load()
        isFavorite = PositiveQuotesService.shared.isFavorite(quote)
      }
      .onChange(of: quote) { _ in
        isFavorite = PositiveQuotesService.shared.isFavorite(quote)
      }
      .sheet(isPresented: $showingMyBoosts) {
        MyBoostsView()
      }
    }
  }

  private func shuffleQuote() {
    isFading = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      if store.quotes.isEmpty { store.load() }
      if let next = store.next() {
        quote = next
      } else {
        quote = PositiveQuotesService.shared.randomQuote()
      }
      isFading = false
    }
  }

  private func toggleFavorite() {
    PositiveQuotesService.shared.toggleFavorite(quote)
    isFavorite.toggle()
    HapticManager.shared.success()
  }

  private func speakQuote() {
    let utterance = AVSpeechUtterance(string: "\(quote.text). \(quote.reflection)")
    utterance.rate = 0.42
    utterance.pitchMultiplier = 0.95
    if let voice = selectDanielVoice() { utterance.voice = voice }
    isSpeaking = true
    let delegate = SpeechDelegateWrapper(onFinish: { isSpeaking = false })
    speechDelegate = delegate
    speechSynthesizer.delegate = delegate
    speechSynthesizer.speak(utterance)
  }

  private func selectDanielVoice() -> AVSpeechSynthesisVoice? {
    // Prefer Daniel by name, then by known identifiers, finally en-GB fallback
    let voices = AVSpeechSynthesisVoice.speechVoices()
    if let danielByName = voices.first(where: { $0.name.lowercased().contains("daniel") }) {
      return danielByName
    }
    if let premium = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.daniel-premium") {
      return premium
    }
    if let compact = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.daniel-compact") {
      return compact
    }
    return AVSpeechSynthesisVoice(language: "en-GB")
  }
}

// Lightweight delegate wrapper to reset isSpeaking when finished
private final class SpeechDelegateWrapper: NSObject, AVSpeechSynthesizerDelegate {
  private let onFinish: () -> Void
  init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance)
  { onFinish() }
}
