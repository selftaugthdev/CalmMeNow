//
//  CalmMeNowApp.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import FirebaseCore
import SwiftData
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct CalmMeNowApp: App {
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

  init() {
    // Activate Watch Connectivity session
    PhoneWCSessionHandler.shared.activate()

    // Initialize Firebase Analytics
    FirebaseAnalyticsService.shared.setUserProperties()
    FirebaseAnalyticsService.shared.checkFirebaseConfiguration()
  }

  var body: some Scene {
    WindowGroup {
      if hasCompletedOnboarding {
        MainTabView()
      } else {
        OnboardingView()
      }
    }
    .modelContainer(for: JournalEntry.self)
  }
}
