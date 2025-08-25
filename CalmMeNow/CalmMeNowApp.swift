//
//  CalmMeNowApp.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import SwiftData
import SwiftUI

@main
struct CalmMeNowApp: App {
  init() {
    // Activate Watch Connectivity session
    PhoneWCSessionHandler.shared.activate()
  }

  var body: some Scene {
    WindowGroup {
      MainTabView()
    }
    .modelContainer(for: JournalEntry.self)
  }
}
