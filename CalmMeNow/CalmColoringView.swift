import CoreHaptics
import SwiftUI

// ---- Shapes (same idea as before)
struct Petal: Shape {
  let index: Int
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let R = min(rect.width, rect.height) * 0.38
    let r = R * 0.45
    let angle = (Double(index) * (2 * .pi / 6))
    let a1 = angle - .pi / 12
    let a2 = angle + .pi / 12

    let tip = CGPoint(
      x: center.x + CGFloat(cos(angle)) * R,
      y: center.y + CGFloat(sin(angle)) * R)
    let c1 = CGPoint(
      x: center.x + CGFloat(cos(a1)) * r,
      y: center.y + CGFloat(sin(a1)) * r)
    let c2 = CGPoint(
      x: center.x + CGFloat(cos(a2)) * r,
      y: center.y + CGFloat(sin(a2)) * r)

    p.move(to: center)
    p.addQuadCurve(to: tip, control: c1)
    p.addQuadCurve(to: center, control: c2)
    p.closeSubpath()
    return p
  }
}

struct CenterCircle: Shape {
  func path(in rect: CGRect) -> Path {
    let d = min(rect.width, rect.height) * 0.25
    let r = d / 2
    let c = CGPoint(x: rect.midX, y: rect.midY)
    return Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: d, height: d))
  }
}

// ---- Coloring + Tracing
struct ColoringPageWithTraceView: View {
  @Environment(\.presentationMode) var presentationMode
  @State private var regionColors: [Color?] = Array(repeating: nil, count: 7)  // 6 petals + center
  @State private var selectedColor: Color = .mint
  @State private var traceMode: Bool = false

  // tracing state
  @State private var tracePoints: [CGPoint] = []
  @State private var onPathCount: Int = 0
  @State private var totalCount: Int = 0
  @State private var haptic: UINotificationFeedbackGenerator? = UINotificationFeedbackGenerator()

  var accuracy: Int {
    guard totalCount > 0 else { return 0 }
    return Int((Double(onPathCount) / Double(totalCount)) * 100.0)
  }

  var body: some View {
    VStack(spacing: 12) {
      // Toolbar
      HStack {
        Button {
          presentationMode.wrappedValue.dismiss()
        } label: {
          Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray)
        }
        Spacer()
        Text("Calm Coloring").font(.headline)
        Spacer()
        ColorPicker("", selection: $selectedColor).labelsHidden().frame(width: 28, height: 28)
      }
      .padding(.horizontal)

      // Mode toggle
      HStack(spacing: 16) {
        Toggle(isOn: $traceMode) {
          Text("Trace Mode")
        }
        .toggleStyle(SwitchToggleStyle(tint: .yellow))
        .frame(maxWidth: .infinity, alignment: .leading)

        if traceMode {
          Text("Accuracy: \(accuracy)%")
            .font(.subheadline)
            .fontWeight(.semibold)
        }
      }
      .padding(.horizontal)

      GeometryReader { geo in
        ZStack {
          // FILLS
          ForEach(0..<6, id: \.self) { i in
            Petal(index: i)
              .fill(regionColors[i] ?? Color.clear)
          }
          CenterCircle()
            .fill(regionColors[6] ?? Color.clear)

          // OUTLINES
          ForEach(0..<6, id: \.self) { i in
            Petal(index: i).stroke(.secondary.opacity(0.6), lineWidth: 2)
          }
          CenterCircle().stroke(.secondary.opacity(0.6), lineWidth: 2)

          // TAP-TO-FILL (only when not tracing)
          if !traceMode {
            ForEach(0..<6, id: \.self) { i in
              Petal(index: i)
                .fill(Color.clear)
                .contentShape(Petal(index: i))
                .onTapGesture { regionColors[i] = selectedColor }
            }
            CenterCircle()
              .fill(Color.clear)
              .contentShape(CenterCircle())
              .onTapGesture { regionColors[6] = selectedColor }
          }

          // TRACE MODE overlay drawing
          if traceMode {
            // user stroke
            Path { p in
              guard let first = tracePoints.first else { return }
              p.move(to: first)
              for pt in tracePoints.dropFirst() { p.addLine(to: pt) }
            }
            .stroke(
              Color.accentColor.opacity(0.8),
              style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
          }
        }
        .contentShape(Rectangle())
        .gesture(
          traceMode
            ? DragGesture(minimumDistance: 0)
              .onChanged { value in
                let pt = value.location
                tracePoints.append(pt)

                // Build a union of all stroked outlines (petals + center)
                var outline = Path()
                for i in 0..<6 {
                  outline.addPath(Petal(index: i).path(in: geo.frame(in: .local)))
                }
                outline.addPath(CenterCircle().path(in: geo.frame(in: .local)))

                let stroked = outline.strokedPath(
                  .init(lineWidth: 24, lineCap: .round, lineJoin: .round))  // tolerance

                totalCount += 1
                if stroked.contains(pt) {
                  onPathCount += 1
                  if onPathCount % 12 == 0 { haptic?.notificationOccurred(.success) }
                }
              }
              .onEnded { _ in
                // gentle checkpoint haptic
                haptic?.notificationOccurred(.success)
              }
            : nil
        )
        .padding(24)
      }

      // Actions
      HStack {
        Button("Reset Colors") { regionColors = Array(repeating: nil, count: 7) }
        Spacer()
        Button("Clear Trace") {
          tracePoints.removeAll()
          onPathCount = 0
          totalCount = 0
        }
      }
      .padding(.horizontal)
      .padding(.bottom, 10)
    }
  }
}

#Preview { ColoringPageWithTraceView() }
