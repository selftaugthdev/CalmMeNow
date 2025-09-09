import Foundation
import SwiftUI

// MARK: - Subscription Success Manager
/// Manages showing custom congratulations screen after successful subscription
final class SubscriptionSuccessManager: ObservableObject {
  static let shared = SubscriptionSuccessManager()
  
  @Published var shouldShowSuccessScreen = false
  
  private init() {
    setupNotificationListener()
  }
  
  private func setupNotificationListener() {
    // Listen for subscription success notifications
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleSubscriptionSuccess),
      name: PaywallNotifications.showSubscriptionConfirmation,
      object: nil
    )
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleRestoreSuccess),
      name: PaywallNotifications.restorePurchaseSuccess,
      object: nil
    )
  }
  
  @objc private func handleSubscriptionSuccess() {
    DispatchQueue.main.async {
      self.shouldShowSuccessScreen = true
    }
  }
  
  @objc private func handleRestoreSuccess() {
    DispatchQueue.main.async {
      self.shouldShowSuccessScreen = true
    }
  }
  
  func dismissSuccessScreen() {
    shouldShowSuccessScreen = false
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}

// MARK: - PaywallNotifications Extension
extension Notification.Name {
  static let showSubscriptionConfirmation = Notification.Name("showSubscriptionConfirmation")
  static let restorePurchaseSuccess = Notification.Name("restorePurchaseSuccess")
}

// MARK: - PaywallNotifications (for compatibility)
struct PaywallNotifications {
  static let showSubscriptionConfirmation = Notification.Name.showSubscriptionConfirmation
  static let restorePurchaseSuccess = Notification.Name.restorePurchaseSuccess
}
