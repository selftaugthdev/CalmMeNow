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
  var body: some Scene {
    WindowGroup {
      MainTabView()
    }
    .modelContainer(for: JournalEntry.self)
  }
}
