//
//  CalmMeNowApp.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import FirebaseAnalytics
import FirebaseAppCheck
import FirebaseCore
import SwiftData
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    setupFirebaseAndAppCheck()
    return true
  }

  private func setupFirebaseAndAppCheck() {
    FirebaseApp.configure()

    #if targetEnvironment(simulator)
      // Dev/testing on Simulator
      AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
      // First run will print a debug token in Xcode; paste it in Console > App Check > Debug tokens.
      print("🔥 Firebase App Check: Using DEBUG provider for Simulator")
    #else
      // Real devices & TestFlight
      AppCheck.setAppCheckProviderFactory(DeviceCheckProviderFactory())
      print("🔥 Firebase App Check: Using DeviceCheck provider for real devices")
    #endif

    // Enable Firebase Analytics debug mode
    #if DEBUG
      Analytics.setAnalyticsCollectionEnabled(true)
    #endif
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
