//
//  CalmMeNowApp.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import FirebaseAnalytics
import FirebaseCore
import SwiftData
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    FirebaseApp.configure()

    // Enable Firebase Analytics debug mode
    #if DEBUG
      Analytics.setAnalyticsCollectionEnabled(true)
    #endif

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

    // Initialize Firebase Analytics with a delay to ensure Firebase is ready
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      FirebaseAnalyticsService.shared.setUserProperties()
      FirebaseAnalyticsService.shared.checkFirebaseConfiguration()
    }
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
