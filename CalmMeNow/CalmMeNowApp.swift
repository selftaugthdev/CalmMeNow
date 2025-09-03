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

@main
struct CalmMeNowApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(for: [JournalEntry.self])
  }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    setupFirebaseAndAppCheck()
    return true
  }

  private func setupFirebaseAndAppCheck() {
    // IMPORTANT: App Check provider must be set BEFORE FirebaseApp.configure()
    #if targetEnvironment(simulator)
      // Dev/testing on Simulator - use DEBUG provider
      AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
      print("🔥 Firebase App Check: Using DEBUG provider for Simulator")
    #else
      // Real devices & TestFlight - use DeviceCheck provider
      AppCheck.setAppCheckProviderFactory(DeviceCheckProviderFactory())
      print("🔥 Firebase App Check: Using DeviceCheck provider for real devices")
    #endif

    // Now configure Firebase (App Check is already set)
    FirebaseApp.configure()

    // Enable Firebase Analytics debug mode
    #if DEBUG
      Analytics.setAnalyticsCollectionEnabled(true)
    #endif

    // kick off anon auth in the background
    AuthManager.shared.warmUpAuth()
  }
}
