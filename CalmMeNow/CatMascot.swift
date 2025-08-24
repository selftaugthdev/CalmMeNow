import SwiftUI

struct CatMascot: View {
  // Theme
  var primary = Color(#colorLiteral(red: 0.93, green: 0.86, blue: 0.75, alpha: 1))  // fur
  var secondary = Color(#colorLiteral(red: 0.84, green: 0.74, blue: 0.63, alpha: 1))  // inner ear / patches
  var accent = Color(#colorLiteral(red: 0.33, green: 0.23, blue: 0.19, alpha: 1))  // line color

  // Animation
  @State private var breathe = false
  @State private var blink = false
  @State private var tailWag = false
  @State private var earTwitch = false

  var body: some View {
    ZStack {
      // Body (breathing)
      VStack(spacing: 0) {
        // Head
        ZStack {
          // Ears
          CatEar()
            .fill(primary)
            .overlay(
              CatEar()
                .scale(0.8)
                .fill(secondary)
            )
            .frame(width: 70, height: 70)
            .rotationEffect(.degrees(-8 + (earTwitch ? -3 : 0)), anchor: .bottomTrailing)
            .offset(x: -45, y: -45)

          CatEar()
            .fill(primary)
            .overlay(
              CatEar()
                .scale(0.8)
                .fill(secondary)
            )
            .frame(width: 70, height: 70)
            .rotationEffect(.degrees(8 + (earTwitch ? 3 : 0)), anchor: .bottomLeading)
            .offset(x: 45, y: -45)

          // Head circle
          Circle()
            .fill(primary)
            .frame(width: 160, height: 160)

          // Face
          Group {
            // Eyes (blink by scaling Y)
            HStack(spacing: 44) {
              Capsule()
                .fill(accent)
                .frame(width: 16, height: 22)
                .scaleEffect(y: blink ? 0.1 : 1, anchor: .center)
              Capsule()
                .fill(accent)
                .frame(width: 16, height: 22)
                .scaleEffect(y: blink ? 0.1 : 1, anchor: .center)
            }
            .offset(y: -10)

            // Nose
            CatNose()
              .fill(Color.pink.opacity(0.9))
              .frame(width: 20, height: 14)
              .offset(y: 6)

            // Mouth
            HStack(spacing: 8) {
              CatSmileHalf(direction: .left).stroke(accent, lineWidth: 2)
              CatSmileHalf(direction: .right).stroke(accent, lineWidth: 2)
            }
            .frame(width: 44, height: 30)
            .offset(y: 22)

            // Whiskers
            Group {
              // Left whiskers
              Whisker().stroke(accent.opacity(0.8), lineWidth: 2)
                .frame(width: 48, height: 12).offset(x: -70, y: 6)
              Whisker().rotation(Angle(degrees: -10))
                .stroke(accent.opacity(0.8), lineWidth: 2)
                .frame(width: 48, height: 12).offset(x: -70, y: -6)

              // Right whiskers (using separate shapes instead of scaleEffect)
              WhiskerRight().stroke(accent.opacity(0.8), lineWidth: 2)
                .frame(width: 48, height: 12).offset(x: 70, y: 6)
              WhiskerRight().rotation(Angle(degrees: 10))
                .stroke(accent.opacity(0.8), lineWidth: 2)
                .frame(width: 48, height: 12).offset(x: 70, y: -6)
            }
          }
        }
        .padding(.bottom, -6)

        // Torso
        ZStack {
          Ellipse()
            .fill(primary)
            .frame(width: 180, height: 120)

          // Belly patch
          Ellipse()
            .fill(Color.white.opacity(0.9))
            .frame(width: 90, height: 70)
            .offset(y: 12)

          // Paws
          HStack(spacing: 40) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
              .fill(primary)
              .frame(width: 36, height: 22)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
              .fill(primary)
              .frame(width: 36, height: 22)
          }
          .offset(y: 52)
        }
        .scaleEffect(breathe ? 1.05 : 0.96)  // breathing
      }
      .scaleEffect(breathe ? 1.02 : 0.98)
      .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: breathe)

      // Tail (behind body)
      TailShape()
        .stroke(primary, lineWidth: 18)
        .frame(width: 160, height: 160)
        .rotationEffect(.degrees(tailWag ? 12 : -6), anchor: .topLeading)
        .offset(x: 84, y: 70)
        .shadow(radius: 0.1)
        .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: tailWag)
    }
    .onAppear {
      breathe = true
      tailWag = true

      // Blink loop (random-ish)
      blink = false
      Task {
        while true {
          try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 1.5...4.0) * 1_000_000_000))
          withAnimation(.easeOut(duration: 0.12)) { blink = true }
          withAnimation(.easeIn(duration: 0.12).delay(0.12)) { blink = false }
        }
      }

      // Gentle ear twitch every few seconds
      Task {
        while true {
          try? await Task.sleep(nanoseconds: 3_000_000_000)
          withAnimation(.easeInOut(duration: 0.25)) { earTwitch = true }
          withAnimation(.easeInOut(duration: 0.25).delay(0.25)) { earTwitch = false }
        }
      }
    }
    .accessibilityHidden(true)
  }
}

// MARK: - Parts

struct CatEar: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
    p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + 10))
    p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 10))
    p.closeSubpath()
    return p
  }
}

struct CatNose: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: rect.midX, y: rect.minY))
    p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    p.closeSubpath()
    return p
  }
}

enum SmileDir { case left, right }

struct CatSmileHalf: Shape {
  let direction: SmileDir
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let start = CGPoint(x: direction == .left ? rect.maxX : rect.minX, y: rect.minY)
    let end = CGPoint(x: direction == .left ? rect.minX : rect.maxX, y: rect.minY)
    let cp = CGPoint(x: rect.midX, y: rect.maxY)  // curve downward for cuteness
    p.move(to: start)
    p.addQuadCurve(to: end, control: cp)
    return p
  }
}

struct Whisker: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: rect.minX, y: rect.midY))
    p.addQuadCurve(
      to: CGPoint(x: rect.maxX, y: rect.midY),
      control: CGPoint(x: rect.midX, y: rect.midY - 6))
    return p
  }
}

struct WhiskerRight: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: rect.maxX, y: rect.midY))
    p.addQuadCurve(
      to: CGPoint(x: rect.minX, y: rect.midY),
      control: CGPoint(x: rect.midX, y: rect.midY - 6))
    return p
  }
}

struct TailShape: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: rect.minX + 10, y: rect.maxY - 10))
    p.addQuadCurve(
      to: CGPoint(x: rect.maxX - 20, y: rect.minY + 20),
      control: CGPoint(x: rect.midX + 10, y: rect.midY + 40))
    return p
  }
}
