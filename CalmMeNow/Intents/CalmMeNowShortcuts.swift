import AppIntents

struct CalmMeNowShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: CalmMeDownIntent(),
      phrases: [
        "Calm me down with \(.applicationName)",
        "I'm having a panic attack with \(.applicationName)",
        "Open emergency calm in \(.applicationName)",
        "Help me calm down with \(.applicationName)",
        "Start \(.applicationName)",
      ],
      shortTitle: "Calm Me Down",
      systemImageName: "heart.fill"
    )
  }
}
