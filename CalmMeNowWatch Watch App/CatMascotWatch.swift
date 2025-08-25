import SwiftUI

struct CatMascotWatch: View {
    @Binding var scale: CGFloat

    var body: some View {
        ZStack {
            Group {
                CatEarWatch().fill(.orange.opacity(0.9))
                    .frame(width: 32, height: 32).offset(x: -28, y: -28)
                CatEarWatch().fill(.orange.opacity(0.9))
                    .frame(width: 32, height: 32).offset(x: 28, y: -28)
            }
            Circle().fill(.orange.opacity(0.85))
                .frame(width: 110, height: 110)

            Group {
                HStack(spacing: 24) {
                    Capsule().fill(.black).frame(width: 8, height: 14)
                    Capsule().fill(.black).frame(width: 8, height: 14)
                }.offset(y: -8)
                Circle().fill(.pink).frame(width: 8, height: 8).offset(y: 6)
                HStack(spacing: 6) {
                    CatSmileHalfWatch(left: true).stroke(.black, lineWidth: 1.5)
                    CatSmileHalfWatch(left: false).stroke(.black, lineWidth: 1.5)
                }
                .frame(width: 28, height: 16).offset(y: 16)
            }
        }
        .scaleEffect(scale)
        .drawingGroup()
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
        p.move(to: s); p.addQuadCurve(to: e, control: c)
        return p
    }
}

