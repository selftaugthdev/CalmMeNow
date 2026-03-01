import SwiftUI

struct BreathingLibraryView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var service = BreathingProgramService.shared
  @StateObject private var paywallManager = PaywallManager.shared

  @State private var selectedProgram: BreathingProgram?
  @State private var showingPlayer = false
  @State private var showingCreator = false

  var body: some View {
    NavigationView {
      ZStack {
        LinearGradient(
          gradient: Gradient(colors: [
            Color.blue.opacity(0.05),
            Color.mint.opacity(0.05),
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        ScrollView {
          VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
              Text("🫁")
                .font(.system(size: 50))
              Text("Breathing Programs")
                .font(.title)
                .fontWeight(.bold)
              Text("Clinically-backed techniques for calm")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.top, 20)

            // MARK: Techniques
            sectionCard(title: "TECHNIQUES") {
              VStack(spacing: 0) {
                ForEach(service.builtInPrograms) { program in
                  ProgramRow(
                    program: program,
                    isFavorite: service.favoriteIds.contains(program.id),
                    onTap: { handleTap(program) },
                    onFavorite: { handleFavorite(program) }
                  )
                  if program.id != service.builtInPrograms.last?.id {
                    Divider().padding(.leading, 60)
                  }
                }
              }
            }

            // MARK: Favorites
            sectionCard(title: "FAVORITES") {
              if service.favoritePrograms.isEmpty {
                HStack {
                  Image(systemName: "heart")
                    .foregroundColor(.secondary)
                  Text("Tap ♡ on any program to save it here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding()
              } else {
                VStack(spacing: 0) {
                  ForEach(service.favoritePrograms) { program in
                    ProgramRow(
                      program: program,
                      isFavorite: true,
                      onTap: { handleTap(program) },
                      onFavorite: { handleFavorite(program) }
                    )
                    if program.id != service.favoritePrograms.last?.id {
                      Divider().padding(.leading, 60)
                    }
                  }
                }
              }
            }

            // MARK: My Programs
            sectionCard(title: "MY PROGRAMS") {
              VStack(spacing: 0) {
                // Create button
                Button(action: { handleCreateCustom() }) {
                  HStack {
                    Image(systemName: "plus.circle.fill")
                      .foregroundColor(.blue)
                      .font(.title3)
                    Text("Create a custom program")
                      .font(.body)
                      .foregroundColor(.blue)
                    Spacer()
                    if !paywallManager.hasAIAccess {
                      Text("🔒")
                    }
                  }
                  .padding()
                }

                if !service.customPrograms.isEmpty {
                  Divider().padding(.leading, 60)
                  ForEach(service.customPrograms) { program in
                    ProgramRow(
                      program: program,
                      isFavorite: service.favoriteIds.contains(program.id),
                      onTap: { handleTap(program) },
                      onFavorite: { handleFavorite(program) }
                    )
                    .swipeActions(edge: .trailing) {
                      Button(role: .destructive) {
                        service.deleteCustom(id: program.id)
                      } label: {
                        Label("Delete", systemImage: "trash")
                      }
                    }
                    if program.id != service.customPrograms.last?.id {
                      Divider().padding(.leading, 60)
                    }
                  }
                }
              }
            }

            Spacer(minLength: 40)
          }
          .padding(.horizontal, 16)
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.gray)
              .font(.title3)
          }
        }
      }
    }
    .fullScreenCover(item: $selectedProgram) { program in
      BreathingProgramPlayerView(program: program)
    }
    .sheet(isPresented: $showingCreator) {
      CustomBreathingCreatorView()
    }
  }

  // MARK: - Actions

  private func handleTap(_ program: BreathingProgram) {
    HapticManager.shared.softImpact()
    if program.isFree {
      selectedProgram = program
    } else if !PaywallManager.freeLaunchMode && paywallManager.hasAIAccess {
      // Real subscriber in production
      selectedProgram = program
    } else {
      paywallManager.showPaywall()
    }
  }

  private func handleFavorite(_ program: BreathingProgram) {
    if paywallManager.hasAIAccess {
      service.toggleFavorite(program)
      HapticManager.shared.lightImpact()
    } else {
      Task {
        let _ = await paywallManager.requestAIAccess()
      }
    }
  }

  private func handleCreateCustom() {
    if paywallManager.hasAIAccess {
      showingCreator = true
    } else {
      Task {
        let hasAccess = await paywallManager.requestAIAccess()
        if hasAccess {
          await MainActor.run { showingCreator = true }
        }
      }
    }
  }

  // MARK: - Helpers

  @ViewBuilder
  private func sectionCard<Content: View>(
    title: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(title)
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)

      VStack(spacing: 0) {
        content()
      }
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(.systemBackground))
          .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
      )
    }
  }
}

// MARK: - Program Row

private struct ProgramRow: View {
  let program: BreathingProgram
  let isFavorite: Bool
  let onTap: () -> Void
  let onFavorite: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Text(program.emoji)
        .font(.title2)
        .frame(width: 40)

      VStack(alignment: .leading, spacing: 2) {
        Text(program.name)
          .font(.body)
          .fontWeight(.medium)
        Text("\(program.ratioLabel) · \(program.durationLabel)")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      // Free / locked badge
      if program.isFree {
        Text("FREE")
          .font(.caption2)
          .fontWeight(.bold)
          .foregroundColor(.green)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(Color.green.opacity(0.12))
          .cornerRadius(6)
      } else {
        Text("🔒")
          .font(.caption)
      }

      // Favorite button
      Button(action: onFavorite) {
        Image(systemName: isFavorite ? "heart.fill" : "heart")
          .foregroundColor(isFavorite ? .red : .gray)
          .font(.body)
      }
      .buttonStyle(PlainButtonStyle())

      // Play button
      Button(action: onTap) {
        Image(systemName: "play.circle.fill")
          .foregroundColor(.blue)
          .font(.title2)
      }
      .buttonStyle(PlainButtonStyle())
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .contentShape(Rectangle())
  }
}

#Preview {
  BreathingLibraryView()
}
