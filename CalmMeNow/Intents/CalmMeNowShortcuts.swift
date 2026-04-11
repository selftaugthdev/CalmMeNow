import AppIntents

struct CalmMeNowShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: CalmMeDownIntent(),
      phrases: [
        "Open \(.applicationName)",
        "Start \(.applicationName)",
        "I'm having a panic attack with \(.applicationName)",
        "I'm panicking, open \(.applicationName)",
        "Help me breathe with \(.applicationName)",
        "Open emergency calm in \(.applicationName)",
        "Calm me down with \(.applicationName)",
        "Help me calm down with \(.applicationName)",
      ],
      shortTitle: "Calm Me Down",
      systemImageName: "heart.fill"
    )
  }
}
