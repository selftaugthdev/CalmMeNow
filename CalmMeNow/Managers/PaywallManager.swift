import Combine
import Foundation
import SwiftUI

// MARK: - Paywall Manager
/// Manages when to show paywall for AI features
final class PaywallManager: ObservableObject {
  static let shared = PaywallManager()

  // MARK: - Launch Configuration
  /// Set to true to make all features free (no paywall)
  /// TODO: Set back to false when ready to monetize
  static let freeLaunchMode = true

  /// Cutoff date for grandfathering early adopters (set this when you disable freeLaunchMode)
  /// Users who installed before this date get permanent free access
  /// Format: timeIntervalSince1970 (use Date().timeIntervalSince1970 to get current timestamp)
  static let grandfatherCutoffDate: Double = 0  // 0 = not set yet, set when disabling free mode

  /// Check if current user is grandfathered (installed during free period)
  static var isGrandfatheredUser: Bool {
    let installDate = UserDefaults.standard.double(forKey: "originalInstallDate")
    // If no cutoff set, no one is grandfathered yet (still in free mode)
    guard grandfatherCutoffDate > 0 else { return false }
    // If install date is before cutoff, user is grandfathered
    return installDate > 0 && installDate < grandfatherCutoffDate
  }

  /// User has free access if: free launch mode OR grandfathered OR subscribed
  static var hasFreeAccess: Bool {
    return freeLaunchMode || isGrandfatheredUser
  }

  // MARK: - Published Properties
  @Published var shouldShowPaywall = false
  @Published var isCheckingAccess = false
  @Published var hasAIAccess: Bool = PaywallManager.hasFreeAccess

  // MARK: - Private Properties
  private let revenueCatService = RevenueCatService.shared
  private let aiService = AiService.shared

  private init() {
    // Record install date on first launch (for grandfathering)
    if UserDefaults.standard.double(forKey: "originalInstallDate") == 0 {
      UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "originalInstallDate")
    }

    // Skip paywall setup if user has free access (free mode or grandfathered)
    guard !PaywallManager.hasFreeAccess else {
      hasAIAccess = true
      return
    }
    // Listen for subscription changes
    setupSubscriptionListener()
  }

  // MARK: - Setup

  private func setupSubscriptionListener() {
    // Listen for RevenueCat subscription changes
    revenueCatService.$isSubscribed
      .sink { [weak self] isSubscribed in
        guard let self = self else { return }
        // Update hasAIAccess when subscription status changes
        self.hasAIAccess = self.revenueCatService.aiUnlocked
        if isSubscribed {
          // User has subscription, no need to show paywall
          self.shouldShowPaywall = false
        }
      }
      .store(in: &cancellables)

    // Initialize hasAIAccess on setup
    hasAIAccess = revenueCatService.aiUnlocked
  }

  // MARK: - Access Control

  /// Check if user can access AI features
  /// Returns true if user has subscription, false if paywall should be shown
  func checkAIAccess() async -> Bool {
    // Free access (free launch mode or grandfathered user)
    if PaywallManager.hasFreeAccess {
      return true
    }

    await MainActor.run {
      isCheckingAccess = true
    }

    defer {
      Task { @MainActor in
        isCheckingAccess = false
      }
    }

    // Check RevenueCat subscription status
    await revenueCatService.checkSubscriptionStatus()

    // Update hasAIAccess
    await MainActor.run {
      hasAIAccess = revenueCatService.aiUnlocked
    }

    // If user has subscription, they can access AI features
    if revenueCatService.aiUnlocked {
      return true
    }

    // If no subscription, show paywall
    await MainActor.run {
      shouldShowPaywall = true
    }

    return false
  }

  /// Attempt to access AI feature
  /// Shows paywall if user doesn't have subscription
  func requestAIAccess() async -> Bool {
    // Free access (free launch mode or grandfathered user)
    if PaywallManager.hasFreeAccess {
      return true
    }
    return await checkAIAccess()
  }

  /// Dismiss paywall
  func dismissPaywall() {
    shouldShowPaywall = false
  }

  /// Show paywall
  func showPaywall() {
    shouldShowPaywall = true
  }

  // MARK: - Feature Access Methods

  /// Check access before calling AI features
  func withAIAccess<T>(_ operation: () async throws -> T) async throws -> T? {
    // Free access (free launch mode or grandfathered user)
    if PaywallManager.hasFreeAccess {
      return try await operation()
    }

    let hasAccess = await checkAIAccess()

    if hasAccess {
      return try await operation()
    } else {
      // Paywall will be shown automatically
      return nil
    }
  }

  /// Guard AI features with paywall - convenience method
  func guardAIOrPaywall(present: @escaping () -> Void, paywall: @escaping () -> Void) {
    // Free access (free launch mode or grandfathered user)
    if PaywallManager.hasFreeAccess {
      present()
      return
    }
    revenueCatService.guardAIOrPaywall(present: present, paywall: paywall)
  }

  // MARK: - Private Properties
  private var cancellables = Set<AnyCancellable>()
}

// MARK: - Usage Examples
/*

 // In your views, use like this:

 struct SomeView: View {
   @StateObject private var paywallManager = PaywallManager.shared

   var body: some View {
     VStack {
       Button("Generate AI Plan") {
         Task {
           let hasAccess = await paywallManager.requestAIAccess()
           if hasAccess {
             // User has subscription, proceed with AI feature
             await generatePlan()
           }
           // If no access, paywall will be shown automatically
         }
       }
     }
     .sheet(isPresented: paywallManager.$shouldShowPaywall) {
       PaywallView()
     }
   }

   private func generatePlan() async {
     // Your AI feature logic here
   }
 }

 // Or use the convenience method:
 Button("AI Feature") {
   Task {
     let result = await paywallManager.withAIAccess {
       // Your AI operation here
       return "AI Result"
     }

     if let result = result {
       // Handle successful AI operation
       print(result)
     }
   }
 }

 */
