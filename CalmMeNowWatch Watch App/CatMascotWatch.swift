import SwiftUI

struct CatMascotWatch: View {
  @Binding var scale: CGFloat

  var body: some View {
    GeometryReader { geo in
      let S = min(geo.size.width, geo.size.height)  // mascot box
      let head = S * 0.74  // head diameter
      let r = head / 2  // head radius
      let center = CGPoint(x: S * 0.5, y: S * 0.54)  // head center
      let earSize = S * 0.24  // ear size
      let earAngle = Angle(degrees: 28)  // spread from top
      let seatRadius = r * 0.96  // where ear bases touch the head (slightly inside)

      // Compute ear centers at angles ±earAngle from 90° (top)
      let leftPos = CGPoint(
        x: center.x + CGFloat(cos((.pi / 2) + earAngle.radians)) * seatRadius,
        y: center.y - CGFloat(sin((.pi / 2) + earAngle.radians)) * seatRadius
      )
      let rightPos = CGPoint(
        x: center.x + CGFloat(cos((.pi / 2) - earAngle.radians)) * seatRadius,
        y: center.y - CGFloat(sin((.pi / 2) - earAngle.radians)) * seatRadius
      )

      ZStack {
        // Ears — anchored at bottom so they "sit" on the rim
        CatEarWatch()
          .fill(Color.orange.opacity(0.9))
          .frame(width: earSize, height: earSize)
          .rotationEffect(.degrees(-8), anchor: .bottom)  // tiny tilt
          .position(leftPos)

        CatEarWatch()
          .fill(Color.orange.opacity(0.9))
          .frame(width: earSize, height: earSize)
          .rotationEffect(.degrees(8), anchor: .bottom)
          .position(rightPos)

        // Head
        Circle()
          .fill(Color.orange.opacity(0.85))
          .frame(width: head, height: head)
          .position(center)

        // Eyes
        HStack(spacing: head * 0.22) {
          Capsule().fill(.black).frame(width: head * 0.09, height: head * 0.16)
          Capsule().fill(.black).frame(width: head * 0.09, height: head * 0.16)
        }
        .position(x: center.x, y: center.y - head * 0.14)

        // Nose + smile
        Circle().fill(.pink).frame(width: head * 0.08, height: head * 0.08)
          .position(x: center.x, y: center.y + head * 0.06)

        HStack(spacing: head * 0.06) {
          CatSmileHalfWatch(left: true).stroke(.black, lineWidth: 1.5)
          CatSmileHalfWatch(left: false).stroke(.black, lineWidth: 1.5)
        }
        .frame(width: head * 0.34, height: head * 0.18)
        .position(x: center.x, y: center.y + head * 0.13)
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
