import Combine
import Foundation
import PaywallKit
import RevenueCat

// MARK: - RevenueCat Service
/// Handles subscription management and paywall logic for AI features
final class RevenueCatService: ObservableObject, PaywallPurchasing {
  static let shared = RevenueCatService()

  // MARK: - Published Properties
  @Published var isSubscribed = false
  @Published var currentOffering: Offering?
  @Published var isLoading = false

  // MARK: - PaywallPurchasing Protocol Properties
  @Published var availablePackages: [Package] = []
  @Published var errorMessage: String?

  // MARK: - Private Properties
  private var cancellables = Set<AnyCancellable>()

  private init() {
    setupRevenueCat()
  }

  // MARK: - Setup

  private func setupRevenueCat() {
    // Check current subscription status on launch
    Task {
      await checkSubscriptionStatus()
    }

    // Only listen for live changes if RevenueCat is configured
    guard Purchases.isConfigured else {
      #if DEBUG
        print("⚠️ RevenueCat: Not configured - skipping live updates")
      #endif
      return
    }

    // Listen for live changes
    Task {
      for await info in Purchases.shared.customerInfoStream {
        await MainActor.run {
          let unlocked = isAIUnlocked(info)
          UserDefaults.standard.set(unlocked, forKey: "AIUnlocked")
          isSubscribed = unlocked
        }
      }
    }
  }

  // MARK: - Entitlement Checking

  func isAIUnlocked(_ info: CustomerInfo) -> Bool {
    return info.entitlements.active.keys.contains(Billing.entitlement)
  }

  var aiUnlocked: Bool {
    // Use cached value for performance - it's updated by the customerInfoStream
    return UserDefaults.standard.bool(forKey: "AIUnlocked")
  }

  // MARK: - Subscription Management

  /// Check if user currently has an active subscription
  @MainActor
  func checkSubscriptionStatus() async {
    isLoading = true
    defer { isLoading = false }

    // Check if RevenueCat is configured
    guard Purchases.isConfigured else {
      #if DEBUG
        print("⚠️ RevenueCat: Not configured - treating as free user")
      #endif
      UserDefaults.standard.set(false, forKey: "AIUnlocked")
      isSubscribed = false
      return
    }

    do {
      let info = try await Purchases.shared.customerInfo()
      let unlocked = isAIUnlocked(info)
      UserDefaults.standard.set(unlocked, forKey: "AIUnlocked")
      isSubscribed = unlocked
      #if DEBUG
        print("🔍 RevenueCat: Subscription status checked - AI unlocked: \(unlocked)")
      #endif
    } catch {
      #if DEBUG
        print("❌ RevenueCat: Failed to check subscription status: \(error)")
      #endif
    }
  }

  /// Purchase a subscription
  @MainActor
  func purchaseSubscription() async throws -> Bool {
    // Check if RevenueCat is configured
    guard Purchases.isConfigured else {
      print("⚠️ RevenueCat: Not configured - cannot purchase subscription")
      throw RevenueCatError.notConfigured
    }

    isLoading = true
    defer { isLoading = false }

    do {
      let offerings = try await Purchases.shared.offerings()
      guard let offering = offerings.current,
        let monthly = offering.monthly ?? offering.package(identifier: "monthly")
      else {
        throw RevenueCatError.noOfferingAvailable
      }

      let result = try await Purchases.shared.purchase(package: monthly)

      if result.customerInfo.entitlements.active[Billing.entitlement] != nil {
        // success
        let unlocked = isAIUnlocked(result.customerInfo)
        UserDefaults.standard.set(unlocked, forKey: "AIUnlocked")
        isSubscribed = unlocked
        #if DEBUG
          print("✅ RevenueCat: Subscription purchased successfully!")
        #endif
        return true
      } else if result.userCancelled {
        #if DEBUG
          print("❌ RevenueCat: User cancelled purchase")
        #endif
        return false
      } else {
        throw RevenueCatError.purchaseFailed("Purchase completed but entitlement not active")
      }
    } catch {
      #if DEBUG
        print("❌ RevenueCat: Purchase failed: \(error)")
      #endif
      throw error
    }
  }

  /// Restore previous purchases
  @MainActor
  func restorePurchases() async throws -> Bool {
    // Check if RevenueCat is configured
    guard Purchases.isConfigured else {
      #if DEBUG
        print("⚠️ RevenueCat: Not configured - cannot restore purchases")
      #endif
      throw RevenueCatError.notConfigured
    }

    isLoading = true
    defer { isLoading = false }

    do {
      let info = try await Purchases.shared.restorePurchases()
      let unlocked = isAIUnlocked(info)
      UserDefaults.standard.set(unlocked, forKey: "AIUnlocked")
      isSubscribed = unlocked

      if unlocked {
        print("✅ RevenueCat: Purchases restored successfully!")
      } else {
        print("❌ RevenueCat: No previous purchases found")
      }

      return unlocked
    } catch {
      print("❌ RevenueCat: Restore failed: \(error)")
      throw RevenueCatError.restoreFailed(error.localizedDescription)
    }
  }

  // MARK: - AI Feature Gating

