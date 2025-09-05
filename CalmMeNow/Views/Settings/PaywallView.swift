import StoreKit
import SwiftUI

struct PaywallView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var revenueCatService = RevenueCatService.shared
  @State private var showingError = false
  @State private var errorMessage = ""

  var body: some View {
    NavigationStack {
      ZStack {
        backgroundGradient
        ScrollView {
          VStack(spacing: 30) {
            headerSection
            featuresSection
            pricingSection
            actionButtonsSection
            legalSection
          }
          .padding(.horizontal, 20)
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarBackButtonHidden(true)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Close") {
            dismiss()
          }
          .foregroundColor(.blue)
          .fontWeight(.semibold)
        }
      }
      .alert("Error", isPresented: $showingError) {
        Button("OK") {}
      } message: {
        Text(errorMessage)
      }
      .onReceive(revenueCatService.$isSubscribed) { isSubscribed in
        if isSubscribed {
          dismiss()
        }
      }
      .onAppear {
        revenueCatService.fetchPackages()
      }
    }
  }

  private var backgroundGradient: some View {
    LinearGradient(
      gradient: Gradient(colors: [
        Color(hex: "#A0C4FF"),
        Color(hex: "#D0BFFF"),
      ]),
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
    .ignoresSafeArea(.all, edges: .top)
    .padding(.bottom, 20)
  }

  private var headerSection: some View {
    VStack(spacing: 16) {
      Text("🧠")
        .font(.system(size: 80))

      Text("Unlock AI-Powered Calm")
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundColor(.black)
        .multilineTextAlignment(.center)

      Text("Get personalized support when you need it most")
        .font(.title3)
        .foregroundColor(.black.opacity(0.7))
        .multilineTextAlignment(.center)
    }
    .padding(.top, 20)
  }

  private var featuresSection: some View {
    VStack(spacing: 20) {
      FeatureRow(
        icon: "🎯",
        title: "Personalized Panic Plans",
        description: "AI-generated strategies tailored to your triggers and preferences"
      )

      FeatureRow(
        icon: "📊",
        title: "Smart Daily Check-ins",
        description: "Get intelligent insights and recommendations based on your mood"
      )

      FeatureRow(
        icon: "🤖",
        title: "AI Emergency Companion",
        description: "24/7 AI support for crisis moments with personalized guidance"
      )

      FeatureRow(
        icon: "🫁",
        title: "Enhanced Breathing",
        description: "AI-optimized breathing patterns for maximum effectiveness"
      )
    }
  }

  private var pricingSection: some View {
    VStack(spacing: 16) {
      if let monthlyPackage = revenueCatService.currentOffering?.monthly {
        VStack(spacing: 8) {
          Text(monthlyPackage.storeProduct.localizedPriceString)
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(Color(.label))

          if let trialPeriod = monthlyPackage.storeProduct.introductoryDiscount {
            Text("7-Day Free Trial")
              .font(.subheadline)
              .foregroundColor(.green)
              .fontWeight(.semibold)
          }
        }
      } else {
        Text("Just $4.99/month")
          .font(.title)
          .fontWeight(.bold)
          .foregroundColor(Color(.label))
      }

      Text("Cancel anytime • No commitment")
        .font(.subheadline)
        .foregroundColor(Color(.secondaryLabel))
    }
  }

  private var actionButtonsSection: some View {
    VStack(spacing: 16) {
      Button(action: purchaseSubscription) {
        HStack {
          if revenueCatService.isLoading {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: .white))
              .scaleEffect(0.8)
          } else {
            Text("Start Free Trial")
              .fontWeight(.semibold)
          }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(12)
      }
      .disabled(revenueCatService.isLoading)

      Button(action: restorePurchases) {
        Text("Restore Purchases")
          .font(.subheadline)
          .foregroundColor(.blue)
      }
      .disabled(revenueCatService.isLoading)
    }
  }

  private var legalSection: some View {
    VStack(spacing: 8) {
      HStack(spacing: 20) {
        Button("Terms of Service") {
          // Handle terms
        }
        .font(.caption)
        .foregroundColor(.blue)

        Button("Privacy Policy") {
          // Handle privacy
        }
        .font(.caption)
        .foregroundColor(.blue)
      }

      Text(
        "By subscribing, you agree to our Terms of Service and Privacy Policy. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period."
      )
      .font(.caption2)
      .foregroundColor(Color(.secondaryLabel))
      .multilineTextAlignment(.center)
      .padding(.horizontal)
    }
    .padding(.bottom, 20)
  }

  private func purchaseSubscription() {
    Task {
      do {
        let success = try await revenueCatService.purchaseSubscription()
        if success {
          dismiss()
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
          showingError = true
        }
      }
    }
  }

  private func restorePurchases() {
    Task {
      do {
        let restored = try await revenueCatService.restorePurchases()
        if restored {
          dismiss()
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
          showingError = true
        }
      }
    }
  }
}

struct FeatureRow: View {
  let icon: String
  let title: String
  let description: String

  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      Text(icon)
        .font(.title2)
        .frame(width: 30)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(.black)

        Text(description)
          .font(.subheadline)
          .foregroundColor(.black.opacity(0.7))
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer()
    }
    .padding(.vertical, 8)
  }
}

#Preview {
  PaywallView()
}
