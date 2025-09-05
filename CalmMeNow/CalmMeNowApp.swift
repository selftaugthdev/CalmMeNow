//
//  CalmMeNowApp.swift
//  CalmMeNow
//
//  Created by Thierry De Belder on 19/05/2025.
//

import Combine
import FirebaseAnalytics
import FirebaseAppCheck
import FirebaseAuth
import FirebaseCore
import RevenueCat
import SwiftData
import SwiftUI

// MARK: - Billing Configuration
final class Billing {
  static let entitlement = "premium"
}

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
    #if DEBUG
      // Debug builds - use DEBUG provider for both simulator and real devices
      AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
      print("🔥 Firebase App Check: Using DEBUG provider for debug build")
    #else
      // Release builds - use DeviceCheck provider for real devices
      AppCheck.setAppCheckProviderFactory(DeviceCheckProviderFactory())
      print("🔥 Firebase App Check: Using DeviceCheck provider for release build")
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

    // Configure RevenueCat after Firebase is ready
    configureRevenueCat()
  }

  private func configureRevenueCat() {
    // RevenueCat API key for CalmMeNow
    let apiKey = "appl_xeIUzCLEhVImrKmBAgvcITeDxFn"

    #if DEBUG
      print("🔧 RC configured for CalmMeNow")
      print("🔧 RevenueCat: Configuring with API key: \(apiKey)")
    #endif

    #if DEBUG
      Purchases.logLevel = .debug
    #else
      Purchases.logLevel = .warn
    #endif
    Purchases.configure(withAPIKey: apiKey)

    // Link RC customer to your Firebase UID (best for cross-device restore)
    if let uid = Auth.auth().currentUser?.uid {
      Purchases.shared.logIn(uid) { _, _, _ in }
    } else {
      // If you sign in anonymously later, call logIn(uid) at that moment too.
      // This will be handled when anonymous auth completes
      Task {
        do {
          let user = try await AuthManager.shared.ensureSignedIn()
          Purchases.shared.logIn(user.uid) { _, _, _ in }
        } catch {
          #if DEBUG
            print("Failed to link RevenueCat with Firebase UID: \(error)")
          #endif
        }
      }
    }
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
