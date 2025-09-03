# 🚀 RevenueCat Integration Guide

## 📋 Overview

This guide will help you integrate RevenueCat for subscription management in your CalmMeNow app. RevenueCat will handle the paywall for AI features while keeping core features free.

## 🔧 Step 1: Add RevenueCat SDK

### Option A: Swift Package Manager (Recommended)

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter URL: `https://github.com/RevenueCat/purchases-ios`
3. Select the latest version
4. Add to your main app target

### Option B: CocoaPods

Add to your `Podfile`:

```ruby
pod 'RevenueCat'
```

## 🔑 Step 2: Configure RevenueCat

### 2.1 Get Your API Key

1. Go to [RevenueCat Dashboard](https://app.revenuecat.com/)
2. Create a new project or select existing
3. Go to **Project Settings** → **API Keys**
4. Copy your **Public SDK Key**

### 2.2 Initialize RevenueCat

Update your `CalmMeNowApp.swift`:

```swift
import RevenueCat

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    setupFirebaseAndAppCheck()
    setupRevenueCat() // Add this
    return true
  }

  private func setupRevenueCat() {
    // Replace with your actual API key
    Purchases.configure(withAPIKey: "your_revenuecat_api_key_here")

    // Enable debug logs in development
    #if DEBUG
    Purchases.logLevel = .debug
    #endif

    print("💰 RevenueCat: Configured successfully")
  }
}
```

## 🛍️ Step 3: Configure Products in App Store Connect

### 3.1 Create Subscription Products

1. Go to **App Store Connect** → **Your App** → **Features** → **In-App Purchases**
2. Create new subscription:
   - **Product ID**: `ai_features_monthly`
   - **Type**: Auto-Renewable Subscription
   - **Duration**: 1 Month
   - **Price**: $4.99
   - **Localization**: "AI Features Monthly"

### 3.2 Create Entitlement in RevenueCat

1. Go to **RevenueCat Dashboard** → **Entitlements**
2. Create new entitlement:
   - **Name**: `ai_features`
   - **Description**: "Access to AI-powered features"
   - **Products**: Link to your `ai_features_monthly` product

## 🔄 Step 4: Update RevenueCatService

Replace the mock implementation in `RevenueCatService.swift` with real RevenueCat calls:

```swift
import RevenueCat

final class RevenueCatService: ObservableObject {
  static let shared = RevenueCatService()

  @Published var isSubscribed = false
  @Published var currentOffering: Offering?
  @Published var isLoading = false

  private init() {
    setupRevenueCat()
  }

  private func setupRevenueCat() {
    // Check current subscription status
    Task {
      await checkSubscriptionStatus()
    }
  }

  @MainActor
  func checkSubscriptionStatus() async {
    isLoading = true
    defer { isLoading = false }

    do {
      let customerInfo = try await Purchases.shared.customerInfo()
      isSubscribed = customerInfo.entitlements["ai_features"]?.isActive == true

      // Get current offering
      let offerings = try await Purchases.shared.offerings()
      currentOffering = offerings.current

      print("🔍 RevenueCat: Subscription status checked - \(isSubscribed ? "Active" : "Inactive")")
    } catch {
      print("❌ RevenueCat: Failed to check subscription: \(error)")
    }
  }

  @MainActor
  func purchaseSubscription() async throws -> Bool {
    isLoading = true
    defer { isLoading = false }

    guard let offering = currentOffering,
          let package = offering.monthly else {
      throw RevenueCatError.noOfferingAvailable
    }

    do {
      let result = try await Purchases.shared.purchase(package: package)
      isSubscribed = result.customerInfo.entitlements["ai_features"]?.isActive == true

      print("✅ RevenueCat: Subscription purchased successfully")
      return isSubscribed
    } catch {
      print("❌ RevenueCat: Purchase failed: \(error)")
      throw RevenueCatError.purchaseFailed(error.localizedDescription)
    }
  }

  @MainActor
  func restorePurchases() async throws -> Bool {
    isLoading = true
    defer { isLoading = false }

    do {
      let customerInfo = try await Purchases.shared.restorePurchases()
      isSubscribed = customerInfo.entitlements["ai_features"]?.isActive == true

      print("✅ RevenueCat: Purchases restored successfully")
      return isSubscribed
    } catch {
      print("❌ RevenueCat: Restore failed: \(error)")
      throw RevenueCatError.restoreFailed(error.localizedDescription)
    }
  }
}
```

## 🎯 Step 5: Test Your Integration

### 5.1 Sandbox Testing

1. Use **Sandbox** environment in RevenueCat dashboard
2. Create test users in App Store Connect
3. Test purchase flow with sandbox accounts

### 5.2 Test Purchase Flow

1. Run app in simulator/device
2. Try to access AI feature
3. Verify paywall appears
4. Test purchase button (will use sandbox)
5. Verify access granted after purchase

## 🚨 Step 6: Handle Edge Cases

### 6.1 Network Issues

```swift
// Add retry logic for network failures
func purchaseWithRetry() async throws -> Bool {
  let maxRetries = 3
  var lastError: Error?

  for attempt in 1...maxRetries {
    do {
      return try await purchaseSubscription()
    } catch {
      lastError = error
      if attempt < maxRetries {
        try await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
      }
    }
  }

  throw lastError ?? RevenueCatError.purchaseFailed("Max retries exceeded")
}
```

### 6.2 Receipt Validation

RevenueCat handles receipt validation automatically, but you can add additional checks:

```swift
func validateReceipt() async throws -> Bool {
  let customerInfo = try await Purchases.shared.customerInfo()

  // Check if receipt is valid
  guard customerInfo.originalApplicationVersion != nil else {
    throw RevenueCatError.receiptInvalid
  }

  return true
}
```

## 📱 Step 7: Update Your Views

### 7.1 Add Paywall Guard

In views that use AI features:

```swift
struct PersonalizedPanicPlanGeneratorView: View {
  @StateObject private var paywallManager = PaywallManager.shared

  var body: some View {
    VStack {
      // Your AI feature UI
    }
    .paywallGuard() // This will show paywall when needed
  }
}
```

### 7.2 Check Access Before AI Calls

```swift
Button("Generate Plan") {
  Task {
    let hasAccess = await paywallManager.requestAIAccess()
    if hasAccess {
      // Proceed with AI feature
      await generatePlan()
    }
    // Paywall will be shown automatically if no access
  }
}
```

## 🔒 Step 8: Security & Best Practices

### 8.1 Server-Side Receipt Validation

For production apps, consider server-side validation:

```swift
// Send receipt to your server for validation
func validateWithServer() async throws -> Bool {
  let customerInfo = try await Purchases.shared.customerInfo()

  // Send to your server
  let response = try await yourServerAPI.validateReceipt(
    customerInfo: customerInfo
  )

  return response.isValid
}
```

### 8.2 Handle Subscription Changes

```swift
// Listen for subscription changes
Purchases.shared.delegate = self

extension YourClass: PurchasesDelegate {
  func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
    // Handle subscription changes
    let isSubscribed = customerInfo.entitlements["ai_features"]?.isActive == true

    DispatchQueue.main.async {
      // Update UI based on subscription status
      self.updateSubscriptionUI(isSubscribed: isSubscribed)
    }
  }
}
```

## 🧪 Step 8: Testing Checklist

- [ ] RevenueCat SDK added to project
- [ ] API key configured in app
- [ ] Products created in App Store Connect
- [ ] Entitlements configured in RevenueCat
- [ ] Paywall appears for non-subscribers
- [ ] Purchase flow works in sandbox
- [ ] Restore purchases works
- [ ] Subscription status persists
- [ ] AI features accessible after purchase
- [ ] Error handling works properly

## 🚀 Step 9: Go Live

1. **Test thoroughly** in sandbox environment
2. **Submit for review** with subscription products
3. **Monitor** RevenueCat dashboard for metrics
4. **Set up alerts** for subscription issues
5. **Prepare support** for subscription questions

## 📚 Additional Resources

- [RevenueCat Documentation](https://docs.revenuecat.com/)
- [iOS Integration Guide](https://docs.revenuecat.com/docs/ios)
- [Testing Guide](https://docs.revenuecat.com/docs/testing)
- [Troubleshooting](https://docs.revenuecat.com/docs/troubleshooting)

## 🆘 Support

If you encounter issues:

1. Check RevenueCat dashboard logs
2. Review Xcode console for errors
3. Test with sandbox accounts
4. Contact RevenueCat support if needed

---

**Note**: This implementation provides a seamless user experience where:

- Core features remain free and accessible
- AI features automatically trigger paywall for non-subscribers
- Anonymous Firebase authentication happens behind the scenes
- RevenueCat handles all subscription complexity
