//
//  CalmMeNowApp.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import Combine
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
      MainTabView()
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

    // Set up user properties for analytics
    setupAnalyticsUserProperties()

    // kick off anon auth in the background
    AuthManager.shared.warmUpAuth()
  }

  private func setupAnalyticsUserProperties() {
    // Set build channel
    #if targetEnvironment(simulator)
      AnalyticsLogger.shared.setUserProperty("build_channel", value: "sim")
    #else
      // Check if this is TestFlight or App Store
      if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
        AnalyticsLogger.shared.setUserProperty("build_channel", value: "testflight")
      } else {
        AnalyticsLogger.shared.setUserProperty("build_channel", value: "appstore")
      }
    #endif

    // Set initial subscription status (will be updated when subscription changes)
    AnalyticsLogger.shared.setUserProperty("subscription_status", value: "free")

    // Listen for subscription changes and update user property
    RevenueCatService.shared.$isSubscribed
      .sink { isSubscribed in
        let status = isSubscribed ? "active" : "free"
        AnalyticsLogger.shared.setUserProperty("subscription_status", value: status)
      }
      .store(in: &cancellables)
  }

  private var cancellables = Set<AnyCancellable>()
}
