import Combine
import Foundation
import SwiftUI

// MARK: - Paywall Manager
/// Manages when to show paywall for AI features
final class PaywallManager: ObservableObject {
  static let shared = PaywallManager()

  // MARK: - Published Properties
  @Published var shouldShowPaywall = false
  @Published var isCheckingAccess = false

  // MARK: - Private Properties
  private let revenueCatService = RevenueCatService.shared
  private let aiService = AIService()

  private init() {
    // Listen for subscription changes
    setupSubscriptionListener()
  }

  // MARK: - Setup

  private func setupSubscriptionListener() {
    // Listen for RevenueCat subscription changes
    revenueCatService.$isSubscribed
      .sink { [weak self] isSubscribed in
        if isSubscribed {
          // User has subscription, no need to show paywall
          self?.shouldShowPaywall = false
        }
      }
      .store(in: &cancellables)
  }

  // MARK: - Access Control

  /// Check if user can access AI features
  /// Returns true if user has subscription, false if paywall should be shown
  func checkAIAccess() async -> Bool {
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

    // If user has subscription, they can access AI features
    if revenueCatService.isSubscribed {
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
    return await checkAIAccess()
  }

  /// Dismiss paywall
  func dismissPaywall() {
    shouldShowPaywall = false
  }

  // MARK: - Feature Access Methods

  /// Check access before calling AI features
  func withAIAccess<T>(_ operation: () async throws -> T) async throws -> T? {
    let hasAccess = await checkAIAccess()

    if hasAccess {
      return try await operation()
    } else {
      // Paywall will be shown automatically
      return nil
    }
  }

  // MARK: - Private Properties
  private var cancellables = Set<AnyCancellable>()
}

// MARK: - View Extension for Paywall
extension View {
  /// Shows paywall when AI features are accessed without subscription
  func paywallGuard() -> some View {
    self
      .sheet(isPresented: PaywallManager.shared.$shouldShowPaywall) {
        PaywallView()
      }
  }
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
     .paywallGuard() // This will show paywall when needed
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
