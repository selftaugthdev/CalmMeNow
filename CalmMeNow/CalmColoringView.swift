import SwiftUI

struct ColoringShape: Identifiable {
  let id = UUID()
  var path: Path
  var fillColor: Color
  var isFilled: Bool = false
  var opacity: Double = 0.0
  var scale: CGFloat = 0.8
}

struct CalmColoringView: View {
  @Environment(\.presentationMode) var presentationMode
  @State private var shapes: [ColoringShape] = []
  @State private var selectedColor: Color = .blue
  @State private var brushSize: CGFloat = 20
  @State private var isErasing = false
  @State private var showingColorPicker = false
  @State private var timeSpent: TimeInterval = 0
  @State private var timer: Timer?

  // Soothing color palette
  private let soothingColors: [Color] = [
    .blue, .purple, .mint, .pink, .indigo, .teal,
    .orange, .green, .cyan, .yellow, .red, .brown,
  ]

  var body: some View {
    ZStack {
      // Calming gradient background
      LinearGradient(
        gradient: Gradient(colors: [
          Color.purple.opacity(0.05),
          Color.blue.opacity(0.05),
          Color.mint.opacity(0.05),
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack {
        // Header
        HStack {
          Button(action: {
            stopTimer()
            presentationMode.wrappedValue.dismiss()
          }) {
            Image(systemName: "xmark.circle.fill")
              .font(.title2)
              .foregroundColor(.gray)
          }

          Spacer()

          VStack(spacing: 4) {
            Text("Calm Coloring")
              .font(.title2)
              .fontWeight(.semibold)
              .foregroundColor(.primary)

            Text("Let your creativity flow, let anxiety go")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Spacer()

          // Time spent
          Text(timeString)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.blue)
            .frame(width: 80)
        }
        .padding()

        // Color palette and tools
        HStack(spacing: 16) {
          // Color picker button
          Button(action: { showingColorPicker.toggle() }) {
            Circle()
              .fill(selectedColor)
              .frame(width: 40, height: 40)
              .overlay(
                Circle()
                  .stroke(Color.white, lineWidth: 3)
                  .shadow(color: .black.opacity(0.2), radius: 2)
              )
          }

          // Brush size slider
          VStack(spacing: 4) {
            Text("Brush")
              .font(.caption)
              .foregroundColor(.secondary)
            Slider(value: $brushSize, in: 5...50, step: 5)
              .frame(width: 100)
          }

          // Eraser toggle
          Button(action: { isErasing.toggle() }) {
            Image(systemName: isErasing ? "eraser.fill" : "eraser")
              .font(.title2)
              .foregroundColor(isErasing ? .red : .gray)
              .frame(width: 40, height: 40)
              .background(
                Circle()
                  .fill(isErasing ? Color.red.opacity(0.1) : Color.clear)
              )
          }

          Spacer()

          // New canvas button
          Button(action: createNewCanvas) {
            Image(systemName: "plus.circle.fill")
              .font(.title2)
              .foregroundColor(.blue)
          }
        }
        .padding(.horizontal)

        Spacer()

        // Coloring canvas
        ZStack {
          // Abstract shapes
          ForEach(shapes) { shape in
            shape.path
              .fill(shape.fillColor)
              .opacity(shape.opacity)
              .scaleEffect(shape.scale)
              .animation(.easeInOut(duration: 0.5), value: shape.opacity)
              .animation(.easeInOut(duration: 0.3), value: shape.scale)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { value in
              handleColoring(at: value.location)
            }
            .onEnded { _ in
              // Optional: Add haptic feedback when gesture ends
            }
        )
        .simultaneousGesture(
          TapGesture()
            .onEnded { _ in
              // Handle tap at center of canvas for testing
              let centerX = UIScreen.main.bounds.width / 2
              let centerY = UIScreen.main.bounds.height / 2
              handleColoring(at: CGPoint(x: centerX, y: centerY))
            }
        )

        Spacer()

        // Instructions
        Text("Tap and drag to color • Relax and let your mind wander")
          .font(.caption)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.bottom, 20)
      }
    }
    .onAppear {
      createNewCanvas()
      startTimer()
    }
    .onDisappear {
      stopTimer()
    }
    .sheet(isPresented: $showingColorPicker) {
      ColorPickerView(selectedColor: $selectedColor, colors: soothingColors)
    }
  }

  private var timeString: String {
    let minutes = Int(timeSpent) / 60
    let seconds = Int(timeSpent) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }

  private func createNewCanvas() {
    shapes = []

    // Create abstract, organic shapes
    let screenSize = UIScreen.main.bounds.size
    let centerX = screenSize.width / 2
    let centerY = screenSize.height / 2

    // Flower-like shape
    shapes.append(
      ColoringShape(
        path: createFlowerPath(center: CGPoint(x: centerX - 100, y: centerY - 100)),
        fillColor: soothingColors.randomElement() ?? .blue
      ))

    // Wave-like shape
    shapes.append(
      ColoringShape(
        path: createWavePath(center: CGPoint(x: centerX + 100, y: centerY - 80)),
        fillColor: soothingColors.randomElement() ?? .purple
      ))

    // Spiral shape
    shapes.append(
      ColoringShape(
        path: createSpiralPath(center: CGPoint(x: centerX - 80, y: centerY + 100)),
        fillColor: soothingColors.randomElement() ?? .mint
      ))

    // Organic blob shape
    shapes.append(
      ColoringShape(
        path: createBlobPath(center: CGPoint(x: centerX + 80, y: centerY + 80)),
        fillColor: soothingColors.randomElement() ?? .pink
      ))

    // Leaf-like shape
    shapes.append(
      ColoringShape(
        path: createLeafPath(center: CGPoint(x: centerX, y: centerY)),
        fillColor: soothingColors.randomElement() ?? .green
      ))
  }

  private func handleColoring(at location: CGPoint) {
    for (index, shape) in shapes.enumerated() {
      if shape.path.contains(location) {
        if isErasing {
          // Erase
          withAnimation(.easeInOut(duration: 0.3)) {
            shapes[index].opacity = 0.0
            shapes[index].scale = 0.8
            shapes[index].isFilled = false
          }
        } else {
          // Color
          withAnimation(.easeInOut(duration: 0.5)) {
            shapes[index].fillColor = selectedColor
            shapes[index].opacity = 0.8
            shapes[index].scale = 1.0
            shapes[index].isFilled = true
          }
        }
        break
      }
    }
  }

  private func startTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      timeSpent += 1
    }
  }

  private func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  // MARK: - Shape Creation Methods

  private func createFlowerPath(center: CGPoint) -> Path {
    Path { path in
      let radius: CGFloat = 40
      let petalCount = 6

      for i in 0..<petalCount {
        let angle = Double(i) * 2 * .pi / Double(petalCount)
        let petalX = center.x + cos(angle) * radius
        let petalY = center.y + sin(angle) * radius

        if i == 0 {
          path.move(to: CGPoint(x: petalX, y: petalY))
        } else {
          path.addLine(to: CGPoint(x: petalX, y: petalY))
        }
      }
      path.closeSubpath()
    }
  }

  private func createWavePath(center: CGPoint) -> Path {
    Path { path in
      let width: CGFloat = 80
      let height: CGFloat = 60

      path.move(to: CGPoint(x: center.x - width / 2, y: center.y))

      for i in 0...10 {
        let x = center.x - width / 2 + (width / 10) * CGFloat(i)
        let y = center.y + sin(Double(i) * .pi / 5) * height / 2
        path.addLine(to: CGPoint(x: x, y: y))
      }

      path.addLine(to: CGPoint(x: center.x + width / 2, y: center.y + height / 2))
      path.addLine(to: CGPoint(x: center.x - width / 2, y: center.y + height / 2))
      path.closeSubpath()
    }
  }

  private func createSpiralPath(center: CGPoint) -> Path {
    Path { path in
      let maxRadius: CGFloat = 50
      let rotations = 3

      path.move(to: center)

      for i in 0...100 {
        let angle = Double(i) * .pi / 50 * Double(rotations)
        let radius = maxRadius * Double(i) / 100
        let x = center.x + cos(angle) * radius
        let y = center.y + sin(angle) * radius
        path.addLine(to: CGPoint(x: x, y: y))
      }
    }
  }

  private func createBlobPath(center: CGPoint) -> Path {
    Path { path in
      let radius: CGFloat = 45

      path.move(to: CGPoint(x: center.x + radius, y: center.y))

      // Create organic blob with multiple curves
      path.addCurve(
        to: CGPoint(x: center.x, y: center.y + radius),
        control1: CGPoint(x: center.x + radius * 0.8, y: center.y + radius * 0.3),
        control2: CGPoint(x: center.x + radius * 0.3, y: center.y + radius * 0.8)
      )

      path.addCurve(
        to: CGPoint(x: center.x - radius, y: center.y),
        control1: CGPoint(x: center.x - radius * 0.3, y: center.y + radius * 0.8),
        control2: CGPoint(x: center.x - radius * 0.8, y: center.y + radius * 0.3)
      )

      path.addCurve(
        to: CGPoint(x: center.x, y: center.y - radius),
        control1: CGPoint(x: center.x - radius * 0.8, y: center.y - radius * 0.3),
        control2: CGPoint(x: center.x - radius * 0.3, y: center.y - radius * 0.8)
      )

      path.addCurve(
        to: CGPoint(x: center.x + radius, y: center.y),
        control1: CGPoint(x: center.x + radius * 0.3, y: center.y - radius * 0.8),
        control2: CGPoint(x: center.x + radius * 0.8, y: center.y - radius * 0.3)
      )

      path.closeSubpath()
    }
  }

  private func createLeafPath(center: CGPoint) -> Path {
    Path { path in
      let width: CGFloat = 60
      let height: CGFloat = 80

      path.move(to: CGPoint(x: center.x, y: center.y - height / 2))

      path.addCurve(
        to: CGPoint(x: center.x + width / 2, y: center.y),
        control1: CGPoint(x: center.x + width / 4, y: center.y - height / 3),
        control2: CGPoint(x: center.x + width / 2, y: center.y - height / 6)
      )

      path.addCurve(
        to: CGPoint(x: center.x, y: center.y + height / 2),
        control1: CGPoint(x: center.x + width / 2, y: center.y + height / 6),
        control2: CGPoint(x: center.x + width / 4, y: center.y + height / 3)
      )

      path.addCurve(
        to: CGPoint(x: center.x - width / 2, y: center.y),
        control1: CGPoint(x: center.x - width / 4, y: center.y + height / 3),
        control2: CGPoint(x: center.x - width / 2, y: center.y + height / 6)
      )

      path.addCurve(
        to: CGPoint(x: center.x, y: center.y - height / 2),
        control1: CGPoint(x: center.x - width / 2, y: center.y - height / 6),
        control2: CGPoint(x: center.x - width / 4, y: center.y - height / 3)
      )

      path.closeSubpath()
    }
  }
}

struct ColorPickerView: View {
  @Binding var selectedColor: Color
  let colors: [Color]
  @Environment(\.presentationMode) var presentationMode

  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Text("Choose Your Calming Color")
          .font(.title2)
          .fontWeight(.semibold)
          .padding(.top)

        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
          ForEach(colors, id: \.self) { color in
            Button(action: {
              selectedColor = color
              presentationMode.wrappedValue.dismiss()
            }) {
              Circle()
                .fill(color)
                .frame(width: 60, height: 60)
                .overlay(
                  Circle()
                    .stroke(selectedColor == color ? Color.blue : Color.clear, lineWidth: 4)
                )
                .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: selectedColor == color)
            }
          }
        }
        .padding()

        Spacer()
      }
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarItems(
        trailing: Button("Done") {
          presentationMode.wrappedValue.dismiss()
        })
    }
  }
}

#Preview {
  CalmColoringView()
}
