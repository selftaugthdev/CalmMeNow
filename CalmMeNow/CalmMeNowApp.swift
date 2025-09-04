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
import FirebaseAuth
import RevenueCat
import SwiftData
import SwiftUI

// MARK: - Billing Configuration
final class Billing {
    static let entitlement = "ai"
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
    
    // Configure RevenueCat after Firebase is ready
    configureRevenueCat()
  }
  
  private func configureRevenueCat() {
    // Check if we have a valid RevenueCat API key
    let apiKey = "appl_your_public_sdk_key"
    
    // Skip RevenueCat configuration if using placeholder key
    guard apiKey != "appl_your_public_sdk_key" else {
      print("⚠️ RevenueCat: Skipping configuration - placeholder API key detected")
      print("⚠️ RevenueCat: Please replace 'appl_your_public_sdk_key' with your actual RevenueCat API key")
      return
    }
    
    Purchases.logLevel = .warn // .debug while testing
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
          print("Failed to link RevenueCat with Firebase UID: \(error)")
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