  func guardAIOrPaywall(present: @escaping () -> Void, paywall: @escaping () -> Void) {
    if aiUnlocked {
      present()
    } else {
      paywall()
    }
  }

  // MARK: - Paywall Presentation

  @MainActor
  func presentPaywall() async throws {
    // Check if RevenueCat is configured
    guard Purchases.isConfigured else {
      #if DEBUG
        print("⚠️ RevenueCat: Not configured - cannot present paywall")
      #endif
      throw RevenueCatError.notConfigured
    }

    do {
      let offerings = try await Purchases.shared.offerings()
      guard let offering = offerings.current,
        let monthly = offering.monthly ?? offering.package(identifier: "monthly")
      else {
        throw RevenueCatError.noOfferingAvailable
      }

      let result = try await Purchases.shared.purchase(package: monthly)

      if result.customerInfo.entitlements.active[Billing.entitlement] != nil {
        // success → dismiss paywall
        let unlocked = isAIUnlocked(result.customerInfo)
        UserDefaults.standard.set(unlocked, forKey: "AIUnlocked")
        isSubscribed = unlocked
      } else if result.userCancelled {
        // user cancelled - do nothing
      } else {
        throw RevenueCatError.purchaseFailed("Purchase completed but entitlement not active")
      }
    } catch {
      print("❌ RevenueCat: Paywall purchase error: \(error)")
      throw error
    }
  }

  // MARK: - PaywallPurchasing Protocol Methods

  /// Fetch available packages from RevenueCat
  func fetchPackages() {
    Task {
      await MainActor.run {
        isLoading = true
        errorMessage = nil
      }

      do {
        let offerings = try await Purchases.shared.offerings()
        await MainActor.run {
          self.isLoading = false
          guard let current = offerings.current else {
            self.errorMessage = "No current offering set in RevenueCat"
            #if DEBUG
              print("⚠️ RC: offerings.current is nil")
            #endif
            return
          }
          let pkgs = current.availablePackages
          self.availablePackages = pkgs
          self.currentOffering = current
          #if DEBUG
            print("✅ RC current offering:", current.identifier)
            print("✅ Packages count:", pkgs.count)
            pkgs.forEach { p in
              print(
                "• package.id=\(p.identifier) type=\(p.packageType.rawValue) product=\(p.storeProduct.productIdentifier) price=\(p.storeProduct.localizedPriceString)"
              )
            }
          #endif
        }
      } catch {
        await MainActor.run {
          self.errorMessage = error.localizedDescription
          self.isLoading = false
          print("❌ RevenueCat: Failed to fetch packages: \(error)")
        }
      }
    }
  }

  /// Purchase a specific package
  func purchase(package: Package) {
    Task {
      await MainActor.run {
        isLoading = true
        errorMessage = nil
      }

      do {
        let result = try await Purchases.shared.purchase(package: package)

        if result.customerInfo.entitlements.active[Billing.entitlement] != nil {
          // Purchase successful
          let unlocked = isAIUnlocked(result.customerInfo)
          await MainActor.run {
            UserDefaults.standard.set(unlocked, forKey: "AIUnlocked")
            isSubscribed = unlocked
            isLoading = false

            // Post notification for PaywallKit
            NotificationCenter.default.post(
              name: PaywallNotifications.showSubscriptionConfirmation, object: nil)
            print("✅ RevenueCat: Purchase successful!")
          }
        } else if result.userCancelled {
          await MainActor.run {
            isLoading = false
            print("❌ RevenueCat: User cancelled purchase")
          }
        } else {
          await MainActor.run {
            isLoading = false
            errorMessage = "Purchase completed but entitlement not active"
          }
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
          isLoading = false
          print("❌ RevenueCat: Purchase failed: \(error)")
        }
      }
    }
  }

  /// Restore previous purchases
  func restorePurchases() {
    Task {
      await MainActor.run {
        isLoading = true
        errorMessage = nil
      }

      do {
        let info = try await Purchases.shared.restorePurchases()
        let unlocked = isAIUnlocked(info)

        await MainActor.run {
          UserDefaults.standard.set(unlocked, forKey: "AIUnlocked")
          isSubscribed = unlocked
          isLoading = false

          if unlocked {
            // Post notification for PaywallKit
            NotificationCenter.default.post(
              name: PaywallNotifications.restorePurchaseSuccess, object: nil)
            print("✅ RevenueCat: Purchases restored successfully!")
          } else {
            errorMessage = "No previous purchases found to restore"
            print("❌ RevenueCat: No previous purchases found")
          }
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
          isLoading = false
          print("❌ RevenueCat: Restore failed: \(error)")
        }
      }
    }
  }

}

// MARK: - RevenueCat Errors
enum RevenueCatError: LocalizedError {
  case notConfigured
  case noOfferingAvailable
  case purchaseFailed(String)
  case restoreFailed(String)

  var errorDescription: String? {
    switch self {
    case .notConfigured:
      return "RevenueCat is not configured. Please set up your API key."
    case .noOfferingAvailable:
      return "No subscription offering available"
    case .purchaseFailed(let message):
      return "Purchase failed: \(message)"
    case .restoreFailed(let message):
      return "Restore failed: \(message)"
    }
  }
}
