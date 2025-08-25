import SwiftUI

struct CatMascotWatch: View {
  @Binding var scale: CGFloat

  var body: some View {
    GeometryReader { geo in
      let S = min(geo.size.width, geo.size.height)  // total mascot box
      let head = S * 0.74  // head diameter (leave margin)
      let ear = S * 0.26  // ear triangle size

      ZStack {
        // Ears (top, slightly angled up)
        CatEarWatch()
          .fill(Color.orange.opacity(0.9))
          .frame(width: ear, height: ear)
          .rotationEffect(.degrees(-10))
          .position(x: S * 0.32, y: S * 0.18)

        CatEarWatch()
          .fill(Color.orange.opacity(0.9))
          .frame(width: ear, height: ear)
          .rotationEffect(.degrees(10))
          .position(x: S * 0.68, y: S * 0.18)

        // Head
        Circle()
          .fill(Color.orange.opacity(0.85))
          .frame(width: head, height: head)
          .position(x: S * 0.5, y: S * 0.54)

        // Eyes
        HStack(spacing: head * 0.22) {
          Capsule().fill(.black).frame(width: head * 0.09, height: head * 0.16)
          Capsule().fill(.black).frame(width: head * 0.09, height: head * 0.16)
        }
        .position(x: S * 0.5, y: S * 0.48)

        // Nose + smile
        Circle().fill(.pink).frame(width: head * 0.08, height: head * 0.08)
          .position(x: S * 0.5, y: S * 0.60)

        HStack(spacing: head * 0.06) {
          CatSmileHalfWatch(left: true).stroke(.black, lineWidth: 1.5)
          CatSmileHalfWatch(left: false).stroke(.black, lineWidth: 1.5)
        }
        .frame(width: head * 0.34, height: head * 0.18)
        .position(x: S * 0.5, y: S * 0.66)
      }
      .scaleEffect(scale, anchor: .center)
    }
    .accessibilityHidden(true)
  }
}

struct CatEarWatch: Shape {
  func path(in r: CGRect) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: r.midX, y: r.maxY))
    p.addLine(to: CGPoint(x: r.minX, y: r.minY + 6))
    p.addLine(to: CGPoint(x: r.maxX, y: r.minY + 6))
    p.closeSubpath()
    return p
  }
}

struct CatSmileHalfWatch: Shape {
  let left: Bool
  func path(in r: CGRect) -> Path {
    var p = Path()
    let s = CGPoint(x: left ? r.maxX : r.minX, y: r.minY)
    let e = CGPoint(x: left ? r.minX : r.maxX, y: r.minY)
    let c = CGPoint(x: r.midX, y: r.maxY)
    p.move(to: s)
    p.addQuadCurve(to: e, control: c)
    return p
  }
}
